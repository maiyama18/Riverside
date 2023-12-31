import Models
import SwiftUI

@MainActor
struct EntryRowView: View {
    let entry: EntryModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.publishedAt.formatted(date: .numeric, time: .omitted))
                .font(.footnote.monospacedDigit())
            
            Text(entry.title)
                .bold()
                .lineLimit(2)
            
            if let content = entry.content {
                Text(content)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
        .foregroundStyle(entry.read ? .secondary : .primary)
    }
}
