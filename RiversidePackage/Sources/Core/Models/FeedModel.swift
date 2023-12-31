import Foundation
import SwiftData

@Model
public final class FeedModel {
    public let url: String = ""
    public let title: String = ""
    public let overview: String? = nil
    
    @Relationship
    public var entries: [EntryModel] = []
    
    public init(url: String, title: String, overview: String?) {
        self.url = url
        self.title = title
        self.overview = overview
    }
}

@Model
public final class EntryModel {
    public let url: String = ""
    public let title: String = ""
    public let publishedAt: Date = Date.now
    public let content: String? = nil
    
    @Relationship
    public var feed: FeedModel?
    
    public init(url: String, title: String, publishedAt: Date, content: String?) {
        self.url = url
        self.title = title
        self.publishedAt = publishedAt
        self.content = content
    }
}
