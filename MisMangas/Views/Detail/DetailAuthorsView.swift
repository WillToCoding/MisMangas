//
//  DetailAuthorsView.swift
//  MisMangas
//
//  Created by Juan Carlos on 4/12/25.
//

import SwiftUI

struct DetailAuthorsView: View {
    let authors: [Author]

    var body: some View {
        if !authors.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("detail_authors")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityHeading(.h2)

                ForEach(authors) { author in
                    AuthorRow(author: author)
                }
            }
        }
    }
}

// MARK: - Author Row
private struct AuthorRow: View {
    let author: Author

    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .foregroundStyle(.blue)
                .accessibilityHidden(true)

            VStack(alignment: .leading) {
                Text("\(author.firstName) \(author.lastName)")
                    .font(.subheadline)
                Text(author.role)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(author.firstName) \(author.lastName), \(author.role)")
    }
}

#Preview {
    DetailAuthorsView(authors: Manga.test.authors)
        .padding()
}
