//
//  RadioPlayerManager.swift
//  Radio Futura Sorso
//
//  Gestore centrale di streaming audio per iOS, iPadOS e Apple CarPlay.
//

import Foundation
import AVFoundation
import MediaPlayer
import Combine
import UIKit

public final class RadioPlayerManager: NSObject, ObservableObject {
    public static let shared = RadioPlayerManager()

    // MARK: - Proprietà Pubblicate per SwiftUI
    @Published public var isPlaying: Bool = false
    @Published public var isLoading: Bool = false
    @Published public var streamError: String? = nil
    
    @Published public var currentSongTitle: String = "Solo online – In Diretta"
    @Published public var currentArtist: String = "Radio Futura Sorso"
    @Published public var currentArtwork: UIImage? = nil
    @Published public var listenersCount: Int = 0
    @Published public var bitrate: String = "128 kbps"
    
    // MARK: - Costanti
    public let streamURL = URL(string: "https://marinadisorso.radioca.st/stream.mp3")!
    public let statsURL = URL(string: "https://marinadisorso.radioca.st/stats?sid=1&json=1")!
    public let stationName = "Radio Futura Sorso"
    public let stationTagline = "Solo online"

    // MARK: - Proprietà Private
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var metadataTimer: Timer?
    private var statusObservation: NSKeyValueObservation?
    private var cancellables = Set<AnyCancellable>()

    private override init() {
        super.init()
        setupRemoteCommandCenter()
        setupAudioSessionNotifications()
        startMetadataPolling()
    }

    deinit {
        stop()
        metadataTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Controllo Riproduzione
    public func play() {
        guard !isPlaying else { return }
        
        isLoading = true
        streamError = nil

        // Configura la sessione audio attiva
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[Player] Impossibile attivare AVAudioSession: \(error)")
        }

        // Ricrea o riavvia AVPlayerItem con URL pulito
        let asset = AVURLAsset(url: streamURL)
        playerItem = AVPlayerItem(asset: asset)
        
        // Osserva lo stato dell'AVPlayerItem
        statusObservation = playerItem?.observe(\ .status, options: [.new, .initial]) { [weak self] item, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch item.status {
                case .readyToPlay:
                    self.isLoading = false
                    self.isPlaying = true
                    self.updateNowPlayingInfo()
                case .failed:
                    self.isLoading = false
                    self.isPlaying = false
                    self.streamError = item.error?.localizedDescription ?? "Errore di connessione allo streaming"
                case .unknown:
                    break
                @unknown default:
                    break
                }
            }
        }

        if player == nil {
            player = AVPlayer(playerItem: playerItem)
            player?.automaticallyWaitsToMinimizeStalling = true
        } else {
            player?.replaceCurrentItem(with: playerItem)
        }

        player?.play()
        isPlaying = true
        updateNowPlayingInfo()
        fetchLiveStats()
    }

    public func stop() {
        player?.pause()
        playerItem = nil
        player?.replaceCurrentItem(with: nil)
        statusObservation?.invalidate()
        statusObservation = nil
        
        isPlaying = false
        isLoading = false
        updateNowPlayingInfo()
    }

    public func togglePlayStop() {
        if isPlaying {
            stop()
        } else {
            play()
        }
    }

    // MARK: - Polling Metadati ICY & Shoutcast
    private func startMetadataPolling() {
        fetchLiveStats()
        // Esegue il refresh dei metadati ogni 10 secondi
        metadataTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.fetchLiveStats()
        }
    }

    @objc public func fetchLiveStats() {
        let task = URLSession.shared.dataTask(with: statsURL) { [weak self] data, response, error in
            guard let self = self, let data = data, error == nil else { return }

            struct ShoutcastStats: Decodable {
                let songtitle: String?
                let servertitle: String?
                let bitrate: String?
                let currentlisteners: Int?
            }

            if let stats = try? JSONDecoder().decode(ShoutcastStats.self, from: data) {
                DispatchQueue.main.async {
                    if let listeners = stats.currentlisteners {
                        self.listenersCount = listeners
                    }
                    if let br = stats.bitrate {
                        self.bitrate = "\(br) kbps"
                    }
                    if let rawSong = stats.songtitle, !rawSong.isEmpty {
                        self.parseAndApplySong(rawSong)
                    }
                }
            }
        }
        task.resume()
    }

    private func parseAndApplySong(_ rawTitle: String) {
        let parts = rawTitle.components(separatedBy: " - ")
        let newArtist: String
        let newTitle: String

        if parts.count >= 2 {
            newArtist = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            newTitle = parts.dropFirst().joined(separator: " - ").trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            newArtist = stationName
            newTitle = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Se la traccia è cambiata, aggiorna e cerca la copertina
        if newTitle != self.currentSongTitle || newArtist != self.currentArtist {
            self.currentArtist = newArtist
            self.currentSongTitle = newTitle
            self.updateNowPlayingInfo()

            // Cerca la copertina dell'album tramite iTunes Search API
            ArtworkFetcher.shared.fetchArtwork(forArtist: newArtist, songTitle: newTitle) { [weak self] image in
                DispatchQueue.main.async {
                    self?.currentArtwork = image
                    self?.updateNowPlayingInfo()
                }
            }
        }
    }

    // MARK: - Schermata di Blocco e Centro Notifiche (MPNowPlayingInfoCenter)
    public func updateNowPlayingInfo() {
        var nowPlayingInfo = [String: Any]()

        nowPlayingInfo[MPMediaItemPropertyTitle] = currentSongTitle
        nowPlayingInfo[MPMediaItemPropertyArtist] = currentArtist
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "\(stationName) – \(stationTagline)"
        nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = true
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0

        if let artworkImage = currentArtwork ?? UIImage(named: "AppLogo") {
            let artwork = MPMediaItemArtwork(boundsSize: artworkImage.size) { _ in
                return artworkImage
            }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    // MARK: - Controlli Remoti (Lock Screen, AirPods, Apple Watch, Apple CarPlay)
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }

        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.stop()
            return .success
        }

        commandCenter.stopCommand.isEnabled = true
        commandCenter.stopCommand.addTarget { [weak self] _ in
            self?.stop()
            return .success
        }

        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.togglePlayStop()
            return .success
        }
    }

    // MARK: - Gestione Interruzioni e Cambio Uscita Audio (Cuffie / Bluetooth / AirPlay)
    private func setupAudioSessionNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    @objc private func handleAudioInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            // Telefonata in arrivo o comando vocale Siri
            if isPlaying {
                player?.pause()
            }
        case .ended:
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) && isPlaying {
                    play()
                }
            }
        @unknown default:
            break
        }
    }

    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }

        // Se le cuffie o il Bluetooth vengono disconnessi, metti in pausa per evitare di suonare a tutto volume
        if reason == .oldDeviceUnavailable {
            DispatchQueue.main.async {
                self.stop()
            }
        }
    }
}
