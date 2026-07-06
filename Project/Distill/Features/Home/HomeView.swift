import SwiftUI
import PhotosUI
import os
import SwiftData

struct HomeView: View {
    
    // MARK: - Setting up for dummy grid
    
    @Environment(\.modelContext)
    private var modelContext

    @Query(sort: \JournalEntry.createdAt, order: .reverse)
    private var journalEntries: [JournalEntry]

    private let imageStore = ImageStore()
    private let generator = PaintingGenerator()

    // MARK: - State

    @State private var showPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var errorMessage: String?
    private let logger = Logger(subsystem: "com.morad.Distill", category: "ColorExtraction")

    var body: some View {
        
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
                    .foregroundStyle(Color(uiColor: .systemBackground))
                    .controlSize(.large)
                    
                    Divider()
                        .padding(.top, 50)
                    
                    // MARK: - Painting Grid
                    
                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: 150), spacing: 50)
                        ],
                        spacing: 50
                    ) {

                        ForEach(journalEntries) { entry in

                            if let image = imageStore.loadPainting(
                                identifier: entry.paintingImageIdentifier
                            ) {

                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 150, height: 150)
                                    .clipShape(
                                        RoundedRectangle(cornerRadius: 18)
                                    )
                                    .contentShape(
                                        RoundedRectangle(cornerRadius: 18)
                                    )
                                    .onTapGesture {

                                        // Viewer modal comes later.

                                    }

                            }

                        }

                    }

                    .padding(50)
                }
            }
            .navigationTitle("Distill")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Select") {
                        
                    }
                }
                
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
                
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        
                    } label: {
                        Image(systemName: "translate")
                    }
                    .accessibilityLabel("Translate")
                    
                    Button {
                        
                    } label: {
                        Image(systemName: "info.circle")
                    }
                    .accessibilityLabel("About Distill")
                }
            }
            .photosPicker(
                isPresented: $showPhotoPicker,
                selection: $selectedPhotoItem,
                matching: .images
            )
            .photosPickerDisabledCapabilities(.collectionNavigation)
            // Photo Selection Error: user-facing error surface
            .alert("Something went wrong", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }


            // MARK: - Extracting the dominant colors.

            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }

                Task {
                    
                    // It makes sure that the image selection, reseted to nil, so the user if he clicked start painting again, get to choose a brand new image.
                    defer { selectedPhotoItem = nil }

                    // Loading the image, and casting it into UIImage
                    do {
                        guard let data = try await newItem.loadTransferable(type: Data.self),
                              let originalImage = UIImage(data: data) else {

                            errorMessage = "Couldn't load that photo. Try a different one."
                            return
                        }

                        // Resize image
                        let targetSize = CGSize(width: 100, height: 100)

                        guard let resizedImage = originalImage.resize(to: targetSize) else {
                            errorMessage = "Failed to process the image./n Please try again."
                            return
                        }

                        // Extract dominant colors
                        let extractor = DominantColorExtractor()
                        let colors = try await extractor.extract(from: resizedImage)
                        logger.debug("Extracted \(colors.count) colors")
                        for (index, color) in colors.enumerated() {
                            logger.debug("Color \(index + 1): \(String(describing: color))")
                        }

                        // TODO: do something with colors — pass to your canvas, update @State, etc.
                        // (test) Generate a placeholder painting
                        let generatedPainting = generator.generate(from: colors)

                        // (test) Save both images to disk
                        let referenceIdentifier = try imageStore.saveReference(originalImage)
                        let paintingIdentifier = try imageStore.savePainting(generatedPainting)

                        // (test) Create the journal entry
                        let entry = JournalEntry(
                            referenceImageIdentifier: referenceIdentifier,
                            paintingImageIdentifier: paintingIdentifier,
                            paletteHex: colors.map(\.hex)
                        )

                        // (test) Persist it
                        modelContext.insert(entry)

                        do {
                            try modelContext.save()
                            logger.debug("Journal entry saved successfully.")
                        } catch {
                            logger.error("Failed to save journal entry: \(error.localizedDescription)")
                            errorMessage = "Couldn't save your painting."
                        }

                    } catch {
                        logger.error("Color extraction failed: \(error.localizedDescription)")
                        errorMessage = "Color extraction failed. Please try again."
                    }
                }
            }

        }
    }
}

#Preview {
    HomeView()
}
