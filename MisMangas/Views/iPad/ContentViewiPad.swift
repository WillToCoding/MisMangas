//
//  ContentViewiPad.swift
//  MisMangas
//
//  Created by Juan Carlos on 2/2/26.
//

import SwiftUI

struct ContentViewiPad: View {
    @State private var viewModel = MangaViewModel()
    @State private var showFilters = false
    @Namespace private var namespace

    private let columns = [GridItem(.adaptive(minimum: 180), spacing: 20)]

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.state.isLoading && viewModel.mangas.isEmpty {
                    ProgressView("loading_mangas")
                        .accessibilityLabel(String(localized: "accessibility_loading_mangas"))
                } else if let errorMessage = viewModel.state.errorMessage {
                    ContentUnavailableView {
                        Label("error_title", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(errorMessage)
                    } actions: {
                        Button("action_retry") {
                            Task {
                                if viewModel.filters.isActive {
                                    await viewModel.applyFilters()
                                } else {
                                    await viewModel.fetchMangas()
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else if viewModel.mangas.isEmpty {
                    ContentUnavailableView {
                        Label("collection_empty_title", systemImage: "book.closed")
                    } description: {
                        Text(viewModel.filters.isActive
                             ? "filter_no_results"
                             : "filter_no_data")
                    } actions: {
                        if viewModel.filters.isActive {
                            Button("action_clear_filters") {
                                viewModel.filters.clear()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(viewModel.mangas) { manga in
                                NavigationLink(value: manga) {
                                    MangaGridCell(manga: manga, namespace: namespace)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        if viewModel.filters.isActive {
                            await viewModel.applyFilters()
                        } else {
                            await viewModel.fetchMangas()
                        }
                    }
                }
            }
            .navigationTitle("nav_explore")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Manga.self) { manga in
                MangaDetailView(manga: manga, namespace: namespace)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("nav_explore")
                        .font(.title3)
                        .bold()
                }

                ToolbarItem(placement: .status) {
                    if viewModel.state.isLoading && !viewModel.mangas.isEmpty {
                        ProgressView()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showFilters = true
                    } label: {
                        Image(systemName: viewModel.filters.isActive
                              ? "line.3.horizontal.decrease.circle.fill"
                              : "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .toolbarRole(.editor)
            .sheet(isPresented: $showFilters) {
                FilterView(filters: $viewModel.filters)
            }
        }
        .task {
            await viewModel.fetchMangas()
        }
        .onChange(of: viewModel.filters) { oldValue, newValue in
            guard oldValue != newValue else { return }

            Task {
                if newValue.isActive {
                    await viewModel.applyFilters()
                } else {
                    await viewModel.fetchMangas()
                }
            }
        }
    }
}

#Preview(traits: .sampleData) {
    ContentViewiPad()
}
