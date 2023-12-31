@testable import FeedClient

import XCTest

final class NormalizeURLTests: XCTestCase {
    func test() {
        let testCases: [(input: URL, expected: URL)] = [
            (input: URL(string: "https://example.com")!, expected: URL(string: "https://example.com")!),
            (input: URL(string: "https://example.com/rss")!, expected: URL(string: "https://example.com/rss")!),
            (input: URL(string: "https://example.com/")!, expected: URL(string: "https://example.com")!),
            (input: URL(string: "https://example.com?key=value")!, expected: URL(string: "https://example.com")!),
        ]
        
        for testCase in testCases {
            XCTAssertEqual(normalizeURL(testCase.input), testCase.expected)
        }
    }
}
