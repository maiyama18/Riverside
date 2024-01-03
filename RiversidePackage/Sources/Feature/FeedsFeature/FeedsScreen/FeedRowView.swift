import Models
import SwiftUI
import UIComponents

@MainActor
struct FeedRowView: View {
    let feed: FeedModel
    
    var body: some View {
        HStack {
            if let imageURLString = feed.imageURL {
                FeedImage(url: URL(string: imageURLString), size: 44)
            } else {
                FeedImage.default(size: 44)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(feed.title)
                    .bold()
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    if let host = URL(string: feed.url)?.host() {
                        Text(host)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .badge(feed.unreadCount)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    FeedRowView(feed: .init(url: "https://example.com", title: "Sample Feed", overview: nil, imageURL: nil))
}
