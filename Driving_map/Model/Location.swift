//
//  Location.swift
//  Driving_map
//
//  Created by Kang Minsang on 3/4/25.
//

import Foundation
import CoreLocation

struct Location: Codable {
    let latitude: Double
    let longitude: Double
}

extension Location {
    /// CLLocation 좌표를 `Location`로 변환하는 이니셜라이저
    init(coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }
    
    /// `Location`을 CLLocation 좌표로 벼환
    func toCLLocationCoordinate2D() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(
            latitude: self.latitude,
            longitude: self.longitude
        )
    }
}
