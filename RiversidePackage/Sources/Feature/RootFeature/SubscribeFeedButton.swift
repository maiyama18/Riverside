import SwiftUI
import SubscribeFeedFeature

struct SubscribeFeedButton: View {
    @State private var isPresented: Bool = false
    
    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            Image(systemName: "plus")
        }
        .popover(isPresented: $isPresented) {
            SubscribeFeedScreen()
        }
    }
}
