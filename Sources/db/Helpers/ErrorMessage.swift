//
//  ErrorMessage.swift
//  db
//
//  Created by Joeri van Veen on 31/01/2021.
//

import Foundation

struct ErrorMessage {
    static func `for` (_ error: Cannot, includeVerboseMessage: Bool) -> String {
        var sentences: [String] = [Shell.format(text: "Error:", foreground: .red, bold: true)]
        
        switch error {
            case Cannot.importData:
                sentences.append("Failed to import data.")
            case Cannot.importFile(_):
                sentences.append("Failed to import file.")
            case Cannot.readDatabase:
                sentences.append("Database may be corrupt.")
                if Db.isCompressed {
                    sentences.append("Open with `sqlite3 \(Db.name).xmldb` to verify it has a table `data` with TEXT fields.")
                } else {
                    sentences.append("Open in a text editor to verify the validity of the XML file.")
                }
            case Cannot.readScript:
                sentences.append("Failed to open JavaScript file.")
            case Cannot.retrieveFileSize:
                sentences.append("Couldn't retrieve file size")
            case Cannot.runServer:
                sentences.append("Cannot start server. Is nothing running on the chosen port?")
            case Cannot.saveDatabase:
                sentences.append("Failed to save database.")
            case Cannot.compressDatabase:
                sentences.append("Compression failed.")
        }
        
        if includeVerboseMessage {
            sentences.append(Shell.format(text: "\nUse `--verbose` to see the internal error.", foreground: ShellColour.yellow))
        }
        
        return sentences.joined(separator: " ") + "\n"
    }
    
    static func `for` (_ error: Unsupported) -> String {
        var sentences: [String] = [Shell.format(text: "Aborting:", foreground: .red, bold: true)]
        
        switch error {
            case Unsupported.inputFormat(let format):
                sentences.append("Unsupported input format `\(format)`.")
                sentences.append("\nSupports: value, csv, tsv, json, xml, list")
            case Unsupported.inputFileFormat(let format):
                sentences.append("Unsupported input format `\(format)`.")
                sentences.append("\nSupports: .xml, .csv, .tsv, .json, .xlsx, .txt")
                sentences.append(Shell.format(text: "\nUse `--type <format>` to force an interpretation.", foreground: .yellow))
            case Unsupported.inputMethod:
                sentences.append("Only redirected files and piped strings are accepted from stdin.")
            case Unsupported.outputFormat(let format):
                sentences.append("Unsupported output format `\(format)`.")
                sentences.append("\nSupports: xml, json, txt, csv, tsv, php, list")
            case Unsupported.redirectionFile:
                sentences.append("Input from redirection looks to be binary. Use `import` instead.")
        }
        
        return sentences.joined(separator: " ") + "\n"
    }
    
    static func `for` (_ error: Invalid) -> String {
        var sentences: [String] = [Shell.format(text: "Aborting:", foreground: .red, bold: true)]
        
        switch error {
            case Invalid.fieldName(let name):
                sentences.append("The field name \"\(name)\" is not valid. Only letters, numbers and dashes allowed. Field may not start with a number.")
            case Invalid.json:
                sentences.append("Invalid JSON.")
            case Invalid.xlsx:
                sentences.append("Excel file might be corrupt.")
        }
        
        return sentences.joined(separator: " ") + "\n"
    }
    
    static func `for` (_ error: Warn) -> String {
        var sentences: [String] = []
        
        switch error {
            case Warn.alreadyCompressed:
                sentences.append("Already compresssed.")
            case Warn.fieldsWillBeOverwritten:
                sentences.append(Shell.format(text: "Warning:", foreground: .yellow, bold: true))
                sentences.append("This will overwrite existing fields. Use `--force` to continue anyway.")
        }
        
        return sentences.joined(separator: " ") + "\n"
    }
    
    static func show (_ error: Cannot, includeVerboseMessage: Bool) {
        fputs(`for`(error, includeVerboseMessage: includeVerboseMessage), stderr)
    }
    
    static func show (_ error: Unsupported) {
        fputs(`for`(error), stderr)
    }
    
    static func show (_ error: Invalid) {
        fputs(`for`(error), stderr)
    }
    
    static func show (_ error: Warn) {
        fputs(`for`(error), stderr)
    }
    static func showInternalError () {
        if Db.internalError != nil {
            fputs("\nDetails:\n" + Db.internalError!.localizedDescription, stderr)
        }
    }
}
