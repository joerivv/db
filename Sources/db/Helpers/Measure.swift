//
//  Measure.swift
//  db
//
//  Created by Joeri van Veen on 10/01/2021.
//

import Foundation

class Measure {
    
    private var begin: DispatchTime = DispatchTime.now()
    private var end: DispatchTime = DispatchTime.now()
    
    func start () {
        begin = DispatchTime.now()
    }
    
    func stop () {
        end = DispatchTime.now()
    }
    
    var elapsedMilliseconds: UInt64 {
        return end.uptimeNanoseconds - begin.uptimeNanoseconds
    }
    
    var elapsedTime: String {
        let ms = elapsedMilliseconds
        let nanosecondsInSecond = UInt64(1e9)
        let millisecondsInSecond = UInt64(1e6)
        
        if ms < nanosecondsInSecond {
            return "\(Double(round(Double(ms) / Double(millisecondsInSecond) * 10)) / 10)ms"
        }
        
        let formatter = DateComponentsFormatter()
        
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        
        return formatter.string(from: Double(elapsedMilliseconds) / Double(nanosecondsInSecond)) ?? "Unable to measure"
    }
    
}
