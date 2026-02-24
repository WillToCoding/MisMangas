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
    @Namespace private var namespace

    enum ViewMode {
        case list, grid
    }

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
                        .accessibilityHint(String(localized: "accessibility_retry_hint"))
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
                            .accessibilityHint(String(localized: "accessibility_clear_filters_hint"))
                        }
                    }
                } else {
                    // Toggle entre List y Grid
                    switch viewMode {
                    case .list:
                        List(viewModel.mangas) { manga in
                            NavigationLink(value: manga) {
                                MangaRow(manga: manga, namespace: namespace)
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
                        MangaGridView(mangas: viewModel.mangas, namespace: namespace)
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
                MangaDetailView(manga: manga, namespace: namespace)
            }
            .toolbar {
                // Toggle List/Grid
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        #if os(iOS)
                        HapticFeedback.selection.trigger()
                        #endif
                        viewMode = viewMode == .list ? .grid : .list
                    } label: {
                        Image(systemName: viewMode == .list ? "list.bullet" : "square.grid.2x2")
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .accessibilityLabel(viewMode == .list
                        ? String(localized: "accessibility_view_list")
                        : String(localized: "accessibility_view_grid"))
                    .accessibilityHint(viewMode == .list
                        ? String(localized: "accessibility_switch_to_grid")
                        : String(localized: "accessibility_switch_to_list"))
                    .accessibilitySortPriority(2)
                }

                // Loading indicator
                ToolbarItem(placement: .status) {
                    if viewModel.state.isLoading && !viewModel.mangas.isEmpty {
                        ProgressView()
                            .accessibilityLabel(String(localized: "accessibility_loading_more"))
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
                    .accessibilityLabel(viewModel.filters.isActive ? String(localized: "accessibility_filters_active") : String(localized: "accessibility_filters"))
                    .accessibilityHint(String(localized: "accessibility_filters_hint"))
                    .accessibilitySortPriority(1)
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

#Preview(traits: .sampleData) {
    ContentView()
}
