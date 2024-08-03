import Foundation

public struct FeedsRequestBody: Codable, Sendable {
    public let urls: [String]
    public let forceRefresh: Bool

    public init(urls: [String], forceRefresh: Bool = false) {
        self.urls = urls
        self.forceRefresh = forceRefresh
    }
}


public struct FeedsResponseBody: Codable, Sendable {
    public struct FeedResult: Codable, Sendable {
        public var feed: Feed?
        public var error: String?
        
        public init(feed: Feed? = nil, error: String? = nil) {
            self.feed = feed
            self.error = error
        }
    }
    
    public let feeds: [String: FeedResult]
    
    public init(feeds: [String: FeedResult]) {
        self.feeds = feeds
    }
}

extension FeedsResponseBody: CustomDebugStringConvertible {
    public var debugDescription: String {
        feeds.map { url, result in
            if let feed = result.feed {
                "\(url): \(feed.title) (\(feed.entries.count) entries)"
            } else {
                "\(url): error \(result.error ?? "")"
            }
        }.joined(separator: ",")
    }
}
