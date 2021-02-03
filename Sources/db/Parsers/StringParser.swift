//
//  StringParser.swift
//  db
//
//  Created by Joeri van Veen on 18/01/2021.
//

import Foundation

struct StringParser {
    
    static func figureOutDataType (_ data: String) -> String {
        let sample = String(data.prefix(200))
        
        if sample.first == "{" || sample.first == "[" {
            return "json"
        }
        
        if sample.first == "<" {
            return "xml"
        }
        
        let charCounts = sample.characterCounts()
        let charCountsFirstLine = sample.components(separatedBy: CharacterSet.newlines).first!.characterCounts()
        let commas = charCountsFirstLine[","] ?? 0
        let tabs = charCountsFirstLine["\t"] ?? 0
        let newlines = charCounts["\n"] ?? 0
        
        if commas == 0 && tabs == 0 {
            return newlines > 0 ? "list" : "value"
        }
        
        return tabs > commas ? "tsv" : "csv"
    }
    
}
