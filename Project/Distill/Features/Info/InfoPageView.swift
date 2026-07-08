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

        (
            Text("Something we're all familiar with is the ritual of ")
            + Text("archiving our memories").bold()
            + Text(". Whether it's for our own reflection, or to share tidbits of our lives with friends, our photo galleries, journal entries, and maybe even our social media are all a testament to the very human need to record moments.\n\n")

            + Text("The Distill team figured we could bring a creative side to this ritual, making it feel more meditative, and facilitating ")
            + Text("the artistic process").bold()
            + Text(" for those who could benefit from it.\n\n")

            + Text("Take a look through your gallery each day, and ")
            + Text("pick one photo").bold()
            + Text(" that stands out to you. It could be something unique, or perhaps you'll find a simple moment that's worth preserving. Distill will then extract from it a ")
            + Text("palette of four colours").bold()
            + Text(".\n\n")

            + Text("With this palette, and a few simple brushes, you'll ")
            + Text("create a painting").bold()
            + Text(" that captures the essence of that memory without directly invoking it. Whether that's abstract art, a blocky recreation of the image itself, a piece of writing, or anything else you can think of.\n\n")

            + Text("Later, view your handiwork from the app gallery. You can ")
            + Text("compare it to the reference").bold()
            + Text(" for a walk down memory lane that has a far more personal and curated touch to it than any straightforward scroll down your photos.\n\n")

            + Text("Things to note:\n").bold()

            + Text("· If you're unhappy with the color palette generated for a particular photo, you can opt to use a different photo instead. However, once you've begun painting for the day, the photo and palette are both locked in place.\n")

            + Text("· Paintings auto-save only when the back button is pressed to return to the home screen. Until the end of the day (local midnight), you can always edit or continue the painting, but not after.\n")

            + Text("· The canvas environment does not have an eraser or undo button, to simulate the mechanics of painting non-digitally. However, you can reset the canvas from the top-right button if needed.\n")

            + Text("· Notification settings can be customized from the home screen.\n\n")

            + Text("Distill and its developers ")
            + Text("do not collect any data from the user").bold()
            + Text(". All photos and paintings are kept on-device, and there is no user authentication - meaning you will lose your work if the app is uninstalled.")
        )
        .font(.body)
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity, alignment: .leading)

    }

}

#Preview {
    InfoPageView()
        .presentationDetents([.large])
}
