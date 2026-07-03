import SwiftUI
import PhotosUI

struct HomeView: View {

    // MARK: - State

    @State private var showPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?

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
            // Just a dummy Task for now, it discards whatever the user choose.
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }

                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        print("Picked image: \(uiImage.size)")
                    } else {
                        print("Failed to load selected photo")
                    }

                    selectedPhotoItem = nil
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
