//
//  main.swift
//  DefaultAppUtils
//
//  Created by TBXark Fan on 12/20/21.
//

import Foundation
import Cocoa


struct Info {
    var bundleId: String
    var raw: [String: Any]
    var utiTypes: [[String: Any]]
    
    subscript(_ key: String) -> Any? {
        return raw[key]
    }
}

func readInfoPlist(_ path: String) throws -> Info {
    var format = PropertyListSerialization.PropertyListFormat.xml
    let plistData = try Data(contentsOf: URL(fileURLWithPath: "\(path.trimmingCharacters(in: .whitespacesAndNewlines))/Contents/Info.plist"))
    guard let info = try PropertyListSerialization.propertyList(from: plistData, options: [], format: &format) as? [String: Any],
          let utiTypes = info["UTImportedTypeDeclarations"] as? [[String: Any]],
            let bundleID = info["CFBundleIdentifier"] as? String
    else {
        throw NSError()
    }
    return Info(bundleId: bundleID, raw: info, utiTypes: utiTypes)
}


print("Please input App path: ", terminator: "")
guard let appPath = readLine(strippingNewline: true)?.trimmingCharacters(in: .whitespacesAndNewlines),
      var info = try? readInfoPlist(appPath) else {
          print("Info.plist not found")
          exit(1)
}



print("Replace target app(Y/n): ", terminator: "")
if let y = readLine(strippingNewline: true)?.trimmingCharacters(in: .whitespacesAndNewlines), (y == "Y" || y == "y")  {
    print("Please input target app path: ", terminator: "")
    if let n = readLine(strippingNewline: true)?.trimmingCharacters(in: .whitespacesAndNewlines),
       let nInfo = try? readInfoPlist(n) {
        info.bundleId = nInfo.bundleId
    }
}

//com.macromates.TextMate

let cfBundleID = info.bundleId as CFString

var successCount = 0
var failedCount = 0

for utiType in info.utiTypes {
    guard
        let iden = utiType["UTTypeIdentifier"] as? String,
        let tagSpec = utiType["UTTypeTagSpecification"] as? [String: Any],
        let exts = tagSpec["public.filename-extension"] as? [String]
    else {
        continue
    }
    print("Set \(iden)(Y/n): ", terminator: "")
    guard let y = readLine(strippingNewline: true)?.trimmingCharacters(in: .whitespacesAndNewlines), (y == "Y" || y == "y") else {
        continue
    }
    for ext in exts {
      
        let utiString = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, ext as CFString, nil)!.takeUnretainedValue()
        let status = LSSetDefaultRoleHandlerForContentType(utiString, .all, cfBundleID)
        if status == kOSReturnSuccess {
            print("success for \(ext)")
            successCount += 1
        } else {
            print("failed for \(ext): return value \(status)")
            failedCount += 1
        }
    }
}

