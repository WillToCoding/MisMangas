//
//  ContentView.swift
//  MisMangas
//
//  Created by Juan Carlos on 4/12/25.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = MangaViewModel()
    @State private var showFilters = false
    @State private var viewMode: ViewMode = .list

    enum ViewMode {
        case list, grid
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.mangas.isEmpty {
                    ProgressView("loading_mangas")
                } else if let errorMessage = viewModel.errorMessage {
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
                    // Toggle entre List y Grid
                    switch viewMode {
                    case .list:
                        List(viewModel.mangas) { manga in
                            NavigationLink(value: manga) {
                                MangaRow(manga: manga)
                            }
                        }
                        .refreshable {
                            if viewModel.filters.isActive {
                                await viewModel.applyFilters()
                            } else {
                                await viewModel.fetchMangas()
                            }
                        }

                    case .grid:
                        MangaGridView(mangas: viewModel.mangas)
                            .refreshable {
                                if viewModel.filters.isActive {
                                    await viewModel.applyFilters()
                                } else {
                                    await viewModel.fetchMangas()
                                }
                            }
                    }
                }
            }
            .navigationTitle("nav_explore")
            .navigationDestination(for: Manga.self) { manga in
                MangaDetailView(manga: manga)
            }
            .toolbar {
                // Toggle List/Grid
                ToolbarItem(placement: .topBarLeading) {
                    Picker("view_mode", selection: $viewMode) {
                        Label("view_list", systemImage: "list.bullet")
                            .tag(ViewMode.list)
                        Label("view_grid", systemImage: "square.grid.2x2")
                            .tag(ViewMode.grid)
                    }
                    .pickerStyle(.segmented)
                }

                // Loading indicator
                ToolbarItem(placement: .status) {
                    if viewModel.isLoading && !viewModel.mangas.isEmpty {
                        ProgressView()
                    }
                }

                // Botón de filtros
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
            .sheet(isPresented: $showFilters) {
                FilterView(filters: $viewModel.filters)
            }
        }
        .task {
            await viewModel.fetchMangas()
        }
        .onChange(of: viewModel.filters) { oldValue, newValue in
            // Solo aplicar filtros si realmente cambiaron
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

#Preview {
    ContentView()
}
