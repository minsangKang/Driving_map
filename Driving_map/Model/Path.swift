//
//  Path.swift
//  Driving_map
//
//  Created by Kang Minsang on 3/4/25.
//

import Foundation
import SwiftData

@Model
final class Path: Identifiable {
    @Attribute(.unique) var id: Int  // 고유 ID 설정
    var name: String
    var start: Location
    var end: Location
    var waypoints: [Location] // 시작점, 경유지, 도착점
    var coordinates: [Location] // 실제 경로를 표시하기 위한 데이터
    
    init(id: Int, name: String, start: Location, end: Location, waypoints: [Location], coordinates: [Location]) {
        self.id = id
        self.name = name
        self.start = start
        self.end = end
        self.waypoints = waypoints
        self.coordinates = coordinates
    }
}
