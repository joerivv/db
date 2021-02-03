//
//  ArrayExtensions.swift
//  db
//
//  Created by Joeri van Veen on 24/01/2021.
//

import Foundation

extension Array where Element: Hashable {
    func duplicates() -> Array {
        let groups = Dictionary(grouping: self, by: {$0})
        let duplicateGroups = groups.filter {$1.count > 1}
        let duplicates = Array(duplicateGroups.keys)
        return duplicates
    }
}


extension Sequence where Iterator.Element: Hashable {
    func unique () -> [Iterator.Element] {
        var seen: Set<Iterator.Element> = []
        return filter { seen.insert($0).inserted }
    }
}
