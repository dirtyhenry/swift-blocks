#if os(iOS) || os(tvOS)
import SwiftUI

/// A basic SwiftUI wrapper for UIKit's `UIImagePickerController`.
struct ImagePickerView: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let mediaTypes: [String]

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.mediaTypes = mediaTypes
        return picker
    }

    func updateUIViewController(_: UIImagePickerController, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(view: self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let view: ImagePickerView

        init(view: ImagePickerView) {
            self.view = view
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo _: [UIImagePickerController.InfoKey: Any]) {
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
#endif
