//
//  MapViewModel.swift
//  Driving_map
//
//  Created by Kang Minsang on 3/2/25.
//

import Foundation

@Observable
final class MapViewModel: MapModel {
    
    var isRecording: Bool = false
    
    // MARK: - 경로 캡쳐
    
    func toggleRecording() async {
        switch isRecording {
            case true:
            isRecording = false
        default:
            isRecording = true
        }
    }
}
