import SwiftUI

@Observable
final class ShareService {

    var imageToShare: UIImage?

    var isShowingShareSheet = false

    func share(_ image: UIImage) {

        imageToShare = image
        isShowingShareSheet = true

    }

}
