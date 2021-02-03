//
//  JavaScriptHooks.swift
//  db
//
//  Created by Joeri van Veen on 20/01/2021.
//

import Foundation

struct JavaScriptHooks {
    
    static let consoleLog: @convention(block) (String) -> Void = { message in
        print(message)
    }
    
    static let dbRead: @convention(block) () -> Bool = {
        Db.records = []
        try? Db.read()
        return Db.internalError == nil
    }
    
    static let dbWrite: @convention(block) () -> Bool = {
        try? Db.write()
        return Db.internalError == nil
    }
    
    static let dbImport: @convention(block) (String) -> [Record] = { path in
        Db.records = []
        try? Db.import(fromFile: path)
        return Db.records
    }
    
    static let dbAdd: @convention(block) (String, String) -> [Record] = { data, type in
        let trimmed = data.trimmingCharacters(in: .whitespacesAndNewlines)
        let dataType = type != "" ? type : StringParser.figureOutDataType(trimmed)
        
        Db.records = []
        try? Db.import(fromString: trimmed, ofType: dataType)
        
        return Db.records
    }
    
    static let dbGetRecords: @convention(block) () -> [Record] = {
        return Db.records
    }
    
    static let dbSetRecords: @convention(block) ([Record]) -> Void = { records in
        Db.records = records
    }
    
    static let dbGetError: @convention(block) () -> String = {
        if Db.internalError == nil {
            return ""
        } else {
            return Db.internalError!.localizedDescription
        }
    }
    
    static let fileRead: @convention(block) (String) -> String = { path in
        return try! String(contentsOfFile: path)
    }
    
    static let fileWrite: @convention(block) (String, String) -> Void = { path, contents in
        try! contents.write(toFile: path, atomically: true, encoding: .utf8)
    }
    
    static let itemExists: @convention(block) (String) -> Bool = { path in
        return FileManager.default.fileExists(atPath: path)
    }
    
    static let itemTrash: @convention(block) (String) -> Void = { path in
        try! FileManager.default.trashItem(at: URL(fileURLWithPath: path), resultingItemURL: nil)
    }
    
    static let itemMoveTo: @convention(block) (String, String) -> Void = { oldPath, newPath in
        if !FileManager.default.fileExists(atPath: newPath) {
            try! FileManager.default.moveItem(atPath: oldPath, toPath: newPath)
        }
    }
    
    static let itemCopyTo: @convention(block) (String, String) -> Void = { source, destination in
        if !FileManager.default.fileExists(atPath: destination) {
            try! FileManager.default.copyItem(atPath: source, toPath: destination)
        }
    }
    
    static let folderMake: @convention(block) (String) -> Void = { path in
        if !FileManager.default.fileExists(atPath: path) {
            try! FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    static let folderItems: @convention(block) (String) -> [[String : String]] = { path in
        return try! FileManager.default.contentsOfDirectory(atPath: path).map { item in
            var isFolder : ObjCBool = false
            FileManager.default.fileExists(atPath: item, isDirectory: &isFolder)
            return [
                "path": path + "/" + item,
                "type": isFolder.boolValue ? "folder" : "file"
            ]
        }
    }
    
    static let folderPath: @convention(block) (String) -> String = { location in
        switch location {
            case "home":
                return FileManager.default.homeDirectoryForCurrentUser.path
            case "desktop":
                return try! FileManager.default.url(for: .desktopDirectory, in: .userDomainMask, appropriateFor: nil, create: false).path
            case "documents":
                return try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).path
            case "downloads":
                return try! FileManager.default.url(for: .downloadsDirectory, in: .userDomainMask, appropriateFor: nil, create: false).path
            case "current":
                return FileManager.default.currentDirectoryPath
            default:
                return ""
        }
    }
    
    static let shell: @convention(block) (String) -> String = { command in
        Shell.run(command: command)
    }
    
    static let applescript: @convention(block) (String) -> String = { script in
        Shell.run(applescript: script)
    }
    
}
