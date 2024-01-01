import Foundation
import Models

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
    public let entries: [Entry]
}

public extension Feed {
    func toModel() -> (FeedModel, [EntryModel]) {
        let feedModel = FeedModel(url: url.absoluteString, title: title, overview: overview, imageURL: imageURL?.absoluteString)
        let entryModels = entries.map { EntryModel(url: $0.url.absoluteString, title: $0.title, publishedAt: $0.publishedAt, content: $0.content) }
        return (feedModel, entryModels)
    }
}
