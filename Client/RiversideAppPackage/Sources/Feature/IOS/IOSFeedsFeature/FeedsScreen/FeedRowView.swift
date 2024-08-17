import Entities
import SwiftUI
import UIComponents

@MainActor
struct FeedRowView: View {
    let feed: FeedModel
    let unreadCount: Int
    
    var body: some View {
        HStack {
            if let imageURL = feed.imageURL {
                FeedImage(url: imageURL, size: 44)
            } else {
                FeedImage.default(size: 44)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(feed.title ?? "")
                    .bold()
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    if let host = feed.url?.host() {
                        Text(host)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .badge(unreadCount)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
