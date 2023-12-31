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
        // TODO: show unreads count only
        .badge(feed.entries?.count ?? 0)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    FeedRowView(feed: .init(url: "https://example.com", title: "Sample Feed", overview: nil))
}
