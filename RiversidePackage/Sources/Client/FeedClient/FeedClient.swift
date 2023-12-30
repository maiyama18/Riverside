import FeedKit
import Foundation
import SwiftSoup

public struct FeedClient: Sendable {
    public var fetch: @Sendable (_ url: URL) async throws -> Feed
}

extension FeedClient {
    static func live(urlSession: URLSession) -> FeedClient {
        enum ContentType {
            case html
            case feed
        }
        
        @Sendable
        func fetchDataAndContentType(url: URL) async throws -> (Data, ContentType) {
            let (data, response) = try await urlSession.data(from: url)
            guard let response = response as? HTTPURLResponse,
                  response.statusCode == 200,
                  let contentTypeString = response.allHeaderFields["Content-Type"] as? String else {
                throw NSError(domain: "FeedClient", code: -1)
            }
            
            let contentType: ContentType = if contentTypeString.contains("text/html") {
                .html
            } else if contentTypeString.contains("application/rss+xml") || contentTypeString.contains("application/json") {
                .feed
            } else {
                throw NSError(domain: "FeedClient", code: -2)
            }
            
            return (data, contentType)
        }
        
        @Sendable
        func extractFeedURL(data: Data) async throws -> URL {
            let html = try SwiftSoup.parse(String(decoding: data, as: UTF8.self))
            let links = try html.select("link[rel=alternate][type=application/rss+xml], link[rel=alternate][type=application/atom+xml]")
            guard let link = try links.compactMap({ try URL(string: $0.attr("href")) }).first else {
                throw NSError(domain: "FeedClient", code: -3)
            }
            return link
        }
        
        return FeedClient(
            fetch: { url in
                let (data, contentType) = try await fetchDataAndContentType(url: url)
                switch contentType {
                case .html:
                    let feedURL = try await extractFeedURL(data: data)
                    let (data, contentType) = try await fetchDataAndContentType(url: feedURL)
                    guard contentType == .feed else { throw NSError(domain: "FeedClient", code: -4) }
                    let feed = try await FeedParser(data: data).parseFeed()
                    return feed.convert(url: url)
                case .feed:
                    let feed = try await FeedParser(data: data).parseFeed()
                    return feed.convert(url: url)
                }
            }
        )
    }
}
