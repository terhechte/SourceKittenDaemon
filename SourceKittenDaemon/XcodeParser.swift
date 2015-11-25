//
//  XcodeParser.swift
//  SourceKittenDaemon
//
//  Created by Benedikt Terhechte on 12/11/15.
//  Copyright © 2015 Benedikt Terhechte. All rights reserved.
//

import Foundation

enum ProjectSourceType: String {
    case Swift = "sourcecode.swift"
    case Plist = "text.plist.xml"
    case Framework = "wrapper.framework"
}

struct ProjectObject {
    let type: ProjectSourceType
    let fileName: String
    let pathInProject: Path
}

struct XcodeParser {
    
    let basePath: String
    
    let proj: XCProjectFile
    
    private var frameworks: [ProjectObject]
    
    private var projectFiles: [ProjectObject]
    
    func projectPaths(exceptions: (filename: String) -> Bool) -> [String] {
        return self.projectFiles.reduce([String]())
             { (cache: [String], object: ProjectObject) -> [String] in
                guard !exceptions(filename: object.fileName) else { return cache }
                switch object.pathInProject {
                case .Absolute(let path): return cache + [path]
                case .RelativeTo(let root, let path)
                    where root == .SourceRoot: return cache + ["\(self.basePath)/\(path)"]
                case .RelativeTo(_, let path): return cache + ["\(self.basePath)\(path)"]
                }
        }
    }
    
    let target: PBXNativeTarget
    
    init?(project: ProjectType, targetName: String?) {
        
        let aProject: XCProjectFile
        do {
            aProject = try XCProjectFile(xcodeprojURL: project.projectFileURL()!)
        } catch (let err as ProjectFileError) {
            print(err.description)
            return nil
        } catch (_ as NSError) {
            print("Could not read xcode project: \(project.projectFileURL()?.path)")
            return nil
        }
        
        self.basePath = project.projectDir()
        self.proj = aProject
        self.frameworks = []
        self.projectFiles = []
        
        /**
        Try to find the target, either the named one, or the first one
        */
        if let targetName = targetName {
            
            let namedTarget = proj.project.targets.filter({ (a) -> Bool in
                return a.name == targetName
            })
            
            guard let target = namedTarget.first
                else {
                    print("Unknown target \(targetName) in Project")
                    return nil
            }
            
            self.target = target
        } else if let target = proj.project.targets.first {
            // take the first target
            self.target = target
        } else {
            print("No valid target in project")
            return nil
        }
        
        for buildPhase in target.buildPhases {
        
            // now access all frameworks for this target.
            if let frameworkPhase = buildPhase as? PBXFrameworksBuildPhase {
                self.frameworks = self.filesFromPhase(proj.project, phase: frameworkPhase)
            }
            
            // now access all files for this target
            if let filesPhase = buildPhase as? PBXSourcesBuildPhase {
                self.projectFiles = self.filesFromPhase(proj.project, phase: filesPhase)
            }
            
            // finally, access all special build settings for this target
            // FIXME: Todo
        }
    }
    
    func filesFromPhase(project: PBXProject, phase: PBXBuildPhase) -> [ProjectObject] {
        guard let fp = phase.dict["files"] as? [String]
            else {
                return []
        }
        
        var files = [ProjectObject]()
        
        for s in fp {
            let file = project.allObjects.object(s)
            guard let fileRef = file.dict["fileRef"] as? String
                else { continue }
            let fileRefCon = project.allObjects.object(fileRef)
            
            guard let filePath = fileRefCon.dict["path"] as? String,
                fileName = filePath.componentsSeparatedByString("/").last,
                fullPath = project.allObjects.fullFilePaths[fileRef]
                else { continue }
            
            let type = fileRefCon.dict["lastKnownFileType"]
            let ftype = fileRefCon.dict["explicitFileType"]
            
            if let type = type as? String,
                stype = ProjectSourceType.init(rawValue: type) {
                    files.append(ProjectObject(type: stype, fileName: fileName, pathInProject: fullPath))
            } else if let _ = ftype as? String {
                files.append(ProjectObject(type: ProjectSourceType.Framework, fileName: fileName, pathInProject: fullPath))
            } else {
                print("unknown filetype \(type) \(ftype)")
            }
        }
        
        return files
    }
    
    func pathForGroup(group: PBXGroup) -> String {
        return ""
    }
}
