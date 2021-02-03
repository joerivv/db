//
//  StringExtensions.swift
//  db
//
//  Created by Joeri van Veen on 17/01/2021.
//

import Foundation

struct EscapeOptions: OptionSet {
    let rawValue: UInt8
    
    static let backslashes = EscapeOptions(rawValue: 1 << 0)
    static let doubleQuotes = EscapeOptions(rawValue: 1 << 1)
    static let singleQuotes = EscapeOptions(rawValue: 1 << 2)
    static let lineEndings = EscapeOptions(rawValue: 1 << 3)
    static let tabs = EscapeOptions(rawValue: 1 << 4)
}

extension String {
    func escaped (_ charactersToEscape: EscapeOptions) -> String {
        var escapedString = self
        
        if charactersToEscape.contains(.backslashes) {
            escapedString = escapedString.replacingOccurrences(of: "\\", with: "\\\\")
        }
        
        if charactersToEscape.contains(.doubleQuotes) {
            escapedString = escapedString.replacingOccurrences(of: "\"", with: "\\\"")
        }
        
        if charactersToEscape.contains(.singleQuotes) {
            escapedString = escapedString.replacingOccurrences(of: "'", with: "\\'")
        }
        
        if charactersToEscape.contains(.lineEndings) {
            escapedString = escapedString.replacingOccurrences(of: "\n", with: "\\n")
        }
        
        if charactersToEscape.contains(.tabs) {
            escapedString = escapedString.replacingOccurrences(of: "\t", with: "\\t")
        }
        
        return escapedString
    }
    
    func unescaped (_ charactersToUnescape: EscapeOptions) -> String {
        var unescapedString = self
        
        
        if charactersToUnescape.contains(.doubleQuotes) {
            unescapedString = unescapedString.replacingOccurrences(of: "\\\"", with: "\"")
        }
        
        if charactersToUnescape.contains(.singleQuotes) {
            unescapedString = unescapedString.replacingOccurrences(of: "\\'", with: "'")
        }
        
        if charactersToUnescape.contains(.lineEndings) {
            unescapedString = unescapedString.replacingOccurrences(of: "\\n", with: "\n")
        }
        
        if charactersToUnescape.contains(.tabs) {
            unescapedString = unescapedString.replacingOccurrences(of: "\\t", with: "\t")
        }
        
        if charactersToUnescape.contains(.backslashes) {
            unescapedString = unescapedString.replacingOccurrences(of: "\\\\", with: "\\")
        }
        
        return unescapedString
    }
    
    func csvEscaped (for separator: String) -> String {
        if self.contains(separator) || self.contains("\n") || self.contains("\"") {
            return "\"\(self.replacingOccurrences(of: "\"", with: "\"\""))\""
        } else {
            return self
        }
    }
    
    func xmlEscaped () -> String {
        return self
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "'", with: "&apos;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
    
    func xmlUnescaped () -> String {
        self
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&amp;", with: "&")
    }
    
    func characterCounts() -> [String: Int] {
        var charCount: [String : Int] = [:]
        for c in self {
            let char = String(c)
            if charCount[char] == nil {
                charCount[char] = 0
            }
            charCount[char]! += 1
        }
        return charCount
    }
    
    func count (matchesOf pattern: String) -> Int {
        let regex = try! NSRegularExpression(pattern: pattern)
        return regex.numberOfMatches(in: self, options: [], range: NSRange(location: 0, length: self.count))
    }
    
    func looksToBeBinary () -> Bool {
        let sample = String(self.prefix(1000))
        let unprintables = try! NSRegularExpression(pattern: "[^\\x20-\\x7E\\t\\r\\n]")
        let unprintableCount = unprintables.numberOfMatches(in: sample, options: [], range: NSRange(location: 0, length: sample.count))
        
        return unprintableCount > 50
    }
}
