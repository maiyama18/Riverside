import Vapor
import XCTest

struct MockResponse {
    enum ResponseType {
        case rssFeed
        case rdfFeed
        case atomFeed
        case jsonFeed
        case html
        case png
        
        var contentType: String {
            switch self {
            case .rssFeed, .atomFeed:
                "application/rss+xml"
            case .rdfFeed:
                "text/xml"
            case .jsonFeed:
                "application/json"
            case .html:
                "text/html"
            case .png:
                "image/png"
            }
        }
        
        var resourceExtension: String {
            switch self {
            case .rssFeed, .atomFeed:
                "xml"
            case .rdfFeed:
                "rdf"
            case .jsonFeed:
                "json"
            case .html:
                "html"
            case .png:
                "png"
            }
        }
    }
    
    let clientResponse: ClientResponse
    
    init(type: ResponseType, dataResourceName: String) throws {
        let resourceURL = try XCTUnwrap(Bundle.module.url(forResource: dataResourceName, withExtension: type.resourceExtension))
        let data = try Data(contentsOf: resourceURL)
        
        self.clientResponse = ClientResponse(
            status: .ok,
            headers: .init([("Content-Type", type.contentType)]),
            body: .init(data: data)
        )
    }
}

final class MockClient: Client {
    let eventLoop: any NIOCore.EventLoop
    let responses: [URI: MockResponse]
    
    init(eventLoop: any NIOCore.EventLoop, responses: [URI: MockResponse]) {
        self.eventLoop = eventLoop
        self.responses = responses
    }
    
    func send(_ request: ClientRequest) -> EventLoopFuture<ClientResponse> {
        guard let response = responses[request.url] ?? responses[toggleTrailingSlash(request.url)] else {
            return eventLoop.makeFailedFuture(NSError(domain: "response not found for url: \(request.url)", code: 0))
        }
        
        return eventLoop.makeSucceededFuture(response.clientResponse)
    }
    
    func delegating(to eventLoop: any NIOCore.EventLoop) -> any Vapor.Client {
        self
    }
    
    private func toggleTrailingSlash(_ url: URI) -> URI {
        var urlString = url.string
        if urlString.hasSuffix("/") {
            urlString.removeLast()
        } else {
            urlString += "/"
        }
        return URI(string: urlString)
    }
}
