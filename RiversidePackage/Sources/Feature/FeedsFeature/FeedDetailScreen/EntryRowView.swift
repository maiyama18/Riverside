import Models
import SwiftUI

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
                    .lineSpacing(0)
                    .lineLimit(3)
            }
        }
    }
}
