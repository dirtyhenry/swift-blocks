import MessageUI
import SwiftUI

/// A basic SwiftUI wrapper for UIKit's `MFMailComposeViewController`.
struct MailComposeView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.delegate = context.coordinator
        return composer
    }

    func updateUIViewController(_: MFMailComposeViewController, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(view: self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, MFMailComposeViewControllerDelegate {
        let view: MailComposeView

        init(view: MailComposeView) {
            self.view = view
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith _: MFMailComposeResult, error _: Error?) {
            controller.dismiss(animated: true)
        }
    }
}
