//
//  ContentView.swift
//  Radio Futura Sorso
//
//  Interfaccia moderna e professionale in stile Apple per iPhone e iPad.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @EnvironmentObject var playerManager: RadioPlayerManager
    @State private var showingInfoSheet = false
    @State private var showingSleepTimerSheet = false
    @State private var sleepTimerRemaining: Int? = nil
    @State private var sleepTimer: Timer? = nil

    // Numero WhatsApp ufficiale della radio
    let whatsAppPhone = "+39 379 104 5300" // Numero ufficiale Radio Futura Sorso

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Sfondo dinamico con sfocatura basata sull'artwork della canzone
                ambientBackground

                // Contenuto principale
                VStack(spacing: 24) {
                    headerView

                    Spacer(minLength: 10)

                    // Copertina Album con ombra ed effetto elevazione
                    artworkView(size: min(geometry.size.width - 64, geometry.size.height * 0.42))

                    // Metadati Canzone e Artista in onda
                    metadataView

                    // Equalizzatore animato quando in riproduzione
                    if playerManager.isPlaying {
                        EqualizerAnimationView()
                            .frame(height: 28)
                            .transition(.opacity)
                    }

                    Spacer(minLength: 10)

                    // Controlli Principali (Play / Stop / AirPlay)
                    controlsView

                    // Barra Azioni Inferiore (WhatsApp, Timer Spegnimento, Info Radio)
                    bottomBarView
                }
                .padding(.horizontal, 24)
                .padding(.top, geometry.safeAreaInsets.top > 0 ? 8 : 24)
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showingInfoSheet) {
            RadioInfoView()
        }
        .sheet(isPresented: $showingSleepTimerSheet) {
            SleepTimerView(activeMinutes: $sleepTimerRemaining, onSelect: startSleepTimer, onCancel: cancelSleepTimer)
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("RADIO FUTURA SORSO")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .tracking(1.2)

                HStack(spacing: 6) {
                    Circle()
                        .fill(playerManager.isPlaying ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                        .scaleEffect(playerManager.isPlaying ? 1.2 : 1.0)
                        .animation(playerManager.isPlaying ? Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default, value: playerManager.isPlaying)

                    Text("Solo online")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))

                    Text("•")
                        .foregroundStyle(.white.opacity(0.4))

                    Text(playerManager.bitrate)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            Spacer()

            // Pulsante AirPlay Nativo
            AirPlayView()
                .frame(width: 38, height: 38)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
        }
    }

    // MARK: - Copertina Album
    private func artworkView(size: CGFloat) -> some View {
        ZStack {
            if let artwork = playerManager.currentArtwork {
                Image(uiImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                // Placeholder elegante con Logo Radio Futura Sorso
                ZStack {
                    LinearGradient(
                        colors: [Color(red: 0.12, green: 0.14, blue: 0.22), Color(red: 0.05, green: 0.06, blue: 0.10)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    VStack(spacing: 12) {
                        Image(systemName: "radio.fill")
                            .font(.system(size: 64, weight: .light))
                            .foregroundStyle(LinearGradient(colors: [.cyan, .blue], startPoint: .top, endPoint: .bottom))

                        Text("RADIO FUTURA SORSO")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.9))

                        Text("Solo online")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 1.2)
        )
        .shadow(color: playerManager.isPlaying ? Color.blue.opacity(0.35) : Color.black.opacity(0.4), radius: 25, x: 0, y: 15)
        .scaleEffect(playerManager.isPlaying ? 1.0 : 0.96)
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: playerManager.isPlaying)
    }

    // MARK: - Metadati Canzone
    private var metadataView: some View {
        VStack(spacing: 6) {
            Text(playerManager.currentSongTitle)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Text(playerManager.currentArtist)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
    }

    // MARK: - Controlli Play / Stop
    private var controlsView: some View {
        HStack(spacing: 36) {
            // Pulsante Stop
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                playerManager.stop()
            }) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 58, height: 58)
                        .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))

                    Image(systemName: "stop.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(playerManager.isPlaying ? .white : .white.opacity(0.35))
                }
            }
            .disabled(!playerManager.isPlaying)

            // Pulsante Play Principale
            Button(action: {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                playerManager.togglePlayStop()
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: playerManager.isPlaying
                                    ? [Color(red: 0.95, green: 0.25, blue: 0.35), Color(red: 0.85, green: 0.15, blue: 0.25)]
                                    : [Color(red: 0.15, green: 0.55, blue: 0.98), Color(red: 0.05, green: 0.40, blue: 0.88)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 86, height: 86)
                        .shadow(color: (playerManager.isPlaying ? Color.red : Color.blue).opacity(0.4), radius: 16, x: 0, y: 8)

                    if playerManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.4)
                    } else {
                        Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(.white)
                            .offset(x: playerManager.isPlaying ? 0 : 3)
                    }
                }
            }

            // Pulsante Timer Spegnimento
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showingSleepTimerSheet = true
            }) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 58, height: 58)
                        .overlay(Circle().stroke(sleepTimerRemaining != nil ? Color.orange : Color.white.opacity(0.15), lineWidth: 1))

                    VStack(spacing: 2) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(sleepTimerRemaining != nil ? .orange : .white)

                        if let min = sleepTimerRemaining {
                            Text("\(min)m")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Barra Azioni Inferiore (WhatsApp & Info)
    private var bottomBarView: some View {
        HStack(spacing: 16) {
            // Pulsante WhatsApp Ufficiale
            Button(action: openWhatsApp) {
                HStack(spacing: 10) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Scrivici su WhatsApp")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.15, green: 0.82, blue: 0.45), Color(red: 0.10, green: 0.68, blue: 0.35)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color.green.opacity(0.3), radius: 10, x: 0, y: 5)
            }

            // Pulsante Info
            Button(action: { showingInfoSheet = true }) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(width: 52, height: 52)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Sfondo Ambientale Sfocato
    private var ambientBackground: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let artwork = playerManager.currentArtwork {
                Image(uiImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .blur(radius: 50)
                    .opacity(0.4)
            } else {
                RadialGradient(
                    colors: [Color(red: 0.12, green: 0.18, blue: 0.35), Color.black],
                    center: .center,
                    startRadius: 50,
                    endRadius: 500
                )
                .ignoresSafeArea()
            }

            // Vignettatura scura per leggibilità ottimale
            Color.black.opacity(0.45).ignoresSafeArea()
        }
    }

    // MARK: - Azione WhatsApp
    private func openWhatsApp() {
        let currentSong = playerManager.currentSongTitle
        let message = "Ciao Radio Futura Sorso! Vi sto ascoltando dall'App iOS (in onda: \(currentSong))"
        let encodedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let cleanPhone = whatsAppPhone.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)

        if let appURL = URL(string: "whatsapp://send?phone=\(cleanPhone)&text=\(encodedMessage)"),
           UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else if let webURL = URL(string: "https://wa.me/\(cleanPhone)?text=\(encodedMessage)") {
            UIApplication.shared.open(webURL)
        }
    }

    // MARK: - Sleep Timer
    private func startSleepTimer(minutes: Int) {
        sleepTimerRemaining = minutes
        sleepTimer?.invalidate()
        sleepTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            if let current = sleepTimerRemaining, current > 1 {
                sleepTimerRemaining = current - 1
            } else {
                cancelSleepTimer()
                playerManager.stop()
            }
        }
    }

    private func cancelSleepTimer() {
        sleepTimer?.invalidate()
        sleepTimer = nil
        sleepTimerRemaining = nil
    }
}

