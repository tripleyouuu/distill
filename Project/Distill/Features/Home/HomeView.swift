import SwiftUI
import PhotosUI
import SwiftData

struct HomeView: View {

    // MARK: - Layout

    private enum Layout {
        static let gridSpacing: CGFloat = 50
        static let gridMinItemWidth: CGFloat = 150
        static let contentPadding: CGFloat = 50
    }

    // MARK: - SwiftData

    @Environment(\.modelContext)
    private var modelContext

    @Query(sort: \JournalEntry.createdAt, order: .reverse)
    private var journalEntries: [JournalEntry]

    // MARK: - State

    @State private var viewModel = HomeViewModel()
    @State private var showPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedEntry: JournalEntry?
    @State private var generationRequest: GenerationRequest?
    @State private var isSelecting: Bool = false
    @State private var selectedEntries: Set<JournalEntry.ID> = []
    @State private var showDeleteConfirmation: Bool = false
    @State private var showAbout: Bool = false
    @State private var showNotifications: Bool = false
    @State private var notificationService = NotificationService()
    
    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            ScrollView {
                VStack {

                    // MARK: - Header

                    Button("Start Painting") {
                        showPhotoPicker = true
                    }
                    .font(.title3.weight(.medium))
                    .buttonStyle(.borderedProminent)
                    .tint(.primary)
                    .foregroundStyle(Color(.systemBackground))
                    .controlSize(.large)
                    .padding(.top, 20)

                    Divider()
                        .padding(.top, Layout.contentPadding)

                    // MARK: - Previous Painting Grid

                    if journalEntries.isEmpty {
                        ContentUnavailableView(
                            "No paintings yet",
                            systemImage: "paintpalette",
                            description: Text("Start a painting to see it here.")
                        )
                        .padding(.top, Layout.contentPadding)
                    } else {
                        paintingGrid
                    }
                }
            }
            .navigationTitle("Distill")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar { toolbarContent }
            .photosPicker(
                isPresented: $showPhotoPicker,
                selection: $selectedPhotoItem,
                matching: .images
            )
            .photosPickerDisabledCapabilities(.collectionNavigation)
            .alert(
                "Something went wrong",
                isPresented: $viewModel.isShowingError,
                presenting: viewModel.errorMessage
            ) { _ in
                Button("OK") { }
            } message: { message in
                Text(message)
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                // Ignore duplicate fires (incl. the picker's own) while a
                // generation is already in flight.
                guard let newItem, generationRequest == nil else { return }
                Task {
                    defer { selectedPhotoItem = nil }
                    if let image = await viewModel.loadImage(from: newItem) {
                        generationRequest = GenerationRequest(image: image)
                    }
                }
            }
            .fullScreenCover(item: $generationRequest) { request in
                GenerationView(referenceImage: request.image, viewModel: viewModel)
            }
            .sheet(item: $selectedEntry) { entry in
                CarouselView(entry: entry)
            }
            .sheet(isPresented: $showNotifications) {
                NotificationSettingsView(service: notificationService)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .alert(
                "Delete \(selectedEntries.count) Painting\(selectedEntries.count == 1 ? "" : "s")?",
                isPresented: $showDeleteConfirmation
            ) {
                Button("Cancel", role: .cancel) { }

                Button("Delete", role: .destructive) {
                    // Confirmed — now actually delete and exit selection mode.
                    viewModel.deleteSelectedEntries(selectedEntries, from: journalEntries, context: modelContext)
                    isSelecting = false
                    selectedEntries = []
                }
            } message: {
                Text("This can't be undone.")
            }
        }
    }

    // MARK: - Subviews

    private var paintingGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.adaptive(minimum: Layout.gridMinItemWidth), spacing: Layout.gridSpacing)
            ],
            spacing: Layout.gridSpacing
        ) {
            ForEach(journalEntries) { entry in
                if let image = viewModel.loadPainting(identifier: entry.paintingImageIdentifier) {
                    PaintingCard(
                                    image: image,
                                    paletteHex: entry.paletteHex,
                                    isSelecting: isSelecting,
                                    // Pass whether THIS specific entry is in the selected set.
                                    isSelected: selectedEntries.contains(entry.id)
                                )
                        .onTapGesture {
                            if isSelecting {
                                if selectedEntries.contains(entry.id) {
                                    selectedEntries.remove(entry.id) // already selected → deselect
                                } else {
                                    selectedEntries.insert(entry.id) // not selected → select
                                }
                            } else {
                                selectedEntry = entry // normal mode → open carousel
                            }
                        }
                }
            }
        }
        .padding(Layout.contentPadding)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if isSelecting {

            // MARK: Selection mode toolbar

            // "Done" exits selection mode and clears any selections.
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isSelecting = false
                    selectedEntries = []
                } label: {
                    Image(systemName: "x.circle")
                }
                .accessibilityLabel("Cancel")
            }

            ToolbarSpacer(.fixed, placement: .topBarTrailing)

            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    // TODO: Share selected entries
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Share")

                Button(role: .destructive) {
                    // Don't delete immediately — show a confirmation alert first.
                    // This is Apple's standard destructive action pattern.
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("Delete")
                // Disabled when nothing is selected — no point confirming an empty action.
                .disabled(selectedEntries.isEmpty)
            }

        } else {

            // MARK: Normal toolbar

            // Label is just "Select" — no state variable needed.
            ToolbarItem(placement: .topBarTrailing) {
                Button("Select") {
                    isSelecting = true
                }
            }

            ToolbarSpacer(.fixed, placement: .topBarTrailing)

            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showNotifications = true
                } label: {
                    Image(systemName: "bell")
                }
                .accessibilityLabel("Notifications")

                Button {
                    showAbout = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .accessibilityLabel("About Distill")
                .popover(isPresented: $showAbout) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Distill")
                            .font(.headline)

                        // TODO: Replace Rania's Design description
                        Text("Distill helps you capture and revisit your paintings.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .presentationCompactAdaptation(.popover) // stays a popover even on iPhone if space allows
                }
            }
        }
    }
}

/// Wraps a picked `UIImage` so it can drive `fullScreenCover(item:)`,
/// which requires an `Identifiable` value (`UIImage` isn't one).
private struct GenerationRequest: Identifiable {
    let id = UUID()
    let image: UIImage
}

#Preview {
    HomeView()
        .modelContainer(for: JournalEntry.self, inMemory: true)
}
