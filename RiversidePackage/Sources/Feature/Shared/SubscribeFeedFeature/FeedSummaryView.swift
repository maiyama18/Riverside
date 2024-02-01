import FeedClient
import SwiftUI
import UIComponents

struct FeedSummaryView: View {
    let feed: Feed
    let feedAlreadySubscribed: Bool
    let onSubscribeTapped: () -> Void
    
    var body: some View {
        HStack(alignment: .top) {
            if let imageURL = feed.imageURL {
                FeedImage(url: imageURL, size: 44)
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
                    onSubscribeTapped()
                } label: {
                    if feedAlreadySubscribed {
                        Text("Already subscribed")
                            .font(.caption)
                    } else {
                        Image(systemName: "plus")
                            .padding(.vertical, 8)
                            .padding(.leading, 8)
                    }
                }
                .buttonStyle(.plain)
                .disabled(feedAlreadySubscribed)
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
                    feedAlreadySubscribed: false,
                    onSubscribeTapped: {}
                )
            }
        }
    }
}
