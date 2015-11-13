//
//  Serialization.swift
//  Xcode
//
//  Created by Tom Lokhorst on 2015-08-29.
//  Copyright © 2015 nonstrict. All rights reserved.
//

import Foundation

extension XCProjectFile {

  public func writeToXcodeproj(xcodeprojURL url: NSURL) throws -> Bool {

    try NSFileManager.defaultManager().createDirectoryAtURL(url, withIntermediateDirectories: true, attributes: nil)

    let name = try XCProjectFile.projectName(url)
    let path = url.URLByAppendingPathComponent("project.pbxproj")

    let serializer = Serializer(projectName: name, projectFile: self)

    if format == NSPropertyListFormat.OpenStepFormat {
      try serializer.openStepSerialization.writeToURL(path, atomically: true, encoding: NSUTF8StringEncoding)
      return true
    }
    else {
      let data = try NSPropertyListSerialization.dataWithPropertyList(dict, format: format, options: 0)
      return data.writeToURL(path, atomically: true)
    }
  }

  public func serialize(projectName: String) throws -> NSData {

    let serializer = Serializer(projectName: projectName, projectFile: self)

    if format == NSPropertyListFormat.OpenStepFormat {
      return serializer.openStepSerialization.dataUsingEncoding(NSUTF8StringEncoding)!
    }
    else {
      return try NSPropertyListSerialization.dataWithPropertyList(dict, format: format, options: 0)
    }
  }
}

let nonescapeRegex = try! NSRegularExpression(pattern: "^[a-z0-9_\\.\\/]+$", options: NSRegularExpressionOptions.CaseInsensitive)
let specialRegexes = [
  "\\\\": try! NSRegularExpression(pattern: "\\\\", options: []),
  "\\\"": try! NSRegularExpression(pattern: "\"", options: []),
  "\\n": try! NSRegularExpression(pattern: "\\n", options: []),
  "\\r": try! NSRegularExpression(pattern: "\\r", options: []),
  "\\t": try! NSRegularExpression(pattern: "\\t", options: []),
]

internal class Serializer {

  let projectName: String
  let projectFile: XCProjectFile

  init(projectName: String, projectFile: XCProjectFile) {
    self.projectName = projectName
    self.projectFile = projectFile
  }

  lazy var targetsByConfigId: [String: PBXNativeTarget] = {
    var dict: [String: PBXNativeTarget] = [:]
    for target in self.projectFile.project.targets {
      dict[target.buildConfigurationList.id] = target
    }

    return dict
  }()

  lazy var buildPhaseByFileId: [String: PBXBuildPhase] = {

    let buildPhases = self.projectFile.allObjects.dict.values.ofType(PBXBuildPhase)

    var dict: [String: PBXBuildPhase] = [:]
    for buildPhase in buildPhases {
      for file in buildPhase.files {
        dict[file.id] = buildPhase
      }
    }

    return dict
  }()

  var openStepSerialization: String {
    var lines = [
      "// !$*UTF8*$!",
      "{",
    ]

    for key in projectFile.dict.keys.sort() {
      let val: AnyObject = projectFile.dict[key]!

      if key == "objects" {

        lines.append("\tobjects = {")

        let groupedObjects = projectFile.allObjects.dict.values
          .groupBy { $0.isa }
          .sortBy { $0.0 }

        for (isa, objects) in groupedObjects {
          lines.append("")
          lines.append("/* Begin \(isa) section */")

          for object in objects.sortBy({ $0.id }) {

            let multiline = isa != "PBXBuildFile" && isa != "PBXFileReference"

            let parts = rows(isa, objKey: object.id, multiline: multiline, dict: object.dict)
            if multiline {
              for ln in parts {
                lines.append("\t\t" + ln)
              }
            }
            else {
              lines.append("\t\t" + parts.joinWithSeparator(""))
            }
          }

          lines.append("/* End \(isa) section */")
        }
        lines.append("\t};")
      }
      else {
        var comment = "";
        if key == "rootObject" {
          comment = " /* Project object */"
        }

        let row = "\(key) = \(val)\(comment);"
        for line in row.componentsSeparatedByString("\n") {
          lines.append("\t\(line)")
        }
      }
    }

    lines.append("}\n")

    return lines.joinWithSeparator("\n")
  }

