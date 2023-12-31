import Models
import SwiftUI

@MainActor
struct FeedRowView: View {
    let feed: FeedModel
    
    var body: some View {
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
        .badge(feed.unreadCount)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    FeedRowView(feed: .init(url: "https://example.com", title: "Sample Feed", overview: nil))
}
