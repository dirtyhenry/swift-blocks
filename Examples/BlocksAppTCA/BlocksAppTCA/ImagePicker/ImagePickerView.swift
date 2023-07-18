import ComposableArchitecture
import SwiftUI
import UniformTypeIdentifiers

struct ImagePickerView: UIViewControllerRepresentable {
    let viewStore: ViewStoreOf<ImagePickerFeature>

    let sourceType: UIImagePickerController.SourceType
    let mediaTypes: [String]

    init(
        store: StoreOf<ImagePickerFeature>,
        sourceType: UIImagePickerController.SourceType,
        mediaTypes: [String]
    ) {
        viewStore = ViewStore(store, observe: { $0 })
        self.sourceType = sourceType
        self.mediaTypes = mediaTypes
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.mediaTypes = mediaTypes
        return picker
    }

    func updateUIViewController(_: UIImagePickerController, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(viewStore: viewStore)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let viewStore: ViewStoreOf<ImagePickerFeature>

        init(viewStore: ViewStoreOf<ImagePickerFeature>) {
            self.viewStore = viewStore
        }

        func imagePickerController(_: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            guard let image = info[.originalImage] as? UIImage else {
                return
            }
            print("imagePickerControllerDidFinishPickingMediaWithInfo: \(Thread.isMainThread)")
            viewStore.send(.usePhotoButtonTapped(image))
        }

        func imagePickerControllerDidCancel(_: UIImagePickerController) {
            print("imagePickerControllerDidCancel: \(Thread.isMainThread)")
            viewStore.send(.cancelButtonTapped)
        }
    }
}

struct ImagePickerView_Previews: PreviewProvider {
    static var previews: some View {
        ImagePickerView(
            store: Store(
                initialState: ImagePickerFeature.State(),
                reducer: ImagePickerFeature()
            ),
            sourceType: .camera,
            mediaTypes: [UTType.image.identifier]
        )
    }
}
