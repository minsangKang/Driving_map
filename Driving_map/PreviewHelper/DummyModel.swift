//
//  DummyModel.swift
//  Driving_map
//
//  Created by Kang Minsang on 3/4/25.
//

import Foundation
import SwiftUI

extension Tag {
    static let 시작점 = Tag(id: 4, name: "시작점", icon: "record.circle", color: Color.green.toHex() ?? "")
    static let 종료점 = Tag(id: 5, name: "종료점", icon: "flag.pattern.checkered.circle.fill", color: Color.red.toHex() ?? "")
}
