//
//  ContentView.swift
//  Driving_map
//
//  Created by Kang Minsang on 3/1/25.
//

import SwiftUI
import MapKit

struct Pin {
    let name: String
    let coordinate: CLLocationCoordinate2D
    let icon: String
    let color: Color
}

struct Path {
    let name: String
    let waypoints: [CLLocationCoordinate2D] // 시작점, 경유지, 도착점
    var coordinates: [CLLocationCoordinate2D] // 실제 도로 경로를 저장
}

struct ContentView: View {
    @State private var pins: [Pin] = [
        .init(name: "사당역", coordinate: .사당역, icon: "tram.circle.fill", color: .pink),
        .init(name: "관악산", coordinate: .관악산, icon: "mountain.2.circle.fill", color: .green),
        .init(name: "북악스카이웨이", coordinate: .북악스카이웨이, icon: "star.circle.fill", color: .orange)
    ]
    
    @State private var paths: [Path] = [
        .init(name: "사당역 -> 북악스카이웨이", waypoints: [.사당역, .인왕산호랑이동상, .북악스카이웨이], coordinates: [])
    ]

    var body: some View {
        Map {
            // 핀 표시
            ForEach(pins, id: \.name) { pin in
                Annotation(pin.name, coordinate: pin.coordinate) {
                    Image(systemName: pin.icon)
                        .padding(4)
                        .foregroundStyle(.white)
                        .background(pin.color)
                        .clipShape(Circle())
                }
            }
            
            // 도로 기반 경로 표시
            ForEach(paths, id: \.name) { path in
                if !path.coordinates.isEmpty {
                    MapPolyline(coordinates: path.coordinates)
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .edgesIgnoringSafeArea(.all) // 전체 화면 적용
        .task {
            await updatePaths()
        }
    }
    
    /// MKDirections를 이용해 실제 도로 기반 경로를 계산하는 함수
    func updatePaths() async {
        for index in paths.indices {
            var routeCoordinates: [CLLocationCoordinate2D] = []
            let waypoints = paths[index].waypoints
            
            for i in 0..<waypoints.count - 1 {
                let start = MKMapItem(placemark: MKPlacemark(coordinate: waypoints[i]))
                let end = MKMapItem(placemark: MKPlacemark(coordinate: waypoints[i + 1]))
                
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
            
            paths[index].coordinates = routeCoordinates
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

// 좌표 확장
extension CLLocationCoordinate2D {
    static let 사당역 = CLLocationCoordinate2D(latitude: 37.4767975, longitude: 126.9816679)
    static let 관악산 = CLLocationCoordinate2D(latitude: 37.4429385, longitude: 126.9610024)
    static let 북악스카이웨이 = CLLocationCoordinate2D(latitude: 37.6015529, longitude: 126.9806646)
    static let 동작대교 = CLLocationCoordinate2D(latitude: 37.5104939, longitude: 126.9799999)
    static let 남산3호터널 = CLLocationCoordinate2D(latitude: 37.5502869, longitude: 126.9856359)
    static let 인왕산호랑이동상 = CLLocationCoordinate2D(latitude: 37.5803138, longitude: 126.9619724)
}

#Preview {
    ContentView()
}