// MARK: - Equalizzatore Animato
struct EqualizerAnimationView: View {
    @State private var heights: [CGFloat] = [10, 18, 14, 24, 8, 20, 16, 22, 12]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<heights.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(LinearGradient(colors: [.green, .cyan], startPoint: .bottom, endPoint: .top))
                    .frame(width: 4, height: heights[index])
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.15)) {
                    heights = (0..<9).map { _ in CGFloat.random(in: 4...26) }
                }
            }
        }
    }
}

// MARK: - Scheda Info Radio
struct RadioInfoView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Dettagli Emittente") {
                    LabeledContent("Stazione", value: "Radio Futura Sorso")
                    LabeledContent("Trasmissione", value: "Solo online")
                    LabeledContent("Località", value: "Marina di Sorso (Sassari)")
                    LabeledContent("Regione", value: "Sardegna, Italia")
                    LabeledContent("Sito Ufficiale", value: "www.radiofuturasorso.it")
                }

                Section("Specifiche Tecniche Audio") {
                    LabeledContent("Codec", value: "MP3 Audio (128 kbps, 44.1 kHz)")
                    LabeledContent("Streaming Server", value: "Shoutcast DNAS v2")
                    LabeledContent("Supporto", value: "AirPlay 2, Bluetooth, Apple CarPlay")
                    LabeledContent("Background Audio", value: "Abilitato (AVAudioSession)")
                }

                Section("Contatti") {
                    Link("Apri Sito Web", destination: URL(string: "https://www.radiofuturasorso.it")!)
                }
            }
            .navigationTitle("Radio Futura Sorso")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Chiudi") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Scheda Timer Spegnimento
struct SleepTimerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var activeMinutes: Int?
    let onSelect: (Int) -> Void
    let onCancel: () -> Void

    let options = [15, 30, 45, 60, 90]

    var body: some View {
        NavigationStack {
            List {
                if activeMinutes != nil {
                    Section {
                        Button(role: .destructive, action: {
                            onCancel()
                            dismiss()
                        }) {
                            Text("Disattiva Timer")
                        }
                    }
                }

                Section("Seleziona durata spegnimento automatico") {
                    ForEach(options, id: \.self) { min in
                        Button(action: {
                            onSelect(min)
                            dismiss()
                        }) {
                            HStack {
                                Text("\(min) minuti")
                                Spacer()
                                if activeMinutes == min {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Timer Spegnimento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Chiudi") { dismiss() }
                }
            }
        }
    }
}
