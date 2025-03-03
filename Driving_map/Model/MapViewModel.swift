//
//  MapViewModel.swift
//  Driving_map
//
//  Created by Kang Minsang on 3/2/25.
//

import Foundation
import CoreLocation

@Observable
final class MapViewModel: MapModel {
    
    var paths: [Path] = []
    var pathCoordinates: [[CLLocationCoordinate2D]] = []
    var isRecording: Bool = false
    
    var pathStartLocation: CLLocationCoordinate2D?
    var pathEndLocation: CLLocationCoordinate2D?
    var locationManager: LocationManager
    
    init() {
        locationManager = LocationManager()
    }
    
    // MARK: - 경로 캡쳐
    
    func loadPaths() async {
        paths = [.init(name: "사당역 -> 북악스카이웨이", waypoints: [.사당역, .인왕산호랑이동상, .북악스카이웨이], coordinates: [])]
    }
    
    func toggleRecording() async {
        guard let currentLocation = locationManager.userLocation else {
            print("사용자 위치를 가져올 수 없음")
            return
        }
        
        switch isRecording {
        case false:
            pathStartLocation = currentLocation
            pathEndLocation = nil
            print("출발점 설정: \(currentLocation)")
            
            isRecording = true
        case true:
            pathEndLocation = currentLocation
            print("도착점 설정: \(currentLocation)")
            
            await createNewPath()
            isRecording = false
        }
    }
    
    func createNewPath() async {
        guard let start = pathStartLocation, let end = pathEndLocation else {
            print("출발점, 도착점이 설정되지 않았습니다.")
            return
        }
        
        paths.append(.init(name: UUID().uuidString, waypoints: [start, end], coordinates: []))
    }
}
