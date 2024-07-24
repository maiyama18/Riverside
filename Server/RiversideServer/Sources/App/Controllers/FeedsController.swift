import Foundation
import FeedClient
import Payloads
import Vapor

struct FeedsController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let feeds = routes.grouped("feeds")
        
        feeds.post(use: post)
    }
    
    @Sendable
    func post(req: Request) async throws -> FeedsResponseBody {
        let feedClient = FeedClient(urlSession: .shared, logger: req.logger)
        
        let requestBody = try req.content.decode(FeedsRequestBody.self)
        req.logger.notice("request: \(requestBody)")
        let feeds = try await fetchFeeds(logger: req.logger, feedClient: feedClient, urls: requestBody.urls)
        return FeedsResponseBody(feeds: feeds)
    }
    
    private func fetchFeeds(
        logger: Logger,
        feedClient: FeedClient,
        urls: [String]
    ) async throws -> [String:Feed] {
        await withTaskGroup(of: Optional<(String, Feed)>.self, returning: [String:Feed].self) { [feedClient] group in
            for urlString in urls {
                group.addTask {
                    guard let url = URL(string: urlString) else { return nil }
                    
                    do {
                        return try await (urlString, feedClient.fetch(url: url))
                    } catch {
                        logger.warning("failed to fetch \(urlString): \(error)")
                        return nil
                    }
                }
            }
            
            return await group.compactMap { $0 }.reduce(into: [:]) { result, pair in
                result[pair.0] = pair.1
            }
        }
    }
}
