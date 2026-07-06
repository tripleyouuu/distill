import SwiftUI
import SwiftData

struct CarouselView: View {

    let entry: JournalEntry

    @Environment(\.dismiss)
    private var dismiss
    
    @Environment(\.modelContext)
    private var modelContext

    @State
    private var showDeleteAlert = false

    @State private var showingReference = false

    private let imageStore = ImageStore()

    var body: some View {

        NavigationStack {

            VStack {

                Spacer()

                if let image = displayedImage {

                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()

                }

                Spacer()

            }
            .padding()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                }

                ToolbarItem(placement: .topBarTrailing) {

                    Menu {

                        if entry.isToday {

                            Button {

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

                    deletePainting()

                }

            } message: {

                Text("This can't be undone.")

            }

        }

    }

    private var displayedImage: UIImage? {

        if showingReference {

            return imageStore.loadReference(
                identifier: entry.referenceImageIdentifier
            )

        }

        return imageStore.loadPainting(
            identifier: entry.paintingImageIdentifier
        )

    }

    private var title: String {

        if entry.isToday {

            return "Today"

        }

        return entry.createdAt.formatted(
            date: .complete,
            time: .omitted
        )

    }
    
    private func deletePainting() {

        imageStore.deletePainting(
            identifier: entry.paintingImageIdentifier
        )

        imageStore.deleteReference(
            identifier: entry.referenceImageIdentifier
        )

        modelContext.delete(entry)

        do {

            try modelContext.save()

            dismiss()

        } catch {

            print(error)

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
