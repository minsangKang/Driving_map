//
//  Driving_mapApp.swift
//  Driving_map
//
//  Created by Kang Minsang on 3/1/25.
//

import SwiftUI
import SwiftData

@main
struct Driving_mapApp: App {
    // SwiftData 모델 컨테이너
    var sharedModelContainer: ModelContainer

    init() {
        do {
            sharedModelContainer = try ModelContainer(for: Pin.self, Path.self)
        } catch {
            fatalError("SwiftData ModelContainer 생성 실패: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(sharedModelContainer) // 모델 컨테이너 주입
        }
    }
}
