import Foundation

public struct Feed: Codable, Sendable {
    public let url: URL
    public let title: String
    public let pageURL: URL?
    public let overview: String?
    public var imageURL: URL?
    
    public var entries: [Entry]
    
    public init(url: URL, title: String, pageURL: URL?, overview: String?, imageURL: URL? = nil, entries: [Entry]) {
        self.url = url
        self.title = title
        self.pageURL = pageURL
        self.overview = overview
        self.imageURL = imageURL
        self.entries = entries
    }
}

public struct Entry: Codable, Sendable {
    public let url: URL
    public let title: String
    public let publishedAt: Date
    public let content: String?
    
    public init(url: URL, title: String, publishedAt: Date, content: String?) {
        self.url = url
        self.title = title
        self.publishedAt = publishedAt
        self.content = content
    }
}
