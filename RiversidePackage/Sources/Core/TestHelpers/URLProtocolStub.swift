import Foundation

public struct StubResponse: Sendable {
    public let result: Result<(Int, Data), Error>

    public init(result: Result<(Int, Data), Error>) {
        self.result = result
    }
}

public final class URLProtocolStub: URLProtocol {
    private static var responses: [URL: StubResponse] = [:]

    public static func setResponses(_ responses: [URL: StubResponse]) {
        self.responses = responses
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
              let response = Self.responses[url] else {
            client?.urlProtocol(self, didFailWithError: NSError(domain: "stub response not match", code: 0))
            return
        }

        switch response.result {
        case .success((let statusCode, let data)):
            let response = HTTPURLResponse(
                url: url,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
        case .failure(let error):
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override public func stopLoading() {}
}
