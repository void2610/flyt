//
//  Item.swift
//  my-first-app
//
//  Created by Izumi Shuya on 2025/10/21.
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
