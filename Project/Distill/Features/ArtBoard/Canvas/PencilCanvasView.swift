import SwiftUI

struct PencilCanvasView: View {

    @Environment(\.dismiss)
    private var dismiss

    var body: some View {

        Color(uiColor: .systemBackground)
            .ignoresSafeArea()
            .navigationBarBackButtonHidden()
            .toolbar {

                ToolbarItem(placement: .topBarLeading) {

                    Button {

                        dismiss()

                    } label: {

                        Image(systemName: "chevron.left")

                    }

                }

                ToolbarItem(placement: .topBarTrailing) {

                    Menu {

                        Button {

                        } label: {
                            Label("Toggle Reference", systemImage: "eye")
                        }

                        Button {

                        } label: {
                            Label("Share Painting", systemImage: "square.and.arrow.up")
                        }

                        Button(role: .destructive) {

                        } label: {
                            Label("Reset Canvas", systemImage: "trash")
                        }

                    } label: {

                        Image(systemName: "ellipsis")

                    }

                }

            }

    }

}

#Preview {

    NavigationStack {

        PencilCanvasView()

    }

}
