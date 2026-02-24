//
//  MangaCoverVM.swift
//  MisMangas
//
//  Created by Juan Carlos on 1/2/26.
//

import SwiftUI

#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
import NetworkAPI
import UIKit
typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
typealias PlatformImage = NSImage
#endif

/// ViewModel para cargar y cachear imágenes de covers de manga
@Observable @MainActor
final class MangaCoverVM {
    var image: PlatformImage?
    var isLoading = false

    func getImage(url: URL?) {
        guard let url else { return }

        #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
        // Verificar si ya está en caché de disco
        let file = ImageDownloader.shared.getFileURL(url: url)
        if FileManager.default.fileExists(atPath: file.path()) {
            do {
                let data = try Data(contentsOf: file)
                image = PlatformImage(data: data)
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
        #elseif os(macOS)
        // macOS: descargar directamente (NSImage)
        guard !isLoading else { return }
        isLoading = true

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                image = PlatformImage(data: data)
            } catch {
                print("Error downloading image: \(error)")
            }
            isLoading = false
        }
        #endif
    }
}
