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
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        let dateFormatterWithFractional = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            
            if let date = dateFormatter.date(from: string) ?? dateFormatterWithFractional.date(from: string) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(string)")
        }
        return decoder
    }()
    static private let jsonEncoder: JSONEncoder = .init()
    
    static func live(serverBaseURL: URL) -> FeedClient {
        @Sendable
        func request(urls: [URL], forceRefresh: Bool) async throws -> FeedsResponseBody {
            let endpointURL: URL = serverBaseURL.appending(path: "riverside").appending(path: "feeds")
            let requestURL = endpointURL.appending(
                queryItems: [
                    .init(name: "urls", value: urls.map(\.absoluteString).joined(separator: ",")),
                    .init(name: "force", value: "\(forceRefresh)")
                ]
            )
            
            var request = URLRequest(url: requestURL)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let (data, response) = try await urlSession.data(for: request)
            guard let response = response as? HTTPURLResponse else {
                throw NSError(domain: "response not HTTPURLResponse", code: 0)
            }
            guard response.statusCode == 200 else {
                throw NSError(domain: "invalid response code \(response.statusCode)", code: 0)
            }
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
                URL(string: "https://rssproxy-6q4koorr7a-an.a.run.app")!
            }
            #else
                URL(string: "https://rssproxy-6q4koorr7a-an.a.run.app")!
            #endif
        }()
    )
}
