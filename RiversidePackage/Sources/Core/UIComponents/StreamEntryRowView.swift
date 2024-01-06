import Models
import SwiftUI

@MainActor
public struct StreamEntryRowView: View {
    private let entry: EntryModel
    private let onFeedTapped: (FeedModel) -> Void
    
    public init(entry: EntryModel, onFeedTapped: @escaping (FeedModel) -> Void) {
        self.entry = entry
        self.onFeedTapped = onFeedTapped
    }
    
    public var body: some View {
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
