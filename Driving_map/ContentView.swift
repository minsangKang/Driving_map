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
    @State private var distance: Double = 800
    @State private var previousScale: CGFloat = 1.0
    @State private var isFollow = true // 현위치 & 방향 적용 여부

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Map(position: $cameraPosition, interactionModes: []) {
                    // 사용자 위치 표시
                    if locationManager.userLocation != nil {
                        UserAnnotation()
                    }
                    
                    // 핀 표시
                    ForEach(mapModel.pins, id: \.id) { pin in
                        Annotation(pin.name, coordinate: pin.location.toCLLocationCoordinate2D()) {
                            Image(systemName: pin.tag.icon)
                                .padding(4)
                                .foregroundStyle(.white)
                                .background(Color(hex: pin.tag.color))
                                .clipShape(Circle())
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
                            MapPolyline(coordinates: Array(mapModel.paths[index].coordinates.map { $0.toCLLocationCoordinate2D() }))
                                .stroke(Color.blue, style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round))
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                //            .mapControls {
                //                MapUserLocationButton()
                //                MapCompass()
                //                MapScaleView()
                //            }
                .onChange(of: locationManager.heading) { _, newHeading in
                    guard let heading = newHeading, let location = locationManager.userLocation else { return }
                    
                    // 사용자 위치와 heading이 모두 있을 때만 카메라 업데이트
                    if isFollow {
                        let coordinate = location.coordinate
                        cameraPosition = .camera(
                            MapCamera(
                                centerCoordinate: coordinate,  // 사용자 위치
                                distance: distance,  // 고도
                                heading: heading, // 방향 반영
                                pitch: 60 // 3D 각도
                            )
                        )
                    }
                }
                
                Circle()
                    .strokeBorder(Color.white, lineWidth: 2)
                    .frame(width: min(geometry.size.width, geometry.size.height) - 32)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                HStack {
                    Spacer()
                    Text("\(Int(distance))m")
                        .font(.subheadline)
                        .tint(Color.white)
                    Spacer()
                }
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2 + (min(geometry.size.width, geometry.size.height) - 32) / 2 - 16)
                
                // 버튼 추가
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 16) {
                            Button {
                                distance -= 100
                            } label: {
                                Image(systemName: "plus.square.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 36, height: 36)
                                    .tint(.secondary)
                            }
                            Button {
                                distance += 100
                            } label: {
                                Image(systemName: "minus.square.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 36, height: 36)
                                    .tint(.secondary)
                            }
                            .frame(width: 42, height: 42)
                        }
                    }
                    .padding(8)
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
