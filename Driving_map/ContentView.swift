//
//  ContentView.swift
//  Driving_map
//
//  Created by Kang Minsang on 3/1/25.
//

import SwiftUI
import MapKit
import CoreLocation
import SwiftData

struct ContentView: View {
    
    @Environment(\.modelContext) private var modelContext
    @StateObject private var locationManager = LocationManager()
    @State private var mapModel = MapViewModel()
    
    @State private var cameraPosition: MapCameraPosition = .automatic // 카메라 위치 관리
    @State private var previousScale: CGFloat = 1.0
    @State private var isFollow = true // 현위치 & 방향 적용 여부

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Map(position: $cameraPosition) {
                    // 사용자 위치 표시
                    if locationManager.userLocation != nil {
                        UserAnnotation()
                    }
                    
                    // 핀 표시
                    ForEach(mapModel.pins, id: \.id) { pin in
                        Annotation(pin.name, coordinate: pin.location.toCLLocationCoordinate2D()) {
                            if pin.tag == .시작점 || pin.tag == .종료점 {
                                Circle()
                                    .stroke(Color(hex: pin.tag.color)!, lineWidth: 8)
                                    .fill(Color.secondary)
                                    .frame(width: 12, height: 12)
                            } else {
                                Image(systemName: pin.tag.icon)
                                    .padding(4)
                                    .foregroundStyle(.secondary)
                                    .background(Color(hex: pin.tag.color))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    
                    // 기록 중인 실시간 경로 표시
                    if !mapModel.recordingPath.isEmpty {
                        MapPolyline(coordinates: mapModel.recordingPath)
                            .stroke(Color.yellow, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                    }
                    
                    // 저장된 경로 표시
                    ForEach(mapModel.paths.indices, id: \.self) { index in
                        if !mapModel.paths[index].coordinates.isEmpty {
                            MapPolyline(coordinates: Array(mapModel.paths[index].coordinates.sorted { $0.createdAt < $1.createdAt }.map { $0.toCLLocationCoordinate2D() }))
                                .stroke(Color.orange, style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round))
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }
                .onChange(of: locationManager.userLocation) { _, firstLocation in
                    guard isFollow, let heading = locationManager.heading, let location = firstLocation else { return }
                    
                    let coordinate = location.coordinate
                    cameraPosition = .camera(
                        MapCamera(
                            centerCoordinate: coordinate,  // 사용자 위치
                            distance: 1000,  // 고도
                            heading: heading, // 방향 반영
                            pitch: 0 // 3D 각도
                        )
                    )
                    
                    isFollow = false
                }
                
                Circle()
                    .strokeBorder(Color.secondary, lineWidth: 3)
                    .frame(width: min(geometry.size.width, geometry.size.height) - 32)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                // 버튼 추가
                VStack {
                    Spacer()
                    CaptureButton(mapModel: mapModel)
                }
            }
            .onAppear {
                UIApplication.shared.isIdleTimerDisabled = true // 화면 꺼짐 방지 설정
                mapModel.modelContext = modelContext
                Task {
                    // 경로 로드
                    await mapModel.loadPins()
                    await mapModel.loadPaths()
                }
            }
            .onDisappear {
                UIApplication.shared.isIdleTimerDisabled = false // 화면 꺼짐 방지 제거
            }
        }
    }
    
    /// MKDirections를 이용해 실제 도로 기반 경로를 계산하는 함수
    func updatePaths() async {
        for index in mapModel.paths.indices where mapModel.paths[index].coordinates.isEmpty {
            var routeCoordinates: [CLLocationCoordinate2D] = []
            let waypoints = mapModel.paths[index].waypoints
            
            for i in 0..<waypoints.count - 1 {
                let start = MKMapItem(placemark: MKPlacemark(coordinate: waypoints[i].toCLLocationCoordinate2D()))
                let end = MKMapItem(placemark: MKPlacemark(coordinate: waypoints[i + 1].toCLLocationCoordinate2D()))
                
                let request = MKDirections.Request()
                request.source = start
                request.destination = end
                request.transportType = .automobile // 자동차 경로
                request.departureDate = Date() // 현재 시간
                request.requestsAlternateRoutes = true
                
                let directions = MKDirections(request: request)
                do {
                    let response = try await directions.calculate()
                    if let route = response.routes.sorted(by: { $0.expectedTravelTime < $1.expectedTravelTime }).first {
                        routeCoordinates.append(contentsOf: route.polyline.coordinates)
                    }
                } catch {
                    print("경로 계산 오류: \(error.localizedDescription)")
                }
            }
            
            mapModel.paths[index].coordinates = routeCoordinates.map { .init(coordinate: $0) }
        }
    }
}

// MKPolyline → CLLocationCoordinate2D 배열 변환 확장
extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
}

#Preview {
    ContentView()
        .modelContainer(try! ModelContainer(for: Pin.self, Path.self))
}
