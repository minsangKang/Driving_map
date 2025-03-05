//
//  ContentView.swift
//  Driving_map
//
//  Created by Kang Minsang on 3/1/25.
//

import SwiftUI

import MapKit
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var mapModel = MapViewModel()

    var body: some View {
        ZStack {
            Map {
                // 사용자 위치 표시
                if locationManager.userLocation != nil {
                    UserAnnotation()
                }

                // 핀 표시
                ForEach(mapModel.pins, id: \.id) { pin in
                    let _ = print("pin[\(pin.name)] 표시")
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
                    let _ = print("실시간 경로 업데이트: \(mapModel.recordingPath.count) 개")
                    MapPolyline(coordinates: mapModel.recordingPath)
                        .stroke(Color.yellow, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                }
                
                // 저장된 경로 표시
                ForEach(mapModel.paths.indices, id: \.self) { index in
                    if !mapModel.paths[index].coordinates.isEmpty {
                        let _ = print("path[\(index)] 표시")
                        MapPolyline(coordinates: Array(mapModel.paths[index].coordinates.map { $0.toCLLocationCoordinate2D() }))
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round))
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .onAppear {
                Task {
                    // 경로 로드
                    await mapModel.loadPins()
                    await mapModel.loadPaths()
                }
            }
            .onChange(of: mapModel.paths) { oldValue, newValue in
                Task {
                    // 경로 계산
                    await updatePaths()
                }
            }

            // 버튼 추가
            VStack {
                Spacer()
                CaptureButton(mapModel: mapModel)
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
            
            print("path[\(mapModel.paths[index].name)] 경로는 \(routeCoordinates.count)개")
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
}
