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

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            ScrollView {
                VStack {

                    // MARK: - Header

                    Button("Start Painting") {
                        showModePicker = true
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
                guard let newItem else { return }
                Task {
                    defer { selectedPhotoItem = nil }
                    await viewModel.process(newItem, into: modelContext)
                }
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
                    PaintingCard(image: image, paletteHex: entry.paletteHex)
                        .onTapGesture {
                            // TODO: Viewer modal / carousel
                        }
                }
            }
        }
        .padding(Layout.contentPadding)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Select") {
                // TODO: Enter selection mode
            }
        }

        ToolbarSpacer(.fixed, placement: .topBarTrailing)

        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                // TODO: Translate
            } label: {
                Image(systemName: "translate")
            }
            .accessibilityLabel("Translate")

            Button {
                // TODO: About Distill
            } label: {
                Image(systemName: "info.circle")
            }
            .accessibilityLabel("About Distill")
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: JournalEntry.self, inMemory: true)
}
