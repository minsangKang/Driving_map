//
//  MapModel.swift
//  Driving_map
//
//  Created by Kang Minsang on 3/3/25.
//

import Foundation
import CoreLocation

@MainActor
protocol MapModel: AnyObject {
    var isRecording: Bool { get set }
    
    var pathStartLocation: CLLocationCoordinate2D? { get set }
    var pathEndLocation: CLLocationCoordinate2D? { get set }
    
    func toggleRecording() async
}
