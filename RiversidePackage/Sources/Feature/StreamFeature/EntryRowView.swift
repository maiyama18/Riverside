import Models
import SwiftUI

struct EntryRowView: View {
    let entry: EntryModel
    let onFeedTapped: (FeedModel) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.title)
                .bold()
                .lineLimit(2)
            
            if let feed = entry.feed {
                Button {
                    onFeedTapped(feed)
                } label: {
                    Text(feed.title)
                        .font(.footnote)
                        .underline(true)
                }
                .tint(.secondary)
            }
            
            if let content = entry.content {
                Text(content)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }
}
