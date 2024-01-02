import Foundation
import SwiftData

@Model
public final class FeedModel {
    public let url: String = ""
    public let title: String = ""
    public let overview: String? = nil
    public let imageURL: String? = nil
    
    @Relationship(deleteRule: .cascade)
    public var entries: [EntryModel]?
    
    public init(url: String, title: String, overview: String?, imageURL: String?) {
        self.url = url
        self.title = title
        self.overview = overview
        self.imageURL = imageURL
    }
    
    public var unreadCount: Int {
        entries?.filter { $0.read == false }.count ?? 0
    }
}

@Model
public final class EntryModel {
    public let url: String = ""
    public let title: String = ""
    public let publishedAt: Date = Date.now
    public let content: String? = nil
    public var read: Bool = false
    
    @Relationship
    public var feed: FeedModel?
    
    public init(url: String, title: String, publishedAt: Date, content: String?) {
        self.url = url
        self.title = title
        self.publishedAt = publishedAt
        self.content = content
    }
}
