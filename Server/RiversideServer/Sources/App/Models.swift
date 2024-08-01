import Foundation
import Fluent
import Payloads

final class Feed: Model {
    static let schema = "feeds"

    @ID(key: .id) var id: UUID?

    @Field(key: "url") var url: String
    @Field(key: "title") var title: String
    @OptionalField(key: "page_url") var pageURL: String?
    @OptionalField(key: "overview") var overview: String?
    @OptionalField(key: "image_url") var imageURL: String?
    @Field(key: "updated_at") var updatedAt: Date
    
    @Children(for: \.$feed)
    var entries: [Entry]
    
    init(id: UUID? = nil, url: String, title: String, pageURL: String? = nil, overview: String? = nil, imageURL: String? = nil) {
        self.id = id
        self.url = url
        self.title = title
        self.pageURL = pageURL
        self.overview = overview
        self.imageURL = imageURL
        self.updatedAt = .now
    }
    
    convenience init(feed: Payloads.Feed) {
        self.init(
            url: feed.url.absoluteString,
            title: feed.title,
            pageURL: feed.pageURL?.absoluteString,
            overview: feed.overview,
            imageURL: feed.imageURL?.absoluteString
        )
    }
    
    init() {}
    
    func updatedWithin(timeInterval: TimeInterval) -> Bool {
        Date.now.timeIntervalSince(updatedAt) < timeInterval
    }
    
    func feedPayload() -> Payloads.Feed {
        return .init(
            url: URL(string: url)!,
            title: title,
            pageURL: pageURL.flatMap { URL(string: $0) },
            overview: overview,
            entries: entries.compactMap { $0.entryPayload() }
        )
    }
}

final class Entry: Model {
    static let schema = "entries"
    
    @ID(key: .id) var id: UUID?
    
    @Field(key: "url") var url: String
    @Field(key: "title") var title: String
    @Field(key: "published_at") var publishedAt: Date
    @OptionalField(key: "content") var content: String?
    
    @Parent(key: "feed_id")
    var feed: Feed
    
    init(id: UUID? = nil, url: String, title: String, publishedAt: Date, content: String?, feedID: Feed.IDValue) {
        self.id = id
        self.url = url
        self.title = title
        self.publishedAt = publishedAt
        self.content = content
        self.$feed.id = feedID
    }
    
    convenience init(entry: Payloads.Entry, feedID: Feed.IDValue) {
        self.init(
            url: entry.url.absoluteString,
            title: entry.title,
            publishedAt: entry.publishedAt,
            content: entry.content,
            feedID: feedID
        )
    }
    
    init() {}
    
    func entryPayload() -> Payloads.Entry {
        return .init(
            url: URL(string: url)!,
            title: title,
            publishedAt: publishedAt,
            content: content
        )
    }
}
