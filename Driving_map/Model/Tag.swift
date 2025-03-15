//
//  Tag.swift
//  Driving_map
//
//  Created by Kang Minsang on 3/4/25.
//

import Foundation
import SwiftData

@Model
final class Tag {
    @Attribute(.unique) var id: Int  // 고유 ID 설정
    var name: String
    var icon: String
    var color: String

    init(id: Int, name: String, icon: String, color: String) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
    }
}
