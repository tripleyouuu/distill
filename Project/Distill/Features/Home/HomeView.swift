import SwiftUI
import PhotosUI
import os

struct HomeView: View {

    // MARK: - State

    @State private var showPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var errorMessage: String?
    private let logger = Logger(subsystem: "com.morad.Distill", category: "ColorExtraction")

    var body: some View {
        
        NavigationStack {
            
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
                
                Spacer()
                
                Divider()
                
                // MARK: - Painting Grid
                
            }
            .navigationTitle("Distill")
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
