//
//  Pin.swift
//  Driving_map
//
//  Created by Kang Minsang on 3/4/25.
//

import Foundation
import SwiftData

@Model
final class Pin: CustomStringConvertible {
    @Attribute(.unique) var id: Int  // 고유 ID 설정
    var name: String
    var location: Location
    var color: String
    
    init(id: Int, name: String, location: Location, color: String) {
        self.id = id
        self.name = name
        self.location = location
        self.color = color
    }
    
    var description: String {
        return """
        Pin {
            id: \(id)
            name: \(name)
            location: \(location)
            color: \(color)
        }
        """
    }
}
