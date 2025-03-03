//
//  CaptureButton.swift
//  Driving_map
//
//  Created by Kang Minsang on 3/2/25.
//

import SwiftUI

@MainActor
struct CaptureButton<MapViewModel: MapModel>: View {
    
    @State var mapModel: MapViewModel
    @State var isRecording = false
    
    private let mainButtonDimension: CGFloat = 68
    
    var body: some View {
        PathCaptureButton(isRecording: $isRecording) { _ in
            Task {
                await mapModel.toggleRecording()
            }
        }
        .aspectRatio(1.0, contentMode: .fit)
        .frame(width: mainButtonDimension)
        .onChange(of: mapModel.isRecording) { _, newValue in
            withAnimation(.easeInOut(duration: 0.25)) {
                isRecording = newValue
            }
        }
    }
}

private struct PathCaptureButton: View {
    
    private let action: (Bool) -> Void
    private let lineWidth = CGFloat(4.0)
    
    @Binding private var isRecording: Bool
    
    init(isRecording: Binding<Bool>, action: @escaping (Bool) -> Void) {
        _isRecording = isRecording
        self.action = action
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: lineWidth)
                .foregroundColor(Color.white)
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isRecording.toggle()
                }
                action(isRecording)
            } label: {
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: geometry.size.width / (isRecording ? 4.0 : 2.0))
                        .inset(by: lineWidth * 1.2)
                        .fill(.red)
                        .scaleEffect(isRecording ? 0.6 : 1.0)
                }
            }
            .buttonStyle(NoFadeButtonStyle())
        }
    }
    
    struct NoFadeButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
        }
    }
}

#Preview("Video") {
    @Previewable @State var isRecording = false
    CaptureButton(mapModel: PreviewMapViewModel())
}
