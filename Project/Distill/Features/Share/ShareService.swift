import SwiftUI
import UIKit

struct ShareService {

    func share(_ image: UIImage) {

        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )

        guard let windowScene = UIApplication.shared.connectedScenes
            .first as? UIWindowScene,
              let root = windowScene.windows.first?.rootViewController
        else {
            return
        }

        var topController = root
        while let presented = topController.presentedViewController {
            topController = presented
        }

        if UIDevice.current.userInterfaceIdiom == .pad {
            activityVC.popoverPresentationController?.sourceView = topController.view
            activityVC.popoverPresentationController?.sourceRect = CGRect(
                x: topController.view.bounds.midX,
                y: topController.view.bounds.midY,
                width: 0,
                height: 0
            )
        }

        topController.present(activityVC, animated: true)

    }

}
