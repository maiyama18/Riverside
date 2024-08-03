import Foundation
import FeedFetcher
import Fluent
import Payloads
import Vapor

struct FeedsController: RouteCollection {
    enum FeedOrigin {
        case remote
        case local
    }
    
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
        let feedFetcher = FeedFetcher(client: req.client, logger: req.logger)
        
        let requestBody = try req.content.decode(FeedsRequestBody.self)
        req.logger.notice("request: \(requestBody)")
        let feeds = try await fetchFeeds(
            urls: requestBody.urls,
            forceRefresh: requestBody.forceRefresh,
            feedFetcher: feedFetcher,
            database: req.db,
            logger: req.logger
        )
        
        Task {
            await saveFeeds(
                fetchedFeeds: feeds.values.compactMap { try? $0.get() }.compactMap { $0.origin == .remote ? $0.feed : nil },
                database: req.db,
                logger: req.logger
            )
        }
        
        let responseBody = FeedsResponseBody(
            feeds: feeds.mapValues {
                switch $0 {
                case .success((_, let feed)): return .init(feed: feed)
                case .failure(let error): return .init(error: error.localizedDescription)
                }
            }
        )
        req.logger.notice("response: \(responseBody)")
        return responseBody
    }
    
    private func fetchFeeds(
        urls: [String],
        forceRefresh: Bool,
        feedFetcher: FeedFetcher,
        database: any Database,
        logger: Logger
    ) async throws -> [String:Result<(origin: FeedOrigin, feed: Payloads.Feed), any Error>] {
        await withTaskGroup(of: Result<(String, FeedOrigin, Payloads.Feed), FeedsError>.self) { [feedFetcher] group in
            func addTask(urlString: String) {
                group.addTask {
                    guard let url = URL(string: urlString) else {
                        return .failure(FeedsError(url: urlString, description: "invalid url: \(urlString)"))
                    }
                    
                    do {
                        if !forceRefresh,
                           let feed = try? await Feed.query(on: database).filter(\.$url == urlString).with(\.$entries).first(),
                           feed.updatedWithin(timeInterval: 60 * 60) {
                            logger.notice("database records used for \(urlString)")
                            return .success((urlString, .local, feed.feedPayload()))
                        }
                        logger.notice("fetching \(urlString)")
                        defer { logger.notice("fetching finished \(urlString)") }
                        return try await .success((urlString, .remote, feedFetcher.fetch(url: url)))
                    } catch {
                        logger.warning("failed to fetch \(urlString): \(error)")
                        return .failure(FeedsError(url: urlString, description: "failed to fetch \(urlString): \(error)"))
                    }
                }
            }
            
            let concurrentTaskLimit = min(urls.count, 8)
            for index in 0..<concurrentTaskLimit {
                addTask(urlString: urls[index])
            }
            
            var results: [Result<(String, FeedOrigin, Payloads.Feed), FeedsError>] = []
            var nextIndex = concurrentTaskLimit
            for await result in group {
                if nextIndex < urls.count {
                    addTask(urlString: urls[nextIndex])
                    nextIndex += 1
                }
                results.append(result)
            }
            
            return results.reduce(into: [:]) { dict, result in
                switch result {
                case .success((let url, let origin, let feed)):
                    dict[url] = .success((origin, feed))
                case .failure(let error):
                    dict[error.url] = .failure(error)
                }
            }
        }
    }
    
    private func saveFeeds(fetchedFeeds: [Payloads.Feed], database: any Database, logger: Logger) async {
        do {
            let existingFeeds = try await Feed.query(on: database)
                .filter(\.$url ~~ fetchedFeeds.map(\.url.absoluteString))
                .with(\.$entries)
                .all()
                .get()
            
            for fetchedFeed in fetchedFeeds {
                if let existingFeed = existingFeeds.first(where: { $0.url == fetchedFeed.url.absoluteString }),
                   let existingFeedID = existingFeed.id {
                    do {
                        let addedEntryCount = try await database.transaction { database in
                            var addedEntryCount = 0
                            for newEntry in fetchedFeed.entries where !existingFeed.entries.contains(where: { $0.url == newEntry.url.absoluteString }) {
                                try await Entry(entry: newEntry, feedID: existingFeedID).create(on: database)
                                addedEntryCount += 1
                            }
                            
                            existingFeed.updatedAt = .now
                            try await existingFeed.save(on: database)
                            return addedEntryCount
                        }
                        logger.notice("feed updated \(fetchedFeed.url): \(addedEntryCount) entries added")
                    } catch {
                        logger.warning("failed to update feed \(fetchedFeed.url): \(error)")
                    }
                } else {
                    do {
                        let feedRecord = Feed(feed: fetchedFeed)
                        try await database.transaction { database in
                            try await feedRecord.create(on: database)
                            
                            let feedID = try feedRecord.requireID()
                            for entry in fetchedFeed.entries {
                                try await Entry(entry: entry, feedID: feedID).create(on: database)
                            }
                        }
                        logger.notice("feed created \(fetchedFeed.url)")
                    } catch {
                        logger.warning("failed to create feed \(fetchedFeed.url): \(error)")
                    }
                }
            }
        } catch {
            logger.warning("failed to save feeds: \(error)")
        }
    }
}