  func comment(key: String, verbose: Bool) -> String? {
    if key == projectFile.project.id {
      return "Project object"
    }

    if let obj = projectFile.allObjects.dict[key] {
      if let name = obj.dict["name"] as? String {
        return name
      }
      if let path = obj.dict["path"] as? String {
        return path
      }
      if let ref = obj as? PBXReference {
        return ref.name ?? ref.path
      }
      if let nativeTarget = obj as? PBXNativeTarget {
        return verbose ? nativeTarget.name : nil
      }
      if let config = obj as? XCBuildConfiguration {
        return config.name
      }
      if let copyFiles = obj as? PBXCopyFilesBuildPhase {
        return copyFiles.name
      }
      if obj is PBXFrameworksBuildPhase {
        return "Frameworks"
      }
      if obj is PBXSourcesBuildPhase {
        return "Sources"
      }
      if obj is PBXResourcesBuildPhase {
        return "Resources"
      }
      if obj is PBXShellScriptBuildPhase {
        return "ShellScript"
      }
      if let shellScript = obj as? PBXShellScriptBuildPhase {
        return shellScript.name
      }
      if let buildFile = obj as? PBXBuildFile {
        if let buildPhase = buildPhaseByFileId[key],
          let group = comment(buildPhase.id, verbose: verbose) {

          if let fileRefId = buildFile.fileRef?.id {
            if let fileRef = comment(fileRefId, verbose: verbose) {
              return "\(fileRef) in \(group)"
            }
          }
          else {
            return "(null) in \(group)"
          }
        }
      }
      if obj is XCConfigurationList {
        if let target = targetsByConfigId[key] {
          return "Build configuration list for \(target.isa) \"\(target.name)\""
        }
        return "Build configuration list for PBXProject \"\(projectName)\""
      }

      return obj.isa
    }

    return nil
  }

  func valStr(val: String) -> String {

    var str = val
    for (replacement, regex) in specialRegexes {
      let range = NSRange(location: 0, length: str.utf16.count)
      let template = NSRegularExpression.escapedTemplateForString(replacement)
      str = regex.stringByReplacingMatchesInString(str, options: [], range: range, withTemplate: template)
    }

    let range = NSRange(location: 0, length: str.utf16.count)
    if let _ = nonescapeRegex.firstMatchInString(str, options: [], range: range) {
      return str
    }

    return "\"\(str)\""
  }

  func objval(key: String, val: AnyObject, multiline: Bool) -> [String] {
    var parts: [String] = []
    let keyStr = valStr(key)

    if let valArr = val as? [String] {
      parts.append("\(keyStr) = (")

      var ps: [String] = []
      for valItem in valArr {
        let str = valStr(valItem)

        var extraComment = ""
        if let c = comment(valItem, verbose: true) {
          extraComment = " /* \(c) */"
        }

        ps.append("\(str)\(extraComment),")
      }
      if multiline {
        for p in ps {
          parts.append("\t\(p)")
        }
        parts.append(");")
      }
      else {
        let space = valArr.isEmpty ? "" : " "
        parts.append(ps.joinWithSeparator("") + space + "); ")
      }

    }
    else if let valObj = val as? [String: AnyObject] {
      parts.append("\(keyStr) = {")

      for valKey in valObj.keys.sort() {
        let valVal: AnyObject = valObj[valKey]!
        let ps = objval(valKey, val: valVal, multiline: multiline)

        if multiline {
          for p in ps {
            parts.append("\t\(p)")
          }
        }
        else {
          parts.append(ps.joinWithSeparator("") + "}; ")
        }
      }

      if multiline {
        parts.append("};")
      }

    }
    else {
      let str = valStr("\(val)")

      var extraComment = "";
      if let c = comment(str, verbose: false) {
        extraComment = " /* \(c) */"
      }

      if key == "remoteGlobalIDString" || key == "TestTargetID" {
        extraComment = ""
      }

      if multiline {
        parts.append("\(keyStr) = \(str)\(extraComment);")
      }
      else {
        parts.append("\(keyStr) = \(str)\(extraComment); ")
      }
    }

    return parts
  }

  func rows(type: String, objKey: String, multiline: Bool, dict: JsonObject) -> [String] {

    var parts: [String] = []
    if multiline {
      parts.append("isa = \(type);")
    }
    else {
      parts.append("isa = \(type); ")
    }

    for key in dict.keys.sort() {
      if key == "isa" { continue }
      let val: AnyObject = dict[key]!

      for p in objval(key, val: val, multiline: multiline) {
        parts.append(p)
      }
    }

    var objComment = ""
    if let c = comment(objKey, verbose: true) {
      objComment = " /* \(c) */"
    }

    let opening = "\(objKey)\(objComment) = {"
    let closing = "};"

    if multiline {
      var lines: [String] = []
      lines.append(opening)
      for part in parts {
        lines.append("\t\(part)")
      }
      lines.append(closing)
      return lines
    }
    else {
      return [opening + parts.joinWithSeparator("") + closing]
    }
  }
}
