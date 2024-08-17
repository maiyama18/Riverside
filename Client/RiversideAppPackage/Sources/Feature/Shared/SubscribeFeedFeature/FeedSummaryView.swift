import FeedClient
import SwiftUI
import UIComponents
import Payloads

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

extension Feed {
    public enum PreviewContents {
        public static let maiyama4: Feed = Feed(
            url: URL(string: "https://maiyama4.hatenablog.com/rss")!,
            title: "maiyama log", pageURL: URL(string: "https://maiyama4.hatenablog.com/")!,
            overview: nil,
            imageURL: URL(string: "https://maiyama4.hatenablog.com/icon/favicon")!,
            entries: Array(repeating: Entry.PreviewContents.random(), count: 4)
        )
        
        public static let jessesquires: Feed = Feed(
            url: URL(string: "https://www.jessesquires.com/feed.xml")!,
            title: "Jesse Squires", pageURL: URL(string: "https://www.jessesquires.com")!,
            overview: "Turing complete with a stack of 0xdeadbeef",
            imageURL: URL(string: "https://www.jessesquires.com/img/logo.png")!,
            entries: Array(repeating: Entry.PreviewContents.random(), count: 10)
        )
        
        public static let phaNote: Feed = Feed(
            url: URL(string: "https://note.com/pha/rss")!,
            title: "pha", pageURL: URL(string: "https://note.com/pha")!,
            overview: "毎日寝て暮らしたい。読んだ本の感想やだらだらした日常のことを書いている日記です。毎回最初の1日分は無料で読めるようにしています。雑誌などに書いた文章もここに載せたりします。",
            imageURL: URL(string: "https://assets.st-note.com/poc-image/manual/note-common-images/production/svg/production.ico")!,
            entries: Array(repeating: Entry.PreviewContents.random(), count: 15)
        )
    }
}

extension Entry {
    public enum PreviewContents {
        public static func random() -> Entry {
            .init(
                url: URL(string: "https://example.com/" + UUID().uuidString)!,
                title: "Title",
                publishedAt: .now,
                content: nil
            )
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
