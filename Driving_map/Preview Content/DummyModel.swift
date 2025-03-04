//
//  DummyModel.swift
//  Driving_map
//
//  Created by Kang Minsang on 3/4/25.
//

import Foundation
import SwiftUI

extension Tag {
    static let 전철역 = Tag(id: 1, name: "전철역", icon: "tram.circle.fill", color: Color.pink.toHex() ?? "")
    static let 산 = Tag(id: 2, name: "산", icon: "mountain.2.circle.fill", color: Color.green.toHex() ?? "")
    static let 즐겨찾기 = Tag(id: 3, name: "즐겨찾기", icon: "star.circle.fill", color: Color.orange.toHex() ?? "")
    static let 시작점 = Tag(id: 4, name: "시작점", icon: "record.circle", color: Color.yellow.toHex() ?? "")
    static let 종료점 = Tag(id: 5, name: "종료점", icon: "flag.pattern.checkered.circle.fill", color: Color.red.toHex() ?? "")
}

extension Location {
    static let 사당역 = Location(latitude: 37.476568, longitude: 126.981649)
    static let 관악산 = Location(latitude: 37.4429385, longitude: 126.9610024)
    static let 북악스카이웨이 = Location(latitude: 37.6015529, longitude: 126.9806646)
    static let 동작대교 = Location(latitude: 37.5104939, longitude: 126.9799999)
    static let 남산3호터널 = Location(latitude: 37.5502869, longitude: 126.9856359)
    static let 인왕산호랑이동상 = Location(latitude: 37.5803138, longitude: 126.9619724)
}
