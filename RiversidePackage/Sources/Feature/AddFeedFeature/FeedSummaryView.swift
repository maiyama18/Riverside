import FeedClient
import SwiftUI

struct FeedSummaryView: View {
    let feed: Feed
    let feedAlreadyAdded: Bool
    let onAddTapped: () -> Void
    
    var body: some View {
        HStack(alignment: .top) {
            if let imageURL = feed.imageURL {
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
            }
            
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    VStack(alignment: .leading, spacing: 0) {
                        if let host = feed.url.host() {
                            Text(host)
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                        
                        Text(feed.title)
                            .bold()
                    }
                    
                    if let overview = feed.overview, !overview.isEmpty {
                        Text(overview)
                            .font(.caption)
                            .lineLimit(5)
                    }
                    
                    Text("\(feed.entries.count) entries")
                        .font(.footnote)
                        .foregroundStyle(.teal)
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Button {
                    onAddTapped()
                } label: {
                    if feedAlreadyAdded {
                        Text("Already added")
                            .font(.caption)
                    } else {
                        Image(systemName: "plus")
                            .padding(.vertical, 8)
                            .padding(.leading, 8)
                    }
                }
                .disabled(feedAlreadyAdded)
            }
        }
    }
}

#Preview {
    List {
        ForEach(
            [
                Feed.PreviewContents.maiyama4,
                Feed.PreviewContents.jessesquires,
                Feed.PreviewContents.phaNote,
            ],
            id: \.url
        ) { feed in
            Section {
                FeedSummaryView(
                    feed: feed,
                    feedAlreadyAdded: false,
                    onAddTapped: {}
                )
            }
        }
    }
}