//
//  Shell.swift
//  db
//
//  Created by Joeri van Veen on 24/01/2021.
//

import Foundation

struct Shell {
    
    static func format (
        text: String,
        background: ShellColour? = nil,
        foreground: ShellColour? = nil,
        bold: Bool = false) -> String {
        
        var formats: [String] = []
        
        if bold {
            formats.append("1")
        }
        
        if foreground != nil {
            formats.append(String(foreground!.rawValue))
        }
        
        if background != nil {
            formats.append(String(background!.rawValue + 10))
        }
        
        return "\u{001B}[\(formats.joined(separator: ";"))m\(text)\u{001B}[0m"
        
    }
    
    static func run (command: String) -> String{
        return run(launchPath: "/bin/zsh", arguments: ["-c", command])
    }
    
    static func run (applescript: String) -> String {
        return run(launchPath: "/usr/bin/osascript", arguments: ["-e", applescript])
    }
    
    static func run (launchPath: String, arguments: [String]) -> String {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = arguments
        task.currentDirectoryPath = FileManager.default.currentDirectoryPath
        task.launchPath = launchPath
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!
        
        return output
    }
    
}

enum ShellColour: Int {
    case black = 30
    case red = 31
    case green = 32
    case yellow = 33
    case blue = 34
    case magenta = 35
    case cyan = 36
    case white = 37
}
