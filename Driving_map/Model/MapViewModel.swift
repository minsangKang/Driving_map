//
//  MapViewModel.swift
//  Driving_map
//
//  Created by Kang Minsang on 3/2/25.
//

import Foundation
import CoreLocation
import SwiftData
import Combine

@Observable
final class MapViewModel: MapModel {
    @MainActor var modelContext: ModelContext?
    var locationManager: LocationManager
    
    var pins: [Pin] = []
    var paths: [Path] = []
    var isRecording: Bool = false
    var recordingPath: [CLLocationCoordinate2D] = []
    
    private var pinId: Int = 1
    private var pathId: Int = 1
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        locationManager = LocationManager()
        
        // 위치 업데이트 감지
        locationManager.$userLocation
            .compactMap { $0 }
            .map { $0.coordinate }
            .sink { [weak self] newLocation in
                if self?.isRecording == true {
                    self?.recordingPath.append(newLocation)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - SwiftData에서 데이터 불러오기
    
    func loadPins() async {
        guard let modelContext = modelContext else { return }
        let descriptor = FetchDescriptor<Pin>()
        do {
            pins = try modelContext.fetch(descriptor)
            updatePinIdCounters()
        } catch {
            print("핀 로드 실패: \(error)")
        }
    }
    
    func loadPaths() async {
        guard let modelContext = modelContext else { return }
        let descriptor = FetchDescriptor<Path>(sortBy: [SortDescriptor(\.createdAt, order: .forward)])
        do {
            paths = try modelContext.fetch(descriptor)
            print(paths)
            updatePathIdCounters()
        } catch {
            print("경로 로드 실패: \(error)")
        }
    }
    
    // MARK: - ID 값 업데이트
    private func updatePinIdCounters() {
        pinId = (pins.map { $0.id }.max() ?? 0) + 1
    }
    
    private func updatePathIdCounters() {
        pathId = (paths.map { $0.id }.max() ?? 0) + 1
    }
    
    // MARK: - 데이터 저장
    func savePin(_ pin: Pin) {
        guard let modelContext = modelContext else { return }
        modelContext.insert(pin)
        do {
            try modelContext.save()
            pins.append(pin)
            updatePinIdCounters()
        } catch {
            print("핀 저장 실패: \(error)")
        }
    }
    
    func savePath(_ path: Path) {
        guard let modelContext = modelContext else { return }
        modelContext.insert(path)
        do {
            try modelContext.save()
            paths.append(path)
            updatePathIdCounters()
        } catch {
            print("경로 저장 실패: \(error)")
        }
    }
    
    // MARK: - 경로 캡처
    func toggleRecording() async {
        guard let currentLocation = locationManager.userLocation?.coordinate else {
            print("사용자 위치를 가져올 수 없음")
            return
        }
        
        switch isRecording {
        case false:
            let start = Location(coordinate: currentLocation)
            recordingPath = [currentLocation]
            
            let newPin = Pin(id: pinId, name: "경로\(pathId) 시작점", location: start, tag: .시작점)
            savePin(newPin)
            
            print("출발점 설정")
            isRecording = true
            
        case true:
            recordingPath.append(currentLocation)
            print("도착점 설정")
            
            await createNewPath()
            recordingPath.removeAll()
            isRecording = false
        }
    }
    
    func createNewPath() async {
        guard let start = recordingPath.first,
              let end = recordingPath.last else { return }
        
        let coordinates = recordingPath.map { Location(coordinate: $0) }
        let startLocation = Location(coordinate: start)
        let endLocation = Location(coordinate: end)
        
        let newPath = Path(id: pathId, name: "경로\(pathId)", start: startLocation, end: endLocation, waypoints: [startLocation, endLocation], coordinates: coordinates)
        let newPin = Pin(id: pinId, name: "경로\(pathId) 종료점", location: endLocation, tag: .종료점)
        
        savePath(newPath)
        savePin(newPin)
    }
}
