import SwiftUI
import SubscribeFeedFeature

struct SubscribeFeedButton<Label: View>: View {
    let label: () -> Label
    
    @State private var isPresented: Bool = false
    
    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            label()
        }
        .popover(isPresented: $isPresented) {
            SubscribeFeedScreen()
        }
    }
}
