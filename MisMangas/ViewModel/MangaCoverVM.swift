//
//  MangaCoverVM.swift
//  MisMangas
//
//  Created by Juan Carlos on 1/2/26.
//

import SwiftUI
import NetworkAPI

/// ViewModel para cargar y cachear imágenes de covers de manga
@Observable @MainActor
final class MangaCoverVM {
    var image: UIImage?
    var isLoading = false

    func getImage(url: URL?) {
        guard let url else { return }

        // Verificar si ya está en caché de disco
        let file = ImageDownloader.shared.getFileURL(url: url)
        if FileManager.default.fileExists(atPath: file.path()) {
            do {
                let data = try Data(contentsOf: file)
                image = UIImage(data: data)
                return
            } catch {
                print("Error loading cached image: \(error)")
            }
        }

        // Si no está en caché, descargar
        guard !isLoading else { return }
        isLoading = true

        Task {
            do {
                image = try await ImageDownloader.shared.image(for: url)
            } catch {
                print("Error downloading image: \(error)")
            }
            isLoading = false
        }
    }
}
