//
//  XcodeParser.swift
//  SourceKittenDaemon
//
//  Created by Benedikt Terhechte on 12/11/15.
//  Copyright © 2015 Benedikt Terhechte. All rights reserved.
//

import Foundation

class Project {

    let type: ProjectType
    let targetName: String?
    let configurationName: String?

    init(type: ProjectType,
         targetName: String?,
         configurationName: String?) throws {
        
        self.type = type
        self.targetName = targetName
        self.configurationName = configurationName

        guard type.projectDir != nil
            else { throw ProjectError.ProjectNotFound(type.path) }

        guard type.projectFile != nil
            else { throw ProjectError.ProjectNotFound(type.path) }
        
        guard projectFile.project.targets.count > 0
            else { throw ProjectError.NoValidTarget }
    }

    var projectDir: NSURL { return self.type.projectDir! }
    var srcRoot: NSURL { return projectDir }

    lazy var objects: [ProjectObject] = {
      return self.target.buildPhases.reduce([], combine: { (a, phase) -> [ProjectObject] in
            return a + phase.files
                        .map({ (file) -> ProjectObject? in
                                 if let fileRef = file.fileRef,
                                    type = fileRef.string("lastKnownFileType"),
                                    sourceType = ProjectObjectSourceType(rawValue: type),
                                    path = fileRef.path,
                                    name = path.componentsSeparatedByString("/").last,
                                    relativePath = self.projectFile.project.allObjects.fullFilePaths[fileRef.id] {
                                     return ProjectObject(type: sourceType,
                                                          fileName: name,
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

    var sourceObjects: [ProjectObject] {
        guard let phase = target.buildPhases.filter({ ($0 as? PBXSourcesBuildPhase) != nil }).first
            else { return [] }
        return objects.filter { $0.buildPhase.id == phase.id }
    }

    var frameworkObjects: [ProjectObject] {
        guard let phase = target.buildPhases.filter({ ($0 as? PBXFrameworksBuildPhase) != nil }).first
            else { return [] }
        return objects.filter { $0.buildPhase.id == phase.id }
    }

    private lazy var projectFile: XCProjectFile = {
        try! XCProjectFile(xcodeprojURL: self.type.projectFile!)
    }()
    
    private lazy var target: PBXNativeTarget = {
        return self.projectFile.project.targets.filter({
            self.targetName == nil ? false : $0.name == self.targetName! }).first ??
        self.projectFile.project.targets.first!
    }()

}

struct ProjectObject {
    let type: ProjectObjectSourceType
    let fileName: String
    let relativePath: Path
    let buildPhase: PBXBuildPhase
}

enum ProjectObjectSourceType: String {
    case Swift = "sourcecode.swift"
    case Plist = "text.plist.xml"
    case Framework = "wrapper.framework"
}

