//
//  Utils.swift
//  db
//
//  Created by Joeri van Veen on 11/01/2021.
//

import Foundation

func printo (_ output: String) {
    print("\u{1B}[1A\u{1B}[K" + output)
}

func measure (_ task: @escaping () throws -> Void) rethrows -> Measure {
    let m = Measure()
    m.start()
    try task()
    m.stop()
    return m
}
