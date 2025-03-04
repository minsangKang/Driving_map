//
//  Color+Extensions.swift
//  Driving_map
//
//  Created by Kang Minsang on 3/4/25.
//

import SwiftUI
import UIKit

extension Color {
    /// HEX 문자열을 `Color`로 변환하는 이니셜라이저
    ///
    /// - Parameter hex: `#RRGGBB` 또는 `#AARRGGBB` 형식의 HEX 문자열
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.hasPrefix("#") ? String(hexSanitized.dropFirst()) : hexSanitized

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let length = hexSanitized.count
        let r, g, b, a: Double

        switch length {
        case 6: // RGB (예: #RRGGBB)
            r = Double((rgb >> 16) & 0xFF) / 255.0
            g = Double((rgb >> 8) & 0xFF) / 255.0
            b = Double(rgb & 0xFF) / 255.0
            a = 1.0
        case 8: // ARGB (예: #AARRGGBB)
            a = Double((rgb >> 24) & 0xFF) / 255.0
            r = Double((rgb >> 16) & 0xFF) / 255.0
            g = Double((rgb >> 8) & 0xFF) / 255.0
            b = Double(rgb & 0xFF) / 255.0
        default:
            return nil
        }

        self.init(red: r, green: g, blue: b, opacity: a)
    }

    /// `Color`를 `#RRGGBB` 또는 `#AARRGGBB` 형식의 HEX 문자열로 변환
    func toHex(withAlpha: Bool = false) -> String? {
        // UIColor 변환
        guard let uiColor = UIColor(self).cgColor.components else { return nil }
        
        let r = Int((uiColor[0] * 255).rounded())
        let g = Int((uiColor[1] * 255).rounded())
        let b = Int((uiColor[2] * 255).rounded())

        if withAlpha, uiColor.count >= 4 {
            let a = Int((uiColor[3] * 255).rounded())
            return String(format: "#%02X%02X%02X%02X", a, r, g, b) // ARGB
        } else {
            return String(format: "#%02X%02X%02X", r, g, b) // RGB
        }
    }

}
