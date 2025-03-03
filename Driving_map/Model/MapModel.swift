//
//  MapModel.swift
//  Driving_map
//
//  Created by Kang Minsang on 3/3/25.
//

import Foundation

@MainActor
protocol MapModel: AnyObject {
    var isRecording: Bool { get set }
    
    func toggleRecording() async
}
