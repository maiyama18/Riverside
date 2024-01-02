import Dependencies
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
            } else if contentTypeString.contains("application") && contentTypeString.contains(#/(xml|json)/#) {
                .feed
            } else {
                throw NSError(domain: "FeedClient", code: -2)
            }
            
            return (data, contentType)
        }
        
        @Sendable
        func extractFeedURL(data: Data) throws -> URL {
            let html = try SwiftSoup.parse(String(decoding: data, as: UTF8.self))
            let links = try html.select("link[rel=alternate][type=application/rss+xml], link[rel=alternate][type=application/atom+xml]")
            guard let link = try links.compactMap({ try URL(string: $0.attr("href")) }).first else {
                throw NSError(domain: "FeedClient", code: -3)
            }
            return link
        }
        
        @Sendable
        func extractFaviconURL(data: Data, feed: Feed) throws -> URL? {
            let html = try SwiftSoup.parse(String(decoding: data, as: UTF8.self))
            let links = try html.select(#"link[rel="icon"], link[rel="shortcut icon"]"#)
            guard let faviconURL = try links.compactMap({ try URL(string: $0.attr("href")) }).filter({ !$0.absoluteString.contains("svg") }).first else {
                return nil
            }
            if faviconURL.scheme != nil {
                return faviconURL
            } else {
                if faviconURL.absoluteString.hasPrefix("/"),
                   let baseURL = feed.pageURL?.baseURL() ?? feed.url.baseURL() {
                    guard var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
                        return defaultFaviconURL(url: baseURL)
                    }
                    urlComponents.path = faviconURL.absoluteString
                    return urlComponents.url ?? defaultFaviconURL(url: baseURL)
                } else {
                    return defaultFaviconURL(url: feed.pageURL ?? feed.url)
                }
            }
        }
        
        @Sendable
        func imageURL(of feed: Feed, htmlData: Data?) async -> URL? {
            if let htmlData {
                if let imageURL = try? extractFaviconURL(data: htmlData, feed: feed) {
                    return imageURL
                }
                guard let pageURL = feed.pageURL else { return nil }
                return defaultFaviconURL(url: pageURL)
            } else {
                guard let pageURL = feed.pageURL else { return nil }
                do {
                    let (htmlData, _) = try await fetchDataAndContentType(url: pageURL)
                    if let imageURL = try? extractFaviconURL(data: htmlData, feed: feed) {
                        return imageURL
                    }
                } catch {
                    print(error)
                }
                return defaultFaviconURL(url: pageURL)
            }
        }
        
        @Sendable
        func defaultFaviconURL(url: URL) -> URL? {
            guard var faviconURLComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                return nil
            }
            faviconURLComponents.path = "/favicon.ico"
            faviconURLComponents.query = nil
            faviconURLComponents.fragment = nil
            return faviconURLComponents.url
        }
        
        return FeedClient(
            fetch: { url in
                let (data, contentType) = try await fetchDataAndContentType(url: url)
                switch contentType {
                case .html:
                    let feedURL = try extractFeedURL(data: data)
                    let (feedData, feedContentType) = try await fetchDataAndContentType(url: feedURL)
                    guard feedContentType == .feed else { throw NSError(domain: "FeedClient", code: -4) }
                    let rawFeed = try await FeedParser(data: feedData).parseFeed()
                    var feed = rawFeed.convert(url: feedURL)
                    if feed.imageURL != nil {
                        return feed
                    } else {
                        feed.imageURL = await imageURL(of: feed, htmlData: data)
                        return feed
                    }
                case .feed:
                    let rawFeed = try await FeedParser(data: data).parseFeed()
                    var feed = rawFeed.convert(url: url)
                    if feed.imageURL != nil {
                        return feed
                    } else {
                        feed.imageURL = await imageURL(of: feed, htmlData: nil)
                        return feed
                    }
                }
            }
        )
    }
}

public extension DependencyValues {
    var feedClient: FeedClient {
        get { self[FeedClientKey.self] }
        set { self[FeedClientKey.self] = newValue }
    }
}

private enum FeedClientKey: DependencyKey {
    static let liveValue: FeedClient = .live(urlSession: .shared)
}
