import SwiftUI
import PhotosUI
import SwiftData
import PencilKit

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
    @State private var continueRequest: JournalEntry?
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

                    Button {
                        showPhotoPicker = true
                    } label: {
                        Label("Start Painting", systemImage: "sparkles")
                            .frame(width: 280)
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
            .fullScreenCover(item: $continueRequest) { entry in
                continueArtBoardView(for: entry)
            }
            .sheet(item: $selectedEntry) { entry in
                CarouselView(entry: entry) { entryToContinue in
                    selectedEntry = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        continueRequest = entryToContinue
                    }
                }
            }
            .sheet(isPresented: $showNotifications) {
                NotificationSettingsView(service: notificationService)
                    .presentationDetents([.large])
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

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isSelecting = false
                    selectedEntries.removeAll()
                } label: {
                    Image(systemName: "checkmark")
                }
                .accessibilityLabel("Done")
                .buttonStyle(.borderedProminent)
                .tint(.black)
                .foregroundStyle(.white)
                .controlSize(.large)
            }

            ToolbarItemGroup(placement: .topBarTrailing) {

                Button {
                    // TODO: Share selected entries
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Share")

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("Delete")
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
                .sheet(isPresented: $showAbout) {
                    InfoPageView()
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                }
            }
        }
    }
    @ViewBuilder
    private func continueArtBoardView(for entry: JournalEntry) -> some View {
        if let referenceImage = ImageStore().loadReference(identifier: entry.referenceImageIdentifier) {
            let palette = entry.paletteHex.map { Color(hex: $0) }
            let existingDrawing: PKDrawing? = {
                guard let data = entry.drawingData else { return nil }
                return try? PKDrawing(data: data)
            }()
            
            NavigationStack {
                ArtBoardView(
                    referenceImage: referenceImage,
                    palette: palette,
                    onFinish: {
                        continueRequest = nil
                    },
                    existingEntry: entry,
                    existingDrawing: existingDrawing
                )
            }
        } else {
            // Fallback if image fails to load
            Color.black
                .ignoresSafeArea()
                .overlay {
                    Text("Could not load painting data.")
                        .foregroundColor(.white)
                }
                .onAppear {
                    // Auto dismiss after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        continueRequest = nil
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
