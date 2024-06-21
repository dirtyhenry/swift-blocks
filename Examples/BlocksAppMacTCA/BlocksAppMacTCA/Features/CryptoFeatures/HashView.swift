import Blocks
import ComposableArchitecture
import SwiftUI

struct HashView: View {
    let store: StoreOf<HashFeature>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { _ in
            Text("TODO")
        }
    }
}

struct HashView_Previews: PreviewProvider {
    static var previews: some View {
        HashView(store: Store(
            initialState: HashFeature.State(myVar1: true, myVar2: false)
        ) {
            HashFeature()
        })
    }
}
