//
//  PBXObject.swift
//  Xcode
//
//  Created by Tom Lokhorst on 2015-08-29.
//  Copyright © 2015 nonstrict. All rights reserved.
//

import Foundation

typealias JsonObject = [String: AnyObject]

public /* abstract */ class PBXObject {
  let id: String
  let dict: JsonObject
  let allObjects: AllObjects

  public lazy var isa: String = self.string("isa")!

  public required init(id: String, dict: AnyObject, allObjects: AllObjects) {
    self.id = id
    self.dict = dict as! JsonObject
    self.allObjects = allObjects
  }

  func string(key: String) -> String? {
    return dict[key] as? String
  }

  func object<T : PBXObject>(key: String) -> T? {
    guard let objectKey = dict[key] as? String else {
      return nil
    }

    let obj: T = allObjects.object(objectKey)
    return obj
  }

  func object<T : PBXObject>(key: String) -> T {
    let objectKey = dict[key] as! String
    return allObjects.object(objectKey)
  }

  func objects<T : PBXObject>(key: String) -> [T] {
    let objectKeys = dict[key] as! [String]
    return objectKeys.map(allObjects.object)
  }
}

public /* abstract */ class PBXContainer : PBXObject {
}

public class PBXProject : PBXContainer {
  public lazy var targets: [PBXNativeTarget] = self.objects("targets")
  public lazy var mainGroup: PBXGroup = self.object("mainGroup")
  public lazy var buildConfigurationList: XCConfigurationList = self.object("buildConfigurationList")
}

public /* abstract */ class PBXContainerItem : PBXObject {
}

public class PBXContainerItemProxy : PBXContainerItem {
}

public /* abstract */ class PBXProjectItem : PBXContainerItem {
}

public class PBXBuildFile : PBXProjectItem {
  public lazy var fileRef: PBXReference? = self.object("fileRef")
}


public /* abstract */ class PBXBuildPhase : PBXProjectItem {
  public lazy var files: [PBXBuildFile] = self.objects("files")
}

public class PBXCopyFilesBuildPhase : PBXBuildPhase {
  public lazy var name: String? = self.string("name")
}

public class PBXFrameworksBuildPhase : PBXBuildPhase {
}

public class PBXHeadersBuildPhase : PBXBuildPhase {
}

public class PBXResourcesBuildPhase : PBXBuildPhase {
}

public class PBXShellScriptBuildPhase : PBXBuildPhase {
  public lazy var name: String? = self.string("name")
  public lazy var shellScript: String = self.string("shellScript")!
}

public class PBXSourcesBuildPhase : PBXBuildPhase {
}

public class PBXBuildStyle : PBXProjectItem {
}

public class XCBuildConfiguration : PBXBuildStyle {
  public lazy var name: String = self.string("name")!
}

public /* abstract */ class PBXTarget : PBXProjectItem {
  public lazy var buildConfigurationList: XCConfigurationList = self.object("buildConfigurationList")
  public lazy var name: String = self.string("name")!
  public lazy var productName: String = self.string("productName")!
  public lazy var buildPhases: [PBXBuildPhase] = self.objects("buildPhases")
}

public class PBXAggregateTarget : PBXTarget {
}

public class PBXNativeTarget : PBXTarget {
}

public class PBXTargetDependency : PBXProjectItem {
}

public class XCConfigurationList : PBXProjectItem {
}

public class PBXReference : PBXContainerItem {
  public lazy var name: String? = self.string("name")
  public lazy var path: String? = self.string("path")
  public lazy var sourceTree: SourceTree = self.string("sourceTree").flatMap(SourceTree.init)!
}

public class PBXFileReference : PBXReference {

  // convenience accessor
  public lazy var fullPath: Path = self.allObjects.fullFilePaths[self.id]!
}

public class PBXGroup : PBXReference {
  public lazy var children: [PBXReference] = self.objects("children")

  // convenience accessors
  public lazy var subGroups: [PBXGroup] = self.children.ofType(PBXGroup.self)
  public lazy var fileRefs: [PBXFileReference] = self.children.ofType(PBXFileReference)
}

public class PBXVariantGroup : PBXGroup {
}

public class XCVersionGroup : PBXReference {
}


public enum SourceTree {
  case Absolute
  case Group
  case RelativeTo(SourceTreeFolder)

  init?(sourceTreeString: String) {
    switch sourceTreeString {
    case "<absolute>":
      self = .Absolute
    case "<group>":
      self = .Group
    default:
      guard let sourceTreeFolder = SourceTreeFolder(rawValue: sourceTreeString) else { return nil }
      self = .RelativeTo(sourceTreeFolder)
    }
  }
}

public enum SourceTreeFolder: String {
  case SourceRoot = "SOURCE_ROOT"
  case BuildProductsDir = "BUILT_PRODUCTS_DIR"
  case DeveloperDir = "DEVELOPER_DIR"
  case SDKRoot = "SDKROOT"
}

public enum Path {
  case Absolute(String)
  case RelativeTo(SourceTreeFolder, String)
}

