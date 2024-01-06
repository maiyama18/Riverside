import Models
import SwiftUI

@MainActor
public struct FeedEntryRowView: View {
    private let entry: EntryModel
    
    public init(entry: EntryModel) {
        self.entry = entry
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.publishedAt.formatted(date: .numeric, time: .omitted))
                .font(.footnote.monospacedDigit())
            
            Text(entry.title)
                .bold()
                .lineLimit(2)
            
            if let content = entry.content, !content.isEmpty {
                Text(content)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
        .foregroundStyle(entry.read ? .secondary : .primary)
    }
}
