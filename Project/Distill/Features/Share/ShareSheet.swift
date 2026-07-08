//
//  ShareSheet.swift
//  distill
//
//  Created by Vitha Watson on 08/07/26.
//


import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {

    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {

        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )

        controller.modalPresentationStyle = .pageSheet

        return controller
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) { }

}