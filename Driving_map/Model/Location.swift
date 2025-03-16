//
//  Location.swift
//  Driving_map
//
//  Created by Kang Minsang on 3/4/25.
//

import Foundation
import CoreLocation
import SwiftData

@Model
final class Location: CustomStringConvertible {
    var latitude: Double
    var longitude: Double
    var createdAt: Date?
    
    init(latitude: Double, longitude: Double, createdAt: Date? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = createdAt ?? Date()
    }
    
    /// CLLocation 좌표를 `Location`으로 변환하는 이니셜라이저
    convenience init(coordinate: CLLocationCoordinate2D) {
        self.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
    
    /// `Location`을 CLLocationCoordinate2D로 변환
    func toCLLocationCoordinate2D() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var description: String {
        return """
        Location { (\(latitude), \(longitude)), \(createdAt ?? .distantPast) }
        """
    }
}
