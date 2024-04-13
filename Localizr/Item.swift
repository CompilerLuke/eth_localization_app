//
//  Item.swift
//  Localizr
//
//  Created by Antonella Calvia on 13/04/2024.
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
