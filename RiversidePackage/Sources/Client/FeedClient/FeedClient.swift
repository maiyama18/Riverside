import Dependencies
import FeedKit
import Foundation
import SwiftSoup
import Utilities

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
            
            let contentType: ContentType = try {
                if contentTypeString.contains("html") {
                    return .html
                } else if contentTypeString.contains(#/(xml|json)/#) {
                    return .feed
                } else {
                    let string = String(decoding: data, as: UTF8.self).lowercased()
                    if string.hasPrefix("<!DOCTYPE html") || string.hasPrefix("<html") {
                        return .html
                    } else if string.hasPrefix("<?xml") || string.hasPrefix("<rss") || string.hasPrefix("{") {
                        return .feed
                    } else {
                        throw NSError(domain: "FeedClient", code: -2, userInfo: [
                            NSLocalizedDescriptionKey: "Failed to determine content type from response",
                        ])
                    }
                }
            }()
            
            return (data, contentType)
        }
        
        @Sendable
        func extractFeedURL(data: Data) throws -> URL {
            let html = try SwiftSoup.parse(String(decoding: data, as: UTF8.self))
            let links = try html.select("link[rel=alternate][type=application/rss+xml], link[rel=alternate][type=application/atom+xml]")
            guard let link = try links.compactMap({ try URL(string: $0.attr("href")) }).first else {
                throw NSError(domain: "FeedClient", code: -3, userInfo: [
                    NSLocalizedDescriptionKey: "Cannot find feed URL",
                ])
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
                return faviconURL.insertBaseURLIfNeeded(referenceURL: feed.pageURL ?? feed.url)
            }
        }
        
        @Sendable
        func imageURL(of feed: Feed, htmlData: Data?) async -> URL? {
            func defaultURLOrNil(originalURL: URL) async -> URL? {
                guard let defaultURL = defaultFaviconURL(url: originalURL),
                      defaultURL.isValid() else {
                    return nil
                }
                
                return await isResponseOK(url: defaultURL) ? defaultURL : nil
            }
            
            if let htmlData {
                if let imageURL = try? extractFaviconURL(data: htmlData, feed: feed),
                   imageURL.isValid(),
                   await isResponseOK(url: imageURL) {
                    return imageURL
                }
                guard let pageURL = feed.pageURL else { return nil }
                return await defaultURLOrNil(originalURL: pageURL)
            } else {
                guard let pageURL = feed.pageURL else { return nil }
                do {
                    let (htmlData, _) = try await fetchDataAndContentType(url: pageURL)
                    if let imageURL = try? extractFaviconURL(data: htmlData, feed: feed),
                       imageURL.isValid() {
                        return imageURL
                    }
                } catch {
                    print(error)
                }
                return await defaultURLOrNil(originalURL: pageURL)
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
        
        @Sendable
        func isResponseOK(url: URL) async -> Bool {
            do {
                let (_, response) = try await urlSession.data(from: url)
                if let response = response as? HTTPURLResponse,
                   response.statusCode == 200 {
                    return true
                } else {
                    return false
                }
            } catch {
                return false
            }
        }
        
        return FeedClient(
            fetch: { url in
                let (data, contentType) = try await fetchDataAndContentType(url: url)
                switch contentType {
                case .html:
                    let feedURL = try extractFeedURL(data: data).insertBaseURLIfNeeded(referenceURL: url)
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
