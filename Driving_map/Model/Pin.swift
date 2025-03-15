//
//  Pin.swift
//  Driving_map
//
//  Created by Kang Minsang on 3/4/25.
//

import Foundation
import SwiftData

@Model
final class Pin {
    @Attribute(.unique) var id: Int  // 고유 ID 설정
    var name: String
    var location: Location
    var tag: Tag
    
    init(id: Int, name: String, location: Location, tag: Tag) {
        self.id = id
        self.name = name
        self.location = location
        self.tag = tag
    }
}
