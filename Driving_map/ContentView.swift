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
import Photos

struct ContentView: View {
    
    @Environment(\.modelContext) private var modelContext
    @StateObject private var locationManager = LocationManager()
    @State private var mapModel = MapViewModel()
    
    @State private var cameraPosition: MapCameraPosition = .automatic // 카메라 위치 관리
    @State private var previousScale: CGFloat = 1.0
    @State private var isFollow = true // 현위치 & 방향 적용 여부
    
    @State private var snapshotImage: UIImage?

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
                            Circle()
                                .stroke(Color(hex: pin.color)!, lineWidth: 8)
                                .fill(Color.secondary)
                                .frame(width: 12, height: 12)
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
                .onChange(of: mapModel.createPathComplete) { _, isComplete in
                    guard isComplete, !mapModel.recordingPath.isEmpty else { return }
                    Task {
                        await captureMapSnapshot()
                    }
                }
                
                Circle()
                    .strokeBorder(Color.secondary, lineWidth: 3)
                    .frame(width: min(geometry.size.width, geometry.size.height) - 32)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                // 버튼 추가
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            Task {
                                await mapModel.removeLastPath()
                            }
                        } label: {
                            Image(systemName: "trash.square")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 36, height: 36)
                                .tint(Color.secondary)
                        }
                        .padding(8)
                    }
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

    func captureMapSnapshot() async {
        let coordinates = mapModel.recordingPath
        let imageSize = CGSize(width: 512, height: 512)
        let lineColor = UIColor.white
        let lineWidth: CGFloat = 6.0
        let padding: CGFloat = 16.0 // 🔥 여백 추가 (경로가 이미지 밖으로 나가는 문제 해결)

        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0)
        let context = UIGraphicsGetCurrentContext()
        
        context?.setStrokeColor(lineColor.cgColor)
        context?.setLineWidth(lineWidth)
        context?.setLineJoin(.round)
        context?.setLineCap(.round)

        guard let minLat = coordinates.map({ $0.latitude }).min(),
              let maxLat = coordinates.map({ $0.latitude }).max(),
              let minLon = coordinates.map({ $0.longitude }).min(),
              let maxLon = coordinates.map({ $0.longitude }).max() else {
            return
        }

        let latRange = maxLat - minLat
        let lonRange = maxLon - minLon

        // ✅ 가로/세로 중 더 긴 쪽을 기준으로 스케일 조정
        let scaleX = (imageSize.width - 2 * padding) / lonRange
        let scaleY = (imageSize.height - 2 * padding) / latRange
        let scale = min(scaleX, scaleY) // 🔥 비율 유지하면서 이미지 내부에 맞추기

        func normalize(_ coordinate: CLLocationCoordinate2D) -> CGPoint {
            let x = (coordinate.longitude - minLon) * scale + padding
            let y = (maxLat - coordinate.latitude) * scale + padding
            return CGPoint(x: x, y: y)
        }

        let pathPoints = coordinates.map { normalize($0) }

        // 🔥 경로의 최소/최대 좌표 계산 후 중앙 정렬
        let minX = pathPoints.map { $0.x }.min() ?? 0
        let minY = pathPoints.map { $0.y }.min() ?? 0
        let maxX = pathPoints.map { $0.x }.max() ?? 0
        let maxY = pathPoints.map { $0.y }.max() ?? 0

        let offsetX = (imageSize.width - (maxX - minX)) / 2 - minX
        let offsetY = (imageSize.height - (maxY - minY)) / 2 - minY

        for (index, point) in pathPoints.enumerated() {
            let adjustedPoint = CGPoint(x: point.x + offsetX, y: point.y + offsetY)
            if index == 0 {
                context?.move(to: adjustedPoint)
            } else {
                context?.addLine(to: adjustedPoint)
            }
        }

        context?.strokePath()

        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        Task {
            await mapModel.saveSnapshot()
            snapshotImage = finalImage
            if let image = finalImage {
                saveImageToGallery(image)
            }
        }
    }
    
    func saveImageToGallery(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                if let pngData = image.pngData() {
                    let filename = FileManager.default.temporaryDirectory.appendingPathComponent("polyline_snapshot.png")
                    do {
                        try pngData.write(to: filename)
                        PHPhotoLibrary.shared().performChanges({
                            let request = PHAssetCreationRequest.forAsset()
                            request.addResource(with: .photo, fileURL: filename, options: nil)
                        }) { success, error in
                            if success {
                                print("✅ PNG 이미지가 갤러리에 저장됨!")
                            } else {
                                print("❌ 이미지 저장 실패: \(error?.localizedDescription ?? "알 수 없는 오류")")
                            }
                        }
                    } catch {
                        print("❌ 파일 저장 실패: \(error.localizedDescription)")
                    }
                }
            } else {
                print("❌ 갤러리 접근 권한이 필요합니다.")
            }
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
