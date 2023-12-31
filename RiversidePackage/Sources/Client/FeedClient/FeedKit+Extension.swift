import FeedKit
import Foundation

extension FeedParser {
    func parseFeed() async throws -> FeedKit.Feed {
        try await withCheckedThrowingContinuation { continuation in
            parseAsync { result in
                switch result {
                case .success(let feed):
                    continuation.resume(returning: feed)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

extension FeedKit.Feed {
    func convert(url: URL) -> Feed {
        switch self {
        case .rss(let rssFeed):
            Feed(
                url: url,
                title: rssFeed.title ?? "",
                overview: rssFeed.description ?? "",
                entries: rssFeed.items?.compactMap { item in
                    guard let urlString = item.link, let url = URL(string: urlString),
                          let publishedAt = item.pubDate else {
                        return nil
                    }
                    return Feed.Entry(
                        url: url,
                        title: item.title ?? url.absoluteString,
                        publishedAt: publishedAt,
                        content: sanitizeEntryContent(getLonger(item.content?.contentEncoded, item.description))
                    )
                } ?? []
            )
        case .atom(let atomFeed):
            Feed(
                url: url,
                title: atomFeed.title ?? "",
                overview: atomFeed.subtitle?.value ?? "",
                entries: atomFeed.entries?.compactMap { item in
                    guard let urlString = item.links?.first?.attributes?.href, let url = URL(string: urlString),
                          let publishedAt = item.published ?? item.updated else {
                        return nil
                    }
                    return Feed.Entry(
                        url: url,
                        title: item.title ?? url.absoluteString,
                        publishedAt: publishedAt,
                        content: sanitizeEntryContent(getLonger(item.summary?.value, item.content?.value))
                    )
                } ?? []
            )
        case .json(let jsonFeed):
            Feed(
                url: url,
                title: jsonFeed.title ?? "",
                overview: jsonFeed.description ?? "",
                entries: jsonFeed.items?.compactMap { item in
                    guard let urlString = item.url, let url = URL(string: urlString),
                          let publishedAt = item.datePublished else {
                        return nil
                    }

                    return Feed.Entry(
                        url: url,
                        title: item.title ?? url.absoluteString,
                        publishedAt: publishedAt,
                        content: sanitizeEntryContent(getLonger(item.contentText ?? item.contentHtml, item.summary))
                    )
                } ?? []
            )
        }
    }

    private func getLonger(_ string1: String?, _ string2: String?) -> String {
        let unwrappedString1 = string1 ?? ""
        let unwrappedString2 = string2 ?? ""
        return unwrappedString1.count > unwrappedString2.count ? unwrappedString1 : unwrappedString2
    }

    private func sanitizeEntryContent(_ string: String) -> String {
        let replaced = string
            .replacing(#/<[^>]+>/#, with: "")
            .replacing(#/\s+/#, with: " ")
            .trimmingPrefix(#/\s/#)
        return String(replaced.prefix(500))
    }
}

func normalizeURL(_ url: URL) -> URL? {
     var components = URLComponents(url: url, resolvingAgainstBaseURL: false)

     components?.query = nil

     guard let newURL = components?.url else { return nil }

     var urlString = newURL.absoluteString
     if urlString.hasSuffix("/") {
         urlString.removeLast()
     }

     return URL(string: urlString)
}
