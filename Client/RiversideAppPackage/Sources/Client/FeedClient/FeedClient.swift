import Dependencies
import Foundation
import Payloads
import RiversideLogging
import Utilities

public struct FeedClient: Sendable {
    public var fetchFeed: @Sendable (_ feedURL: URL) async throws -> Feed
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
        let endpointURL: URL = serverBaseURL.appending(path: "feeds")
        
        return FeedClient(
            fetchFeed: { feedURL in
                var request = URLRequest(url: endpointURL)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try jsonEncoder.encode(
                    FeedsRequestBody(urls: [feedURL.absoluteString])
                )
                
                let (data, _) = try await urlSession.data(for: request)
                let response = try jsonDecoder.decode(FeedsResponseBody.self, from: data)
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
                URL(string: "http://localhost:8080")!
            #else
                URL(string: "https://riverside-server-kzf5jitskq-an.a.run.app")!
            #endif
        }()
    )
}
