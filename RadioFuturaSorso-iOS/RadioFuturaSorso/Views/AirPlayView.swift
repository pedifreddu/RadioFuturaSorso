//
//  AirPlayView.swift
//  Radio Futura Sorso
//
//  Wrapper SwiftUI per il controllo nativo AVRoutePickerView (AirPlay & Bluetooth).
//

import SwiftUI
import AVKit

struct AirPlayView: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let routePickerView = AVRoutePickerView()
        routePickerView.backgroundColor = .clear
        routePickerView.tintColor = .white
        routePickerView.activeTintColor = UIColor(red: 0.18, green: 0.8, blue: 0.44, alpha: 1.0)
        routePickerView.prioritizesVideoDevices = false
        return routePickerView
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}
