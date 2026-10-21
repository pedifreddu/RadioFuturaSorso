//
//  ArtworkFetcher.swift
//  Radio Futura Sorso
//
//  Scarica automaticamente le copertine ufficiali in alta risoluzione
//  per la canzone attualmente in onda tramite l'API pubblica di Apple iTunes.
//

import UIKit

public final class ArtworkFetcher {
    public static let shared = ArtworkFetcher()
    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 50
    }

    public func fetchArtwork(forArtist artist: String, songTitle: String, completion: @escaping (UIImage?) -> Void) {
        let cleanArtist = artist.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanTitle = songTitle.replacingOccurrences(of: "\(.*\)", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanArtist.isEmpty, !cleanArtist.lowercased().contains("radio futura") else {
            completion(nil)
            return
        }

        let cacheKey = "\(cleanArtist)-\(cleanTitle)" as NSString
        if let cachedImage = cache.object(forKey: cacheKey) {
            completion(cachedImage)
            return
        }

        let searchTerm = "\(cleanArtist) \(cleanTitle)"
        guard let encodedTerm = searchTerm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let searchURL = URL(string: "https://itunes.apple.com/search?term=\(encodedTerm)&entity=song&limit=1") else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: searchURL) { [weak self] data, _, error in
            guard let self = self, let data = data, error == nil else {
                completion(nil)
                return
            }

            struct SearchResponse: Decodable {
                struct Track: Decodable {
                    let artworkUrl100: String?
                }
                let results: [Track]
            }

            guard let response = try? JSONDecoder().decode(SearchResponse.self, from: data),
                  let firstResult = response.results.first,
                  let smallArtworkURLString = firstResult.artworkUrl100 else {
                completion(nil)
                return
            }

            // Trasforma la risoluzione da 100x100 a 600x600 per Retina Display
            let highResURLString = smallArtworkURLString.replacingOccurrences(of: "100x100bb.jpg", with: "600x600bb.jpg")
            guard let highResURL = URL(string: highResURLString) else {
                completion(nil)
                return
            }

            URLSession.shared.dataTask(with: highResURL) { [weak self] imgData, _, _ in
                guard let imgData = imgData, let image = UIImage(data: imgData) else {
                    completion(nil)
                    return
                }

                self?.cache.setObject(image, forKey: cacheKey)
                completion(image)
            }.resume()
        }.resume()
    }
}
