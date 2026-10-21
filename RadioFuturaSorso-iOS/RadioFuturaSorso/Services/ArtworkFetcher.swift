//
//  ArtworkFetcher.swift
//  Radio Futura Sorso
//
//  Recupera automaticamente le copertine delle canzoni tramite Apple iTunes.
//

import UIKit
import Foundation

public final class ArtworkFetcher {
    public static let shared = ArtworkFetcher()
    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 50
    }

    public func fetchArtwork(
        forArtist artist: String,
        songTitle: String,
        completion: @escaping (UIImage?) -> Void
    ) {
        let cleanArtist = artist.trimmingCharacters(in: .whitespacesAndNewlines)

        let cleanTitle = songTitle
            .replacingOccurrences(
                of: #"\(.*?\)"#,
                with: "",
                options: .regularExpression
            )
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanArtist.isEmpty,
              !cleanTitle.isEmpty,
              !cleanArtist.lowercased().contains("radio futura") else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }

        let cacheKey = "\(cleanArtist)-\(cleanTitle)" as NSString

        if let cachedImage = cache.object(forKey: cacheKey) {
            DispatchQueue.main.async {
                completion(cachedImage)
            }
            return
        }

        var components = URLComponents(string: "https://itunes.apple.com/search")
        components?.queryItems = [
            URLQueryItem(name: "term", value: "\(cleanArtist) \(cleanTitle)"),
            URLQueryItem(name: "entity", value: "song"),
            URLQueryItem(name: "limit", value: "1")
        ]

        guard let searchURL = components?.url else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }

        URLSession.shared.dataTask(with: searchURL) { [weak self] data, _, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            struct SearchResponse: Decodable {
                struct Track: Decodable {
                    let artworkUrl100: String?
                }
                let results: [Track]
            }

            guard let response = try? JSONDecoder().decode(SearchResponse.self, from: data),
                  let artworkString = response.results.first?.artworkUrl100 else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            let highResString = artworkString.replacingOccurrences(
                of: "100x100bb",
                with: "600x600bb"
            )

            guard let imageURL = URL(string: highResString) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            URLSession.shared.dataTask(with: imageURL) { imageData, _, imageError in
                guard let imageData = imageData,
                      imageError == nil,
                      let image = UIImage(data: imageData) else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }

                self?.cache.setObject(image, forKey: cacheKey)

                DispatchQueue.main.async {
                    completion(image)
                }
            }.resume()
        }.resume()
    }
}
