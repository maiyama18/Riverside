import Models
import SwiftUI
import UIComponents

@MainActor
struct EntryRowView: View {
    let entry: EntryModel
    let onFeedTapped: (FeedModel) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                if let imageURLString = entry.feed?.imageURL {
                    FeedImage(url: URL(string: imageURLString), size: 32)
                } else {
                    FeedImage.default(size: 32)
                }
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(entry.title)
                        .bold()
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if let feed = entry.feed {
                        Button {
                            onFeedTapped(feed)
                        } label: {
                            Text(feed.title)
                                .font(.footnote)
                                .underline(true)
                                .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
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
