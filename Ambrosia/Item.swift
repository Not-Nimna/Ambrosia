//
//  Item.swift
//  Ambrosia
//
//  Created by Nimna Wijedasa on 2026-11-21.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
