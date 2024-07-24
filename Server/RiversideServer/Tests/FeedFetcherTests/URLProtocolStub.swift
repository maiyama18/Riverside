import Foundation

struct StubResponse: Sendable {
    let statusCode: Int
    let data: Data
    let headerFields: [String: String]
    
    init(statusCode: Int, data: Data, headerFields: [String: String] = [:]) {
        self.statusCode = statusCode
        self.data = data
        self.headerFields = headerFields
    }
}

final class URLProtocolStub: URLProtocol {
    nonisolated(unsafe) private static var responses: [URL: Result<StubResponse, any Error>] = [:]

    static func setResponses(_ responses: [URL: Result<StubResponse, any Error>]) {
        self.responses = responses
    }

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
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

    override func stopLoading() {}
    
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
