import Dependencies
import Foundation

public struct StubResponse: Sendable {
    public let statusCode: Int
    public let data: Data
    public let headerFields: [String: String]
    
    public init(statusCode: Int, data: Data, headerFields: [String: String] = [:]) {
        self.statusCode = statusCode
        self.data = data
        self.headerFields = headerFields
    }
}

public final class URLProtocolStub: URLProtocol {
    private static let responses: LockIsolated<[URL: Result<StubResponse, Error>]> = .init([:])

    public static func setResponses(_ responses: [URL: Result<StubResponse, Error>]) {
        self.responses.withValue { $0 = responses }
    }

    override public class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override public func startLoading() {
        defer { client?.urlProtocolDidFinishLoading(self) }

        guard let url = request.url,
              let response = Self.responses[url] ?? Self.responses[toggleTrailingSlash(url: url)] else {
            client?.urlProtocol(self, didFailWithError: NSError(domain: "stub response not match", code: 0))
            return
        }

        switch response {
        case .success(let stubResponse):
            let urlResponse = HTTPURLResponse(
                url: url,
                statusCode: stubResponse.statusCode,
                httpVersion: nil,
                headerFields: stubResponse.headerFields
            )!
            client?.urlProtocol(self, didReceive: urlResponse, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: stubResponse.data)
        case .failure(let error):
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override public func stopLoading() {}
    
    private func toggleTrailingSlash(url: URL) -> URL {
        var urlString = url.absoluteString
        if urlString.hasSuffix("/") {
            urlString.removeLast()
        } else {
            urlString += "/"
        }
        return URL(string: urlString)!
    }
}
