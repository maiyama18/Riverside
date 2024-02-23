import SwiftUI
import WidgetKit

struct WidgetView: View {
    let entry: Provider.Entry
    
    var body: some View {
        VStack {
            Image(.logo)
                .resizable()
                .frame(width: 24, height: 24)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        }
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}
