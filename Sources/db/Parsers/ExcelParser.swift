//
//  Excel.swift
//  db
//
//  Created by Joeri van Veen on 16/01/2021.
//

import Foundation
import CoreXLSX

struct ExcelParser {
    
    var file: XLSXFile
    var sharedStrings: SharedStrings
    
    static func read (fromFile path: String) throws -> [Record] {
        let excel = try ExcelParser(fromFile: path)
        return try excel.extractNamedRecords()
    }
    
    init (fromFile path: String) throws {
        guard
            let file = XLSXFile(filepath: path),
            let sharedStrings = try file.parseSharedStrings()
        else {
            throw Invalid.xlsx
        }
        
        self.file = file
        self.sharedStrings = sharedStrings
    }
    
    func extractNamedRecords () throws -> [Record] {
        var records: [Record] = []
        do {
            for workbook in try file.parseWorkbooks() {
                for (_, worksheetPath) in try file.parseWorksheetPathsAndNames(workbook: workbook) {
                    let worksheet = try file.parseWorksheet(at: worksheetPath)
                    parse(worksheet: worksheet, forFile: file, withStrings: sharedStrings, into: &records)
                }
            }
        } catch {
            throw Invalid.xlsx
        }
        return records
    }
    
    private func parse (
        worksheet: Worksheet,
        forFile file: XLSXFile,
        withStrings sharedStrings: SharedStrings,
        into records: inout [[String: String]]) {

        let rows = worksheet.data?.rows ?? []
        let stringish = try! NSRegularExpression(pattern: "[a-z]+")
        var stringValuesPerRow: [Int] = []

        for row in rows.prefix(10) {
            stringValuesPerRow.append(row.cells.filter { cell in
                let cellValue = cell.stringValue(sharedStrings) ?? ""
                return cellValue != "" && stringish.firstMatch(in: cellValue, range: NSRange(location: 0, length: cellValue.count)) != nil
            }.count)
        }

        let mostStringValues = stringValuesPerRow.max()
        let headerRow = stringValuesPerRow.firstIndex(where: { $0 == mostStringValues })!
        var headers: [String : String] = [:]
        
        worksheet.cells(atRows: [UInt(headerRow + 1)]).forEach { cell in
            headers[cell.reference.column.value] = Db.guaranteeValidField(cell.stringValue(sharedStrings) ?? "")
        }

        for row in rows.dropFirst(headerRow + 1) {
            var record: Record = [:]
            
            for cell in row.cells {
                let value = cell.stringValue(sharedStrings) ?? ""
                let field = headers[cell.reference.column.value] ?? "field"
                if value != "" {
                    record[field] = value
                }
            }

            records.append(record)
        }
    }
}
