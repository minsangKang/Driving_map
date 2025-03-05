//
//  MapViewModel.swift
//  Driving_map
//
//  Created by Kang Minsang on 3/2/25.
//

import Foundation
import CoreLocation
import Combine

@Observable
final class MapViewModel: MapModel {
    
    var pins: [Pin] = []
    var paths: [Path] = []
    var isRecording: Bool = false
    var recordingPath: [CLLocationCoordinate2D] = []
    
    private var pinId: Int = 4
    private var pathId: Int = 2
    
    var locationManager: LocationManager
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        locationManager = LocationManager()
        // userLocation 변경 감지
        locationManager.$userLocation
            .compactMap { $0 } // nil 제거
            .sink { [weak self] newLocation in
                if self?.isRecording == true {
                    self?.recordingPath.append(newLocation)
                }
            }
            .store(in: &cancellables)
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
            recordingPath = [currentLocation]
            pins.append(.init(id: pinId, name: "경로\(pathId) 시작점", location: start, tag: .시작점))
            pinId += 1
            print("출발점 설정")
            
            isRecording = true
        case true:
            self.recordingPath.append(currentLocation)
            print("도착점 설정")
            
            await createNewPath()
            self.recordingPath.removeAll()
            isRecording = false
        }
    }
    
    func createNewPath() async {
        guard let start = recordingPath.first,
              let end = recordingPath.last else { return }
        
        let coordinates: [Location] = recordingPath.map { .init(coordinate: $0) }
        let startLocation = Location(coordinate: start)
        let endLocation = Location(coordinate: end)
        
        paths.append(.init(id: pathId, name: "경로\(pathId)", start: startLocation, end: endLocation, waypoints: [startLocation, endLocation], coordinates: coordinates))
        pins.append(.init(id: pinId, name: "경로\(pathId) 종료점", location: endLocation, tag: .종료점))
        
        pathId += 1
        pinId += 1
    }
}
