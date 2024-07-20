import CoreData
import Foundation
import Entities

public struct Feed: Sendable {
    public struct Entry: Sendable {
        public let url: URL
        public let title: String
        public let publishedAt: Date
        public let content: String?
    }

    public let url: URL
    public let pageURL: URL?
    public let title: String
    public let overview: String?
    public var imageURL: URL?
    public var entries: [Entry]
}

public extension Feed {
    func toModel(context: NSManagedObjectContext) -> (FeedModel, [EntryModel]) {
        let feedModel = FeedModel(context: context)
        feedModel.url = url
        feedModel.title = title
        feedModel.overview = overview
        feedModel.imageURL = imageURL
        
        let entryModels = entries
            .sorted(by: { $0.publishedAt > $1.publishedAt })
            .map { $0.toModel(context: context) }
        
        return (feedModel, entryModels)
    }
}

public extension Feed.Entry {
    func toModel(context: NSManagedObjectContext) -> EntryModel {
        let model = EntryModel(context: context)
        model.url = url
        model.title = title
        model.publishedAt = publishedAt
        model.content = content
        return model
    }
}

extension Feed {
    public enum PreviewContents {
        public static let maiyama4: Feed = Feed(
            url: URL(string: "https://maiyama4.hatenablog.com/rss")!,
            pageURL: URL(string: "https://maiyama4.hatenablog.com/")!,
            title: "maiyama log",
            overview: nil,
            imageURL: URL(string: "https://maiyama4.hatenablog.com/icon/favicon")!,
            entries: Array(repeating: Feed.Entry.PreviewContents.random(), count: 4)
        )
        
        public static let jessesquires: Feed = Feed(
            url: URL(string: "https://www.jessesquires.com/feed.xml")!,
            pageURL: URL(string: "https://www.jessesquires.com")!,
            title: "Jesse Squires",
            overview: "Turing complete with a stack of 0xdeadbeef",
            imageURL: URL(string: "https://www.jessesquires.com/img/logo.png")!,
            entries: Array(repeating: Feed.Entry.PreviewContents.random(), count: 10)
        )
        
        public static let phaNote: Feed = Feed(
            url: URL(string: "https://note.com/pha/rss")!,
            pageURL: URL(string: "https://note.com/pha")!,
            title: "pha",
            overview: "毎日寝て暮らしたい。読んだ本の感想やだらだらした日常のことを書いている日記です。毎回最初の1日分は無料で読めるようにしています。雑誌などに書いた文章もここに載せたりします。",
            imageURL: URL(string: "https://assets.st-note.com/poc-image/manual/note-common-images/production/svg/production.ico")!,
            entries: Array(repeating: Feed.Entry.PreviewContents.random(), count: 15)
        )
    }
}

extension Feed.Entry {
    public enum PreviewContents {
        public static func random() -> Feed.Entry {
            .init(
                url: URL(string: "https://example.com/" + UUID().uuidString)!,
                title: "Title",
                publishedAt: .now,
                content: nil
            )
        }
    }
}
