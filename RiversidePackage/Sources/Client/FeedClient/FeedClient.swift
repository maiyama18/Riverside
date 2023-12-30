import FeedKit
import Foundation

public struct FeedClient: Sendable {
    public var fetch: @Sendable (_ url: URL) async throws -> Feed
}

extension FeedClient {
    static func live(urlSession: URLSession) -> FeedClient {
        FeedClient { url in
            let (data, response) = try await urlSession.data(from: url)
            guard let response = response as? HTTPURLResponse,
                  response.statusCode == 200 else {
                throw NSError(domain: "FeedClient", code: -1)
            }
            let feed = try await FeedParser(data: data).parseFeed()
            return feed.convert(url: url)
        }
    }
}
