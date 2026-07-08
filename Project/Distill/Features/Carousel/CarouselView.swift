import SwiftUI
import PencilKit
import SwiftData

struct CarouselView: View {

    let entry: JournalEntry
    var onContinue: ((JournalEntry) -> Void)?

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var modelContext

    // MARK: - State

    @State private var viewModel = CarouselViewModel()
    @State private var showDeleteAlert = false
    @State private var showingReference = false

    var body: some View {

        NavigationStack {

            VStack {

                Spacer()

                if let image = viewModel.displayedImage(for: entry, showingReference: showingReference) {

                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()

                }

                Spacer()

            }
            .padding()
            .navigationTitle(viewModel.title(for: entry))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                }

                ToolbarItem(placement: .topBarTrailing) {

                    Menu {

                        if entry.isToday {

                            Button {
                                dismiss()
                                // Small delay to let the sheet dismiss before presenting the full screen cover
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    onContinue?(entry)
                                }
                            } label: {
                                Label("Continue", systemImage: "pencil")
                            }

                        }

                        Toggle(isOn: $showingReference) {
                            Label("Toggle Reference", systemImage: "eye")
                        }

                        Button {

                        } label: {
                            Label("Share Painting", systemImage: "square.and.arrow.up")
                        }

                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                    } label: {

                        Image(systemName: "ellipsis")

                    }

                }

            }
            .safeAreaInset(edge: .bottom) {
                if entry.isToday {
                    Text("You can continue editing this painting till the day ends.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 30)
                }
            }
            .alert(
                "Delete Painting?",
                isPresented: $showDeleteAlert
            ) {

                Button("Cancel", role: .cancel) { }

                Button("Delete", role: .destructive) {
                    // ViewModel handles files + SwiftData; View handles dismiss.
                    do {
                        try viewModel.delete(entry, from: modelContext)
                        dismiss()
                    } catch {
                        // TODO: surface this error via an alert
                        print("Delete failed: \(error)")
                    }
                }

            } message: {

                Text("This can't be undone.")

            }

        }

    }

}


#Preview {

    CarouselView(
        entry: JournalEntry(
            referenceImageIdentifier: "",
            paintingImageIdentifier: "",
            paletteHex: []
        )
    )

}
