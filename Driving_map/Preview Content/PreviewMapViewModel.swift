//
//  PreviewMapViewModel.swift
//  Driving_map
//
//  Created by Kang Minsang on 3/3/25.
//

import Foundation
import CoreLocation

@Observable
final class PreviewMapViewModel: MapModel {
    
    var isRecording: Bool = false
    var pathStartLocation: CLLocationCoordinate2D?
    var pathEndLocation: CLLocationCoordinate2D?
    
    // MARK: - 경로 캡쳐
    
    func toggleRecording() async {
        print("toggleRecording")
    }
}
