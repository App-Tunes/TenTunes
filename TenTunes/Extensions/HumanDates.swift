//
//  HumanDates.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 28.11.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class HumanDates {
    static var formatters: [DateFormatter] = [
        DateFormatter(format: "yyyy-MM-dd"),
        DateFormatter(format: "yyyy-MM"),
        DateFormatter(format: "yyyy"),
        DateFormatter(format: "dd.MM.yyyy"),
        DateFormatter(format: "MM/dd/yyyy"),
        ]
    
    static func string(from date: Date) -> String {
        guard Calendar.current.component(.day, from: date) == 1 else {
            return formatters.first!.string(from: date)
        }
        
        guard Calendar.current.component(.month, from: date) == 1 else {
            return formatters[1].string(from: date)
        }
        
        return formatters[2].string(from: date)
    }

    static func date(from string: String) -> Date? {
        return formatters.compactMap {
            $0.date(from: string)
        }.first
    }
}
