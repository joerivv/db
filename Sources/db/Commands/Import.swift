//
//  Edit.swift
//  db
//
//  Created by Joeri van Veen on 04/01/2021.
//

import Foundation
import ArgumentParser

struct Import: ParsableCommand {
    
    public static let configuration = CommandConfiguration(abstract: "Import data from a file.")
    
    @Flag(name: .customShort("s"), help: "Import from string literal.")
    private var literal: Bool = false
    
    @Argument(help: "Data file to import.", completion: CompletionKind.file())
    private var path: String = ""
    
    @Option(name: .long, parsing: .scanningForValue, help: "Specify data type (csv, tsv, xlsx, xml, json, list, value)", completion: nil)
    private var type: String?
    
    @Flag(help: "View detailed logging.")
    private var verbose: Bool = false
    
    init () { }
    
    init (usingDefaults: Bool) {
        self.literal = false
        self.path = ""
        self.type = nil
        self.verbose = false
    }
    
    func run() throws {
        
        do {
            
            try Db.read()
            
            if path == "" || literal {
                let data = try getStringData()
                try Db.import(fromString: data, ofType: type ?? StringParser.figureOutDataType(data))
            } else {
                try Db.import(fromFile: path, withType: type)
            }
            
            try Db.write()
            
        } catch Cannot.readDatabase {
            ErrorMessage.show(Cannot.readDatabase, includeVerboseMessage: !verbose)
            
        } catch Cannot.importData {
            ErrorMessage.show(Cannot.importData, includeVerboseMessage: !verbose)
            
        } catch Cannot.importFile(let type) {
            ErrorMessage.show(Cannot.importFile(type), includeVerboseMessage: !verbose)
            
        } catch Unsupported.inputFormat(let format) {
            ErrorMessage.show(Unsupported.inputFormat(format))
            
        } catch Unsupported.inputFileFormat(let format) {
            ErrorMessage.show(Unsupported.inputFileFormat(format))
            
        } catch Unsupported.inputMethod {
            ErrorMessage.show(Unsupported.inputMethod)
            
        } catch Unsupported.redirectionFile {
            ErrorMessage.show(Unsupported.redirectionFile)
            
        } catch No.dataAvailableForInput {
            // Fail silently
            
        } catch Cannot.saveDatabase {
            ErrorMessage.show(Cannot.saveDatabase, includeVerboseMessage: !verbose)
        }
        
        if verbose {
            ErrorMessage.showInternalError()
        }
        
    }
    
    func getStringData () throws -> String {
        if path != "" {
            return treatAsStringLiteral(path)
        } else if StandardInput.isAvailable() {
            return try getStandardInput()
        } else {
            throw No.dataAvailableForInput
        }
    }
    
    func getStandardInput () throws -> String {
        let cameFromFile = StandardInput.isRedirectedFile()
        let cameFromPipe = StandardInput.isPipedString()
        let string = StandardInput.read()
        
        if cameFromPipe {
            return string
        }
        
        if cameFromFile {
            if string.looksToBeBinary() {
                throw Unsupported.redirectionFile
            }
            
            return string
        }
        
        throw Unsupported.inputMethod
    }
    
    func treatAsStringLiteral (_ string: String) -> String {
        return string
            .unescaped([.lineEndings, .tabs])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
}
