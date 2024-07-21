import Foundation

public struct FeedsRequestBody: Codable {
    public let urls: [String]
    public let forceRefresh: Bool

    public init(urls: [String], forceRefresh: Bool = false) {
        self.urls = urls
        self.forceRefresh = forceRefresh
    }
}


public struct FeedsResponseBody: Codable {
    public let feeds: [String: Feed]
    
    public init(feeds: [String: Feed]) {
        self.feeds = feeds
    }
}
