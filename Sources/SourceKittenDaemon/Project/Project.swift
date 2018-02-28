//
//  Project.swift
//  SourceKittenDaemon
//
//  Created by Benedikt Terhechte on 12/11/15.
//  Copyright © 2015 Benedikt Terhechte. All rights reserved.
//

import Foundation
import XcodeEdit

public class Project {

    let type: ProjectType
    let chosenScheme: String?
    let chosenTarget: String?
    let chosenConfiguration: String?

    public init(type: ProjectType,
         scheme: String? = nil,
         target: String? = nil,
         configuration: String? = nil) throws {
        self.type = type
        self.chosenScheme = scheme
        self.chosenTarget = target
        self.chosenConfiguration = configuration

        guard type.projectDir != nil
            else { throw ProjectError.projectNotFound(type.path) }

        guard type.projectFile != nil
            else { throw ProjectError.projectNotFound(type.path) }

        guard xcProjectFile.project.targets.count > 0
            else { throw ProjectError.noValidTarget }

        guard xcodebuildOutput != nil
            else { throw ProjectError.couldNotParseProject }
    }

    var projectDir: URL { return self.type.projectDir! }
    var srcRoot: URL { return projectDir }
    var projectFile: URL { return type.projectFile! }

    var target: String {
        return xcodebuildSettings["TARGET_NAME"]!
    }

    var platformTarget: String? {
        if let arch = xcodebuildSettings["PLATFORM_PREFERRED_ARCH"],
            let targetPrefix = xcodebuildSettings["SWIFT_PLATFORM_TARGET_PREFIX"],
            let targetOS = xcodebuildSettings["IPHONEOS_DEPLOYMENT_TARGET"] {
            return arch + "-apple-" + targetPrefix + targetOS
        }
        return nil
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
        return s.components(separatedBy: " ")
    }

    var customSwiftCompilerFlags: [String] {
        guard let s = xcodebuildSettings["OTHER_SWIFT_FLAGS"] else { return [] }
        return s.components(separatedBy: " ")
    }

    var gccPreprocessorDefinitions: [String] {
        guard let s = xcodebuildSettings["GCC_PREPROCESSOR_DEFINITIONS"] else { return [] }
        return s.components(separatedBy: " ")
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

    fileprivate lazy var xcProjectFile: XCProjectFile = {
        try! XCProjectFile(xcodeprojURL: self.type.projectFile!)
    }()

    fileprivate lazy var pbxTarget: PBXNativeTarget = {
        return self.xcProjectFile.project.targets
            .filter({$0.name == self.target }).first!
    }()

    fileprivate lazy var objects: [ProjectObject] = {
      return self.pbxTarget.buildPhases.reduce([], { (a, phase) -> [ProjectObject] in
            return a + phase.files
                        .map({ (file) -> ProjectObject? in
                                 if let fileRef = file.fileRef,
                                    let type = fileRef.string("lastKnownFileType"),
                                    let sourceType = ProjectObjectSourceType(rawValue: type),
                                    let path = fileRef.path,
                                    let name = path.components(separatedBy: "/").last,
                                    let relativePath = self.xcProjectFile.project.allObjects.FullFilePaths[fileRef.id] {
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

    fileprivate lazy var xcodebuildSettings: [String: String] = {
        return self.xcodebuildOutput!.components(separatedBy: "\n")
        .reduce([String: String]()) { (a, e) in
            let splitString = e.components(separatedBy: " = ")
            if splitString.count != 2 { return a }
            var b = a
            b.merge(
               [splitString[0].trimmingCharacters(in: CharacterSet.whitespaces):
                splitString[1].trimmingCharacters(in: CharacterSet.whitespaces)])
            return b
        }
    }()

    fileprivate lazy var xcodebuildOutput: String? = {
        let task = Process()
        task.launchPath = "/usr/bin/xcodebuild"
        task.currentDirectoryPath = self.projectDir.path
        task.arguments =
            (self.chosenScheme == nil ? [String]() : ["-scheme", self.chosenScheme!]) +
            (self.chosenTarget == nil ? [String]() : ["-target", self.chosenTarget!]) +
            (self.chosenConfiguration == nil ? [String]() : ["-configuration", self.chosenConfiguration!]) +
            ["-showBuildSettings"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch() 
        task.waitUntilExit()

        if task.terminationStatus != 0 { return nil }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()

        return String(data: data, encoding: .utf8)
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
