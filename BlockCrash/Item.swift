//
//  Item.swift
//  BlockCrash
//
//  Created by Kerem Türközü on 28.04.2025.
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
