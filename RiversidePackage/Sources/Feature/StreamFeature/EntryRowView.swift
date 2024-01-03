import Models
import SwiftUI

@MainActor
struct EntryRowView: View {
    let entry: EntryModel
    let onFeedTapped: (FeedModel) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                if let imageURLString = entry.feed?.imageURL,
                   let imageURL = URL(string: imageURLString) {
                    AsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                    } placeholder: {
                        Color.gray.opacity(0.3)
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                    }
                }
                
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
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            if let content = entry.content {
                Text(content)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
        .foregroundStyle(entry.read ? .secondary : .primary)
    }
}
