//
//  Tag.swift
//  Driving_map
//
//  Created by Kang Minsang on 3/4/25.
//

import Foundation

struct Tag: Equatable, Codable {
    let id: Int
    let name: String
    let icon: String
    let color: String
    
    static func == (lhs: Tag, rhs: Tag) -> Bool {
        return lhs.id == rhs.id
    }
}
