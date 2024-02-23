import SwiftUI
import WidgetKit

struct WidgetView: View {
    let entry: Provider.Entry
    
    var body: some View {
        Text("Hello, World!")
            .containerBackground(for: .widget) {
                Color.red
            }
    }
}
