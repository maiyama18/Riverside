import Models
import SwiftUI

@MainActor
struct FeedRowView: View {
    let feed: FeedModel
    
    var body: some View {
        HStack {
            if let imageURLString = feed.imageURL, let imageURL = URL(string: imageURLString) {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } placeholder: {
                    Color.gray.opacity(0.3)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                }
            } else {
                Image(systemName: "newspaper.circle.fill")
                    .resizable()
                    .foregroundStyle(.secondary)
                    .frame(width: 40, height: 40)
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
