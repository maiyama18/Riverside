import Dependencies
import Foundation
import Payloads
import RiversideLogging
import Utilities

public struct FeedClient: Sendable {
    public var fetchFeed: @Sendable (_ feedURL: URL, _ force: Bool) async throws -> Feed
    public var fetchFeeds: @Sendable (_ feedURLs: [URL], _ force: Bool) async throws -> [Feed]
}

extension FeedClient {
    static private let urlSession: URLSession = .shared
    static private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    static private let jsonEncoder: JSONEncoder = .init()
    
    static func live(serverBaseURL: URL) -> FeedClient {
        @Sendable
        func request(urls: [URL], forceRefresh: Bool) async throws -> FeedsResponseBody {
            let endpointURL: URL = serverBaseURL.appending(path: "feeds")
            
            var request = URLRequest(url: endpointURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try jsonEncoder.encode(
                FeedsRequestBody(urls: urls.map(\.absoluteString), forceRefresh: forceRefresh)
            )
            
            let (data, _) = try await urlSession.data(for: request)
            return try jsonDecoder.decode(FeedsResponseBody.self, from: data)
        }
        
        return FeedClient(
            fetchFeed: { feedURL, force in
                let response = try await request(urls: [feedURL], forceRefresh: force)
                
                guard let feedResult = response.feeds[feedURL.absoluteString] else {
                    throw NSError(domain: "invalid response", code: 0)
                }
                if let feed = feedResult.feed {
                    return feed
                } else {
                    if let feedError = feedResult.error {
                        throw NSError(domain: feedError, code: 0)
                    } else {
                        throw NSError(domain: "invalid response", code: 0)
                    }
                }
            },
            fetchFeeds: { feedURLs, force in
                @Dependency(\.logger[.feedModel]) var logger
                
                let response = try await request(urls: feedURLs, forceRefresh: force)
                
                return response.feeds.compactMap {
                    if let feed = $0.value.feed {
                        return feed
                    } else {
                        logger.warning("failed to fetch \($0.key): \($0.value.error ?? "no error")")
                        return nil
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
    static let liveValue: FeedClient = .live(
        serverBaseURL: {
            #if targetEnvironment(simulator)
            if ProcessInfo.processInfo.environment["USE_LOCAL_SERVER"] == "true" {
                URL(string: "http://localhost:8080")!
            } else {
                URL(string: "https://riverside-server-kzf5jitskq-an.a.run.app")!
            }
            #else
                URL(string: "https://riverside-server-kzf5jitskq-an.a.run.app")!
            #endif
        }()
    )
}
