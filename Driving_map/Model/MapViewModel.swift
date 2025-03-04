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
    
    var pins: [Pin] = []
    var paths: [Path] = []
    var isRecording: Bool = false
    var recordingPath: [Location]?
    
    private var pinId: Int = 4
    private var pathId: Int = 2
    
    var locationManager: LocationManager
    
    init() {
        locationManager = LocationManager()
    }
    
    // MARK: - 경로 캡쳐
    
    func loadPins() async {
        pins = [
            .init(id: 1, name: "사당역", location: .사당역, tag: .전철역),
            .init(id: 2, name: "관악산", location: .관악산, tag: .산),
            .init(id: 3, name: "북악스카이웨이", location: .북악스카이웨이, tag: .즐겨찾기)
        ]
    }
    
    func loadPaths() async {
        paths = [
            .init(id: 1, name: "사당역 -> 북악스카이웨이", start: .사당역, end: .북악스카이웨이, waypoints: [.사당역, .인왕산호랑이동상, .북악스카이웨이], coordinates: [])
        ]
    }
    
    func toggleRecording() async {
        guard let currentLocation = locationManager.userLocation else {
            print("사용자 위치를 가져올 수 없음")
            return
        }
        
        switch isRecording {
        case false:
            let start = Location(coordinate: currentLocation)
            recordingPath = [start]
            pins.append(.init(id: pinId, name: "경로\(pathId) 시작점", location: start, tag: .시작점))
            pinId += 1
            print("출발점 설정")
            
            isRecording = true
        case true:
            self.recordingPath?.append(.init(coordinate: currentLocation))
            print("도착점 설정")
            
            await createNewPath()
            self.recordingPath = nil
            isRecording = false
        }
    }
    
    func createNewPath() async {
        guard let recordingPath,
              let start = recordingPath.first,
              let end = recordingPath.last else { return }
        
        paths.append(.init(id: pathId, name: "경로\(pathId)", start: start, end: end, waypoints: recordingPath, coordinates: []))
        pins.append(.init(id: pinId, name: "경로\(pathId) 종료점", location: end, tag: .종료점))
        
        pathId += 1
        pinId += 1
    }
}
