@preconcurrency import FeedKit
import Logging
import Payloads
import SwiftSoup
@preconcurrency import Vapor

public actor FeedFetcher {
    enum ContentType {
        case html
        case feed
    }
    
    private let client: any Client
    private let logger: Logger
    
    public init(client: any Client, logger: Logger) {
        self.client = client
        self.logger = logger
    }
    
    public func fetch(url: URL) async throws -> Payloads.Feed {
        let (data, contentType) = try await fetchDataAndContentType(url: url)
        do {
            let feed = try await {
                switch contentType {
                case .html:
                    let feedURL = try extractFeedURL(data: data).insertBaseURLIfNeeded(referenceURL: url)
                    let (feedData, feedContentType) = try await fetchDataAndContentType(url: feedURL)
                    guard feedContentType == .feed else { throw NSError(domain: "FeedFetcher", code: -4) }
                    let rawFeed = try await FeedParser(data: feedData).parseFeed()
                    var feed = rawFeed.convert(url: feedURL)
                    if feed.imageURL == nil {
                        feed.imageURL = await imageURL(of: feed, htmlData: data)
                    }
                    return feed
                case .feed:
                    let rawFeed = try await FeedParser(data: data).parseFeed()
                    var feed = rawFeed.convert(url: url)
                    if feed.imageURL == nil {
                        feed.imageURL = await imageURL(of: feed, htmlData: nil)
                    }
                    return feed
                }
            }()
            logger.debug("fetched feed from \(url): \(feed.title), \(feed.entries.count) entries (latest: '\(String(describing: feed.entries.first?.title))')")
            return feed
        } catch {
            logger.warning("failed to fetch feed \(url): \(error)")
            throw error
        }
    }
    
    private func fetchDataAndContentType(url: URL) async throws -> (Data, ContentType) {
        let response = try await client.get(.init(string: url.absoluteString))
        guard response.status == .ok,
              let responseBody = response.body,
              let responseData = responseBody.getData(at: responseBody.readerIndex, length: responseBody.readableBytes),
              let headerContentType = response.headers.contentType else {
            throw NSError(domain: "FeedFetcher", code: -1)
        }
        
        let contentType: ContentType = try {
            if headerContentType == .html {
                return .html
            } else if headerContentType == .xml || headerContentType == .json || headerContentType.subType == "rss+xml" {
                return .feed
            } else {
                let string = String(buffer: responseBody)
                if string.hasPrefix("<!DOCTYPE html") || string.hasPrefix("<html") {
                    return .html
                } else if string.hasPrefix("<?xml") || string.hasPrefix("<rss") || string.hasPrefix("<feed") || string.hasPrefix("{") {
                    return .feed
                } else {
                    throw NSError(domain: "FeedFetcher", code: -2, userInfo: [
                        NSLocalizedDescriptionKey: "Failed to determine content type from response",
                    ])
                }
            }
        }()
        
        return (responseData, contentType)
    }
    
    private func extractFeedURL(data: Data) throws -> URL {
        let html = try SwiftSoup.parse(String(decoding: data, as: UTF8.self))
        let links = try html.select("link[rel=alternate][type=application/rss+xml], link[rel=alternate][type=application/atom+xml]")
        guard let link = try links.compactMap({ try URL(string: $0.attr("href")) }).first else {
            throw NSError(domain: "FeedFetcher", code: -3, userInfo: [
                NSLocalizedDescriptionKey: "Cannot find feed URL",
            ])
        }
        return link
    }
    
    private func extractFaviconURL(data: Data, feed: Payloads.Feed) throws -> URL? {
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
    
    private func imageURL(of feed: Payloads.Feed, htmlData: Data?) async -> URL? {
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
                logger.warning("failed to fetch favicon: \(error)")
            }
            return await defaultURLOrNil(originalURL: pageURL)
        }
    }
    
    private func defaultFaviconURL(url: URL) -> URL? {
        guard var faviconURLComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        faviconURLComponents.path = "/favicon.ico"
        faviconURLComponents.query = nil
        faviconURLComponents.fragment = nil
        return faviconURLComponents.url
    }
    
    private func isResponseOK(url: URL) async -> Bool {
        do {
            let response = try await client.get(.init(string: url.absoluteString))
            return response.status == .ok
        } catch {
            return false
        }
    }
}
