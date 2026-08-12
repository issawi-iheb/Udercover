//
//  Item.swift
//  undercover
//
//  Created by Iheb on 12/08/2026.
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
