//
//  CsvParser.swift
//  db
//
//  Created by Joeri van Veen on 18/01/2021.
//

import Foundation

struct Csv {
    
    static func read (fromString data: String, forceDelimiter: Character? = nil) -> [Record] {
        let delimiter = forceDelimiter == nil
            ? detectDelimiter(data)
            : forceDelimiter!
        
        if data.isEmpty {
            return []
        }
        
        var records: [Record] = []
        var record: Record = [:]
        var headerRow: [String] = []
        var column = 0
        var headerComplete = false
        var parser = CsvParser(data, delimiter)
        
        fetcher: repeat {
            let fragment = parser.fetch()
            switch fragment {
                case .value:
                    if !headerComplete {
                        headerRow.append(parser.value)
                    } else {
                        if column < headerRow.count {
                            record[headerRow[column]] = parser.value
                        } else {
                            record["field\(column)"] = parser.value
                        }
                    }
                    column += 1
                case .recordSeparator:
                    if !headerComplete {
                        headerComplete = true
                    } else {
                        records.append(record)
                        record = [:]
                    }
                    column = 0
                case .end:
                    break fetcher
            }
        } while true
        
        return records
    }
    
    static private func detectDelimiter (_ data: String) -> Character {
        let sample = String(data.prefix(200)).characterCounts()
        let commas: Int = sample[","] ?? 0
        let tabs: Int = sample["\t"] ?? 0
        
        return commas > tabs ? "," : "\t"
    }
    
}

private struct CsvParser {
    let data: String
    let delimiter: Character
    var pointer: String.Index
    var previous: String.Index
    var valueStart: String.Index
    var valueEnd: String.Index
    var hasStarted = false
    
    init (_ data: String, _ delimiter: Character) {
        self.data = data
        self.pointer = data.startIndex
        self.previous = data.startIndex
        self.valueStart = data.startIndex
        self.valueEnd = data.startIndex
        self.delimiter = delimiter
    }
    
    mutating func fetch () -> CsvFragment {
        
        var inValue = false
        var inQuotedValue = false
        var quoteCount = -1
        
        valueStart = pointer
        valueEnd = pointer
        
        while pointer != data.endIndex {
            
            previous = pointer
            pointer = !hasStarted ? pointer : data.index(after: pointer)
            hasStarted = true
            
            if pointer == data.endIndex {
                if inQuotedValue {
                    valueEnd = previous
                    return .value
                } else {
                    return .end
                }
            } else if pointer == data.index(before: data.endIndex) && inValue && data[pointer] != "\n" {
                valueEnd = pointer
                return .value
            } else if data[pointer] == delimiter {
                if !inQuotedValue {
                    valueEnd = previous
                    return .value
                } else if quoteCount.isMultiple(of: 2) {
                    return .value
                }
            } else if data[pointer] == "\n" {
                if !inValue {
                    return .recordSeparator
                } else if !inQuotedValue {
                    valueEnd = previous
                    pointer = previous
                    return .value
                } else if quoteCount.isMultiple(of: 2) {
                    return .value
                }
            } else if data[pointer] == "\"" {
                if !inValue {
                    valueStart = pointer
                    inValue = true
                    inQuotedValue = true
                    quoteCount = 1
                } else {
                    valueEnd = pointer
                    quoteCount += 1
                }
            } else if data[pointer].isWhitespace {
                if !inValue {
                    continue
                } else if inQuotedValue && quoteCount.isMultiple(of: 2) {
                    return .value
                }
            } else {
                if !inValue {
                    valueStart = pointer
                }
                inValue = true
            }
            
        }
        
        return .end
    }
    
    var value: String {
        var value = data[valueStart...valueEnd]
        let isQuoted = (value.first == "\"")
        if value.first == "\"" {
            value = value.dropFirst()
        }
        if value.last == "\"" {
            value = value.dropLast()
        }
        if isQuoted {
            return value.replacingOccurrences(of: "\"\"", with: "\"")
        }
        return String(value)
    }
}

enum CsvFragment {
    case value
    case recordSeparator
    case end
}
