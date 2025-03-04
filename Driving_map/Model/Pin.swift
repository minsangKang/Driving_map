//
//  Pin.swift
//  Driving_map
//
//  Created by Kang Minsang on 3/4/25.
//

import Foundation

struct Pin: Equatable, Codable {
    let id: Int
    let name: String
    let location: Location
    let tag: Tag
    
    static func == (lhs: Pin, rhs: Pin) -> Bool {
        return lhs.id == rhs.id
    }
}
