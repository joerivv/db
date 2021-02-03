//
//  Exceptions.swift
//  db
//
//  Created by Joeri van Veen on 24/01/2021.
//

import Foundation

enum Cannot: Error {
    case readDatabase
    case saveDatabase
    case importFile(String)
    case importData
    case runServer
    case retrieveFileSize
    case readScript
    case compressDatabase
}

enum Unsupported: Error {
    case outputFormat(String)
    case inputFormat(String)
    case inputFileFormat(String)
    case inputMethod
    case redirectionFile
}

enum Invalid: Error {
    case fieldName(String)
    case json
    case xlsx
}

enum Warn: Error {
    case fieldsWillBeOverwritten
    case alreadyCompressed
}

enum SqliteFailed: Error {
    case toConnect
    case toCreateTable
    case toDropTable
    case toRenameTable
    case toSelectRecords
    case toInsertRecords
}

enum No: Error {
    case dataAvailableForInput
}
