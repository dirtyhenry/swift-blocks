import Blocks
import ComposableArchitecture
import SwiftUI
import UniformTypeIdentifiers

struct RootView: View {
    let store: StoreOf<RootFeature>

    var body: some View {
        NavigationStack {
            WithViewStore(store, observe: { $0 }) { viewStore in
                if viewStore.latestPhoto == nil {
                    Button("Take Photo \(viewStore.count)") {
                        viewStore.send(.takePhotoButtonTapped)
                    }
                    Button("Increment \(viewStore.count)") {
                        viewStore.send(.incrementButtonTapped)
                    }
                } else {
                    VStack {
                        Image(uiImage: viewStore.latestPhoto!)
                        Button("Retake Photo") {
                            viewStore.send(.takePhotoButtonTapped)
                        }
                    }
                }
            }
        }
        .sheet(
            store: store.scope(
                state: \.$takePhoto,
                action: { .usePhoto($0) }
            )) { takePhotoStore in
                NavigationStack {
                    ImagePickerView(
                        store: takePhotoStore,
                        sourceType: .camera,
                        mediaTypes: [UTType.image.identifier]
                    )
                }
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView(store: Store(
            initialState: RootFeature.State(count: 1),
            reducer: RootFeature()
        ))
    }
}
