import Blocks
import ComposableArchitecture
import SwiftUI
import UniformTypeIdentifiers

struct RootView: View {
    let store: StoreOf<RootFeature>
    @ObservedObject var viewStore: ViewStoreOf<RootFeature>

    init(store: StoreOf<RootFeature>) {
        self.store = store
        viewStore = ViewStore(self.store, observe: { $0 })
    }

    var body: some View {
        NavigationStack {
            if viewStore.latestPhoto == nil {
                VStack(spacing: 32) {
                    Button("Take Photo") {
                        viewStore.send(.takePhotoButtonTapped)
                    }

                    switch viewStore.status {
                    case .notDetermined:
                        Text("Access not determined")
                    case .authorized:
                        Text("Access authorized")
                    case .denied:
                        Text("Access denied")
                    case .restricted:
                        Text("Access restricted")
                    @unknown default:
                        Text("Unknown status")
                    }
                }
            } else {
                VStack {
                    Image(uiImage: viewStore.latestPhoto!)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 200)
                    Button("Retake Photo") {
                        viewStore.send(.takePhotoButtonTapped)
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
                    ImagePickerView(store: takePhotoStore)
                }
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView(store: Store(
            initialState: RootFeature.State(),
            reducer: RootFeature()
        ))
    }
}
