//
//  Project.swift
//  SourceKittenDaemon
//
//  Created by Benedikt Terhechte on 12/11/15.
//  Copyright © 2015 Benedikt Terhechte. All rights reserved.
//

import Foundation

class Project {

    let type: ProjectType
    let chosenScheme: String?
    let chosenTarget: String?
    let chosenConfiguration: String?

    init(type: ProjectType,
         scheme: String? = nil,
         target: String? = nil,
         configuration: String? = nil) throws {
        self.type = type
        self.chosenScheme = scheme
        self.chosenTarget = target
        self.chosenConfiguration = configuration

        guard type.projectDir != nil
            else { throw ProjectError.ProjectNotFound(type.path) }

        guard type.projectFile != nil
            else { throw ProjectError.ProjectNotFound(type.path) }
        
        guard xcProjectFile.project.targets.count > 0
            else { throw ProjectError.NoValidTarget }

        guard xcodebuildOutput != nil
            else { throw ProjectError.CouldNotParseProject }
    }

    var projectDir: NSURL { return self.type.projectDir! }
    var srcRoot: NSURL { return projectDir }
    var projectFile: NSURL { return type.projectFile! }

    var target: String {
        return xcodebuildSettings["TARGET_NAME"]!
    }

    var configuration: String {
        return xcodebuildSettings["CONFIGURATION"]!
    }

    var moduleName: String {
        return xcodebuildSettings["PRODUCT_MODULE_NAME"]!
    }

    var sdkRoot: String {
        return xcodebuildSettings["SDKROOT"]!
    }

    var frameworkSearchPaths: [String] {
        guard let s = xcodebuildSettings["FRAMEWORK_SEARCH_PATHS"] else { return [] }
        return s.componentsSeparatedByString(" ")
    }

    var customSwiftCompilerFlags: [String] {
        guard let s = xcodebuildSettings["OTHER_SWIFT_FLAGS"] else { return [] }
        return s.componentsSeparatedByString(" ")
    }

    var gccPreprocessorDefinitions: [String] {
        guard let s = xcodebuildSettings["GCC_PREPROCESSOR_DEFINITIONS"] else { return [] }
        return s.componentsSeparatedByString(" ")
    }

    var sourceObjects: [ProjectObject] {
        guard let phase = pbxTarget.buildPhases.filter({ ($0 as? PBXSourcesBuildPhase) != nil }).first
            else { return [] }
        return objects.filter { $0.buildPhase.id == phase.id }
    }

    /// Return a project with an identical configuration.
    /// However this new object will re-fetch the project settings such as
    /// source files.
    func reissue() throws -> Project {
        return try Project(type: type,
                           scheme: chosenScheme,
                           target: chosenTarget,
                           configuration: chosenConfiguration)
    }

    private lazy var xcProjectFile: XCProjectFile = {
        try! XCProjectFile(xcodeprojURL: self.type.projectFile!)
    }()
    
    private lazy var pbxTarget: PBXNativeTarget = {
        return self.xcProjectFile.project.targets
            .filter({$0.name == self.target }).first!
    }()

    private lazy var objects: [ProjectObject] = {
      return self.pbxTarget.buildPhases.reduce([], combine: { (a, phase) -> [ProjectObject] in
            return a + phase.files
                        .map({ (file) -> ProjectObject? in
                                 if let fileRef = file.fileRef,
                                    type = fileRef.string("lastKnownFileType"),
                                    sourceType = ProjectObjectSourceType(rawValue: type),
                                    path = fileRef.path,
                                    name = path.componentsSeparatedByString("/").last,
                                    relativePath = self.xcProjectFile.project.allObjects.fullFilePaths[fileRef.id] {
                                     return ProjectObject(type: sourceType,
                                                          name: name,
                                                          relativePath: relativePath,
                                                          buildPhase: phase)
                                 } else {
                                     return nil
                                 }
                            })
                        .filter({ $0 != nil })
                        .map({ $0! })
        })
    }()

    private lazy var xcodebuildSettings: [String: String] = {
        return self.xcodebuildOutput!.componentsSeparatedByString("\n")
        .reduce([String: String]()) { (var a, e) in
            let splitString = e.componentsSeparatedByString(" = ")
            if splitString.count != 2 { return a }
            a.merge(
               [splitString[0].stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()):
                splitString[1].stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())])
            return a
        }
    }()

    private lazy var xcodebuildOutput: String? = {
        let task = NSTask()
        task.launchPath = "/usr/bin/xcodebuild"
        task.currentDirectoryPath = self.projectDir.path!
        task.arguments =
            (self.chosenScheme == nil ? [] : ["-scheme", self.chosenScheme!] as [String]) +
            (self.chosenTarget == nil ? [] : ["-target", self.chosenTarget!] as [String]) +
            (self.chosenConfiguration == nil ? [] : ["-configuration", self.chosenConfiguration!] as [String]) +
            ["-showBuildSettings"]

        let pipe = NSPipe()
        task.standardOutput = pipe
        task.launch() 
        task.waitUntilExit()

        if task.terminationStatus != 0 { return nil }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = NSString(bytes: data.bytes, length: data.length, encoding: NSUTF8StringEncoding)
      
        return output as? String
    }()

}

struct ProjectObject {
    let type: ProjectObjectSourceType
    let name: String
    let relativePath: Path
    let buildPhase: PBXBuildPhase
}

enum ProjectObjectSourceType: String {
    case Swift = "sourcecode.swift"
    case Plist = "text.plist.xml"
    case Framework = "wrapper.framework"
}

