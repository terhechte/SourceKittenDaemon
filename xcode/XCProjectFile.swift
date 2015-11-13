//
//  XCProjectFile.swift
//  Xcode
//
//  Created by Tom Lokhorst on 2015-08-12.
//  Copyright (c) 2015 nonstrict. All rights reserved.
//

import Foundation

enum ProjectFileError : ErrorType, CustomStringConvertible {
  case InvalidData
  case NotXcodeproj
  case MissingPbxproj

  var description: String {
    switch self {
    case .InvalidData:
      return "Data in .pbxproj file not in expected format"
    case .NotXcodeproj:
      return "Path is not a .xcodeproj package"
    case .MissingPbxproj:
      return "project.pbxproj file missing"
    }
  }
}

public class AllObjects {
  var dict: [String: PBXObject] = [:]
  var fullFilePaths: [String: Path] = [:]

  func object<T : PBXObject>(key: String) -> T {
    let obj = dict[key]!
    if let t = obj as? T {
      return t
    }

    return T(id: key, dict: obj.dict, allObjects: self)
  }
}

public class XCProjectFile {
  public let project: PBXProject
  let dict: JsonObject
  let format: NSPropertyListFormat
  let allObjects = AllObjects()

  public convenience init(xcodeprojURL: NSURL) throws {

    let pbxprojURL = xcodeprojURL.URLByAppendingPathComponent("project.pbxproj")
    guard let data = NSData(contentsOfURL: pbxprojURL) else {
      throw ProjectFileError.MissingPbxproj
    }

    try self.init(propertyListData: data)
  }

  public convenience init(propertyListData data: NSData) throws {

    let options = NSPropertyListReadOptions.Immutable
    var format: NSPropertyListFormat = NSPropertyListFormat.BinaryFormat_v1_0
    let obj = try NSPropertyListSerialization.propertyListWithData(data, options: options, format: &format)

    guard let dict = obj as? JsonObject else {
      throw ProjectFileError.InvalidData
    }

    self.init(dict: dict, format: format)
  }

  init(dict: JsonObject, format: NSPropertyListFormat) {
    self.dict = dict
    self.format = format
    let objects = dict["objects"] as! [String: JsonObject]

    for (key, obj) in objects {
      allObjects.dict[key] = XCProjectFile.createObject(key, dict: obj, allObjects: allObjects)
    }

    let rootObjectId = dict["rootObject"]! as! String
    let projDict = objects[rootObjectId]!
    self.project = PBXProject(id: rootObjectId, dict: projDict, allObjects: allObjects)
    self.allObjects.fullFilePaths = paths(self.project.mainGroup, prefix: "")
  }

  static func projectName(url: NSURL) throws -> String {

    guard let subpaths = url.pathComponents,
          let last = subpaths.last,
          let range = last.rangeOfString(".xcodeproj")
    else {
      throw ProjectFileError.NotXcodeproj
    }

    return last.substringToIndex(range.startIndex)
  }

  static func createObject(id: String, dict: JsonObject, allObjects: AllObjects) -> PBXObject {
    let isa = dict["isa"] as? String

    if let isa = isa,
       let type = types[isa] {
      return type.init(id: id, dict: dict, allObjects: allObjects)
    }

    // Fallback
    assertionFailure("Unknown PBXObject subclass isa=\(isa)")
    return PBXObject(id: id, dict: dict, allObjects: allObjects)
  }

  func paths(current: PBXGroup, prefix: String) -> [String: Path] {

    var ps: [String: Path] = [:]

    for file in current.fileRefs {
      switch file.sourceTree {
      case .Group:
        ps[file.id] = .RelativeTo(.SourceRoot, prefix + "/" + file.path!)
      case .Absolute:
        ps[file.id] = .Absolute(file.path!)
      case let .RelativeTo(sourceTreeFolder):
        ps[file.id] = .RelativeTo(sourceTreeFolder, file.path!)
      }
    }

    for group in current.subGroups {
      if let path = group.path {
        ps += paths(group, prefix: prefix + "/" + path)
      }
      else {
        ps += paths(group, prefix: prefix)
      }
    }

    return ps
  }
}

let types: [String: PBXObject.Type] = [
  "PBXProject": PBXProject.self,
  "PBXContainerItemProxy": PBXContainerItemProxy.self,
  "PBXBuildFile": PBXBuildFile.self,
  "PBXCopyFilesBuildPhase": PBXCopyFilesBuildPhase.self,
  "PBXFrameworksBuildPhase": PBXFrameworksBuildPhase.self,
  "PBXHeadersBuildPhase": PBXHeadersBuildPhase.self,
  "PBXResourcesBuildPhase": PBXResourcesBuildPhase.self,
  "PBXShellScriptBuildPhase": PBXShellScriptBuildPhase.self,
  "PBXSourcesBuildPhase": PBXSourcesBuildPhase.self,
  "PBXBuildStyle": PBXBuildStyle.self,
  "XCBuildConfiguration": XCBuildConfiguration.self,
  "PBXAggregateTarget": PBXAggregateTarget.self,
  "PBXNativeTarget": PBXNativeTarget.self,
  "PBXTargetDependency": PBXTargetDependency.self,
  "XCConfigurationList": XCConfigurationList.self,
  "PBXReference": PBXReference.self,
  "PBXFileReference": PBXFileReference.self,
  "PBXGroup": PBXGroup.self,
  "PBXVariantGroup": PBXVariantGroup.self,
  "XCVersionGroup": XCVersionGroup.self
]
