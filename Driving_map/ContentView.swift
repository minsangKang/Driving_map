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
    let iconName: String
    let iconColor: Color
}

struct ContentView: View {
    @State private var pins: [Pin] = [
        .init(name: "사당역", coordinate: .사당역, iconName: "tram.circle.fill", iconColor: .pink),
        .init(name: "관악산", coordinate: .관악산, iconName: "mountain.2.circle.fill", iconColor: .green),
        .init(name: "북악스카이웨이", coordinate: .북악스카이웨이, iconName: "star.circle.fill", iconColor: .orange)
    ]

    var body: some View {
        Map {
            ForEach(pins, id: \.name) { pin in
                Annotation(pin.name, coordinate: pin.coordinate) {
                    Image(systemName: pin.iconName)
                        .padding(4)
                        .foregroundStyle(.white)
                        .background(pin.iconColor)
                        .clipShape(Circle())
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .edgesIgnoringSafeArea(.all) // 전체 화면 적용
    }
}

extension CLLocationCoordinate2D {
    static let 사당역 = CLLocationCoordinate2D(latitude: 37.4767975, longitude: 126.9816679)
    static let 관악산 = CLLocationCoordinate2D(latitude: 37.4429385, longitude: 126.9610024)
    static let 북악스카이웨이 = CLLocationCoordinate2D(latitude: 37.6015529, longitude: 126.9806646)
}

#Preview {
    ContentView()
}
