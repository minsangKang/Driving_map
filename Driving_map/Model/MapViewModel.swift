//
//  MapViewModel.swift
//  Driving_map
//
//  Created by Kang Minsang on 3/2/25.
//

import Foundation
import SwiftUI

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
    var createPathComplete: Bool = false
    
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
#if DEBUG
            print(pins)
#endif
            await updatePinIdCounters()
        } catch {
            print("핀 로드 실패: \(error)")
        }
    }
    
    func loadPaths() async {
        guard let modelContext = modelContext else { return }
        let descriptor = FetchDescriptor<Path>()
        do {
            paths = try modelContext.fetch(descriptor)
#if DEBUG
            print(paths)
#endif
            await updatePathIdCounters()
        } catch {
            print("경로 로드 실패: \(error)")
        }
    }
    
    /// 임시로 가장 마지막에 생성된 Path 제거 함수
    func removeLastPath() async {
        guard let targetPath = paths.first(where: { $0.id == pathId-1 }),
              let startPin = pins.first(where: { $0.id == pinId-1 }),
              let endPin = pins.first(where: { $0.id == pinId-2 }) else {
            print("제거 대상이 존재하지 않음")
            return
        }
        
        do {
            try await deletePin(startPin)
            try await deletePin(endPin)
            try await deletePath(targetPath)
        } catch {
            print("path 제거 실패: \(error.localizedDescription)")
        }
    }
    
    // MARK: - ID 값 업데이트
    private func updatePinIdCounters() async {
        pinId = (pins.map { $0.id }.max() ?? 0) + 1
    }
    
    private func updatePathIdCounters() async {
        pathId = (paths.map { $0.id }.max() ?? 0) + 1
    }
    
    // MARK: - 데이터 저장
    func savePin(_ pin: Pin) async throws {
        guard let modelContext = modelContext else { return }
        print(pin)
        modelContext.insert(pin)
        do {
            try modelContext.save()
            pins.append(pin)
            await updatePinIdCounters()
        } catch {
            print("핀 저장 실패: \(error)")
        }
    }
    
    func savePath(_ path: Path) async throws {
        guard let modelContext = modelContext else { return }
        modelContext.insert(path)
        do {
            try modelContext.save()
            paths.append(path)
            await updatePathIdCounters()
        } catch {
            print("경로 저장 실패: \(error)")
        }
    }
    
    func deletePin(_ pin: Pin) async throws {
        guard let modelContext = modelContext else { return }
        
        modelContext.delete(pin)  // SwiftData에서 삭제
        do {
            try modelContext.save()  // 변경 사항 저장
            if let index = pins.firstIndex(where: { $0.id == pin.id }) {
                pins.remove(at: index)  // 로컬 배열에서도 삭제
            }
            await updatePinIdCounters()
            print("핀(\(pin.id)) 삭제 성공")
        } catch {
            print("핀 삭제 실패: \(error)")
        }
    }
    
    func deletePath(_ path: Path) async throws {
        guard let modelContext = modelContext else { return }
        
        modelContext.delete(path)  // SwiftData에서 삭제
        do {
            try modelContext.save()  // 변경 사항 저장
            if let index = paths.firstIndex(where: { $0.id == path.id }) {
                paths.remove(at: index)  // 로컬 배열에서도 삭제
            }
            await updatePathIdCounters()
            print("경로(\(path.id)) 삭제 성공")
        } catch {
            print("경로 삭제 실패: \(error)")
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
            
            let newPin = Pin(id: pinId, name: "경로\(pathId) 시작점", location: start, color: Color.green.toHex() ?? "")
            do {
                // savePin 함수에서 오류가 발생하면 catch 블록으로 이동합니다.
                try await savePin(newPin)
                print("출발점 설정")
                isRecording = true
            } catch {
                // savePin이 실패할 경우 오류 메시지를 출력하고, isRecording을 false로 유지합니다.
                print("출발점 설정 실패: \(error.localizedDescription)")
            }
            
        case true:
            recordingPath.append(currentLocation)
            print("도착점 설정")
            
            do {
                try await createNewPath()
                isRecording = false
                createPathComplete = true
            } catch {
                print("도착점 설정 실패: \(error.localizedDescription)")
            }
        }
    }
    
    func saveSnapshot() async {
        recordingPath.removeAll()
        createPathComplete = false
    }
    
    func createNewPath() async throws {
        guard let start = recordingPath.first,
              let end = recordingPath.last else { return }
        
        let coordinates = recordingPath.map { Location(coordinate: $0) }
        let startLocation = Location(coordinate: start)
        let endLocation = Location(coordinate: end)
        
        let newPath = Path(id: pathId, name: "경로\(pathId)", start: startLocation, end: endLocation, waypoints: [startLocation, endLocation], coordinates: coordinates)
        let newPin = Pin(id: pinId, name: "경로\(pathId) 종료점", location: endLocation, color: Color.red.toHex() ?? "")
        
        do {
            try await savePath(newPath)
            try await savePin(newPin)
        } catch {
            print("path 생성 실패: \(error.localizedDescription)")
        }
    }
}
