import Foundation
import FeedFetcher
import Payloads
import Vapor

struct FeedsController: RouteCollection {
    struct FeedsError: Error {
        var url: String
        var description: String
    }
    
    func boot(routes: any RoutesBuilder) throws {
        let feeds = routes.grouped("feeds")
        
        feeds.post(use: post)
    }
    
    @Sendable
    func post(req: Request) async throws -> FeedsResponseBody {
        let feedFetcher = FeedFetcher(urlSession: .shared, logger: req.logger)
        
        let requestBody = try req.content.decode(FeedsRequestBody.self)
        req.logger.notice("request: \(requestBody)")
        let feeds = try await fetchFeeds(logger: req.logger, feedFetcher: feedFetcher, urls: requestBody.urls)
        let responseBody = FeedsResponseBody(feeds: feeds)
        req.logger.notice("response: \(responseBody)")
        return responseBody
    }
    
    private func fetchFeeds(
        logger: Logger,
        feedFetcher: FeedFetcher,
        urls: [String]
    ) async throws -> [String:FeedsResponseBody.FeedResult] {
        await withTaskGroup(of: Result<(String, Feed), FeedsError>.self) { [feedFetcher] group in
            for urlString in urls {
                group.addTask {
                    guard let url = URL(string: urlString) else {
                        return .failure(FeedsError(url: urlString, description: "invalid url: \(urlString)"))
                    }
                    
                    do {
                        return try await .success((urlString, feedFetcher.fetch(url: url)))
                    } catch {
                        logger.warning("failed to fetch \(urlString): \(error)")
                        return .failure(FeedsError(url: urlString, description: "failed to fetch \(urlString): \(error)"))
                    }
                }
            }
            
            return await group.reduce(into: [:]) { dict, result in
                switch result {
                case .success((let url, let feed)):
                    dict[url] = .init(feed: feed)
                case .failure(let error):
                    dict[error.url] = .init(error: error.description)
                }
            }
        }
    }
}
