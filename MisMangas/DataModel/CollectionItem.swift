//
//  CollectionItem.swift
//  MisMangas
//
//  Created by Juan Carlos on 1/2/26.
//

import Foundation

/// Protocolo que unifica `UserCollection` (local) y `UserMangaCollection` (cloud).
///
/// `CollectionItem` permite crear vistas genericas que funcionan tanto con
/// la coleccion local (SwiftData) como con la coleccion cloud (API).
///
/// ## Conformance
///
/// - `UserCollection`: Coleccion local persistida con SwiftData
/// - `UserMangaCollection`: Coleccion cloud obtenida de la API
///
/// ## Ejemplo de uso
///
/// ```swift
/// struct CollectionRow<Item: CollectionItem>: View {
///     let item: Item
///
///     var body: some View {
///         HStack {
///             Text(item.collectionTitle)
///             Spacer()
///             Text("\(item.collectionVolumesOwned.count) vols")
///         }
///     }
/// }
/// ```
///
/// ## Propiedades
///
/// Todas las propiedades usan el prefijo `collection` para evitar
/// conflictos con propiedades existentes en los tipos conformantes.
protocol CollectionItem: Identifiable {
    /// Titulo del manga.
    var collectionTitle: String { get }
    /// Titulo en japones.
    var collectionTitleJapanese: String? { get }
    /// URL de la imagen de portada.
    var collectionCoverURL: URL? { get }
    /// Puntuacion media del manga.
    var collectionScore: Double { get }
    /// Volumenes que posee el usuario.
    var collectionVolumesOwned: [Int] { get }
    /// Total de volumenes del manga.
    var collectionTotalVolumes: Int? { get }
    /// Total de capitulos del manga.
    var collectionTotalChapters: Int? { get }
    /// Volumen que esta leyendo actualmente.
    var collectionReadingVolume: Int? { get }
    /// Indica si tiene la coleccion fisica completa.
    var collectionIsComplete: Bool { get }
    /// Estado de lectura (reading, completed, etc.).
    var collectionReadingStatus: ReadingStatus { get }
    /// Estado de publicacion del manga.
    var collectionStatus: String { get }
    /// Sinopsis del manga.
    var collectionSynopsis: String? { get }
    /// Generos del manga.
    var collectionGenres: [String] { get }
    /// ID del manga en la API.
    var collectionMangaId: Int { get }
    /// `true` si viene de cloud, `false` si es local.
    var isCloudSynced: Bool { get }
}

// MARK: - UserMangaCollection Conformance (Cloud/API)

/// Conformance de ``UserMangaCollection`` al protocolo ``CollectionItem``.
///
/// Adapta los datos de la coleccion cloud para usarse en vistas genericas.
/// `isCloudSynced` siempre devuelve `true` para items cloud.
extension UserMangaCollection: CollectionItem {
    var collectionTitle: String { manga.title }
    var collectionTitleJapanese: String? { manga.titleJapanese }
    var collectionCoverURL: URL? { manga.coverURL }
    var collectionScore: Double { manga.score }
    var collectionVolumesOwned: [Int] { volumesOwned }
    var collectionTotalVolumes: Int? { manga.volumes }
    var collectionTotalChapters: Int? { manga.chapters }
    var collectionReadingVolume: Int? { readingVolume }
    var collectionIsComplete: Bool { completeCollection }
    var collectionReadingStatus: ReadingStatus { completeCollection ? .completed : .reading }
    var collectionStatus: String { manga.status }
    var collectionSynopsis: String? { manga.sypnosis }
    var collectionGenres: [String] { manga.genres.map(\.genre) }
    var collectionMangaId: Int { manga.id }
    var isCloudSynced: Bool { true }
}
