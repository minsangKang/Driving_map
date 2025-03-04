//
//  Path.swift
//  Driving_map
//
//  Created by Kang Minsang on 3/4/25.
//

import Foundation

struct Path: Equatable, Codable, Identifiable {
    let id: Int
    let name: String
    let start: Location
    let end: Location
    let waypoints: [Location] // 시작점, 경유지, 도착점
    var coordinates: [Location] // 실제 경로를 표시하기 위한 데이터
    
    static func == (lhs: Path, rhs: Path) -> Bool {
        return lhs.id == rhs.id
    }
}
