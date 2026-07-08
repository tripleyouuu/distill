import SwiftUI

struct InfoPageView: View {

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(alignment: .leading, spacing: 20) {

                    information

                }
                .padding(20)

            }
            .navigationTitle("About Distill")
            .navigationBarTitleDisplayMode(.inline)

        }

    }

    @ViewBuilder
    private var information: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Something we're all familiar with is the ritual of **archiving our memories**. Whether it's for our own reflection, or to share tidbits of our lives with friends, our photo galleries, journal entries, and maybe even our social media are all a testament to the very human need to record moments.")

            Text("The Distill team figured we could bring a creative side to this ritual, making it feel more meditative, and facilitating **the artistic process** for those who could benefit from it.")

            Text("Take a look through your gallery each day, and **pick one photo** that stands out to you. It could be something unique, or perhaps you'll find a simple moment that's worth preserving. Distill will then extract from it a **palette of four colours**.")

            Text("With this palette, and a few simple brushes, you'll **create a painting** that captures the essence of that memory without directly invoking it. Whether that's abstract art, a blocky recreation of the image itself, a piece of writing, or anything else you can think of.")

            Text("Later, view your handiwork from the app gallery. You can **compare it to the reference** for a walk down memory lane that has a far more personal and curated touch to it than any straightforward scroll down your photos.")

            Text("**Things to note:**")
            
            Text("· If you're unhappy with the color palette generated for a particular photo, you can opt to use a different photo instead. However, once you've begun painting for the day, the photo and palette are both locked in place.")

            Text("· Paintings auto-save only when the back button is pressed to return to the home screen. Until the end of the day (local midnight), you can always edit or continue the painting, but not after.")

            Text("· The canvas environment does not have an eraser or undo button, to simulate the mechanics of painting non-digitally. However, you can reset the canvas from the top-right button if needed.")

            Text("· Notification settings can be customized from the home screen.")

            Text("Distill and its developers **do not collect any data from the user**. All photos and paintings are kept on-device, and there is no user authentication - meaning you will lose your work if the app is uninstalled.")
        }
        .font(.body)
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

}

#Preview {
    InfoPageView()
        .presentationDetents([.large])
}
