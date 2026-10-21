//
//  RadioFuturaSorsoApp.swift
//  Radio Futura Sorso
//
//  Creato per Radio Futura Sorso - Solo online.
//  Compatibile con iOS 16.0+, iPadOS e Apple CarPlay.
//

import SwiftUI
import AVFoundation

@main
struct RadioFuturaSorsoApp: App {
    @StateObject private var playerManager = RadioPlayerManager.shared

    init() {
        configureAudioSession()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(playerManager)
                .preferredColorScheme(.dark)
        }
    }

    /// Configura l'AVAudioSession per consentire la riproduzione in background
    /// anche a schermo bloccato, con AirPlay e interruzioni gestite (chiamate telefoniche, navigatore).
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, policy: .longFormAudio, options: [.allowBluetooth, .allowBluetoothA2DP, .allowAirPlay])
            try session.setActive(true)
            print("[Radio Futura Sorso] AVAudioSession configurata con successo per audio in background.")
        } catch {
            print("[Radio Futura Sorso] Errore configurazione AVAudioSession: \(error.localizedDescription)")
        }
    }
}
