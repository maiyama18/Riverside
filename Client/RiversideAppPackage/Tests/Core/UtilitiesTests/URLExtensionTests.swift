@testable import Utilities

import XCTest

final class URLExtensionTests: XCTestCase {
    func testIsSame() throws {
        struct TestCase {
            let url1: String
            let url2: String
            let expected: Bool
            
            init(_ url1: String, _ url2: String, expected: Bool) {
                self.url1 = url1
                self.url2 = url2
                self.expected = expected
            }
        }
        
        let testCases: [TestCase] = [
            .init("https://example.com", "https://example.com", expected: true),
            .init("https://example.com", "https://example.com/", expected: true),
            .init("https://example.com/path", "https://example.com/path", expected: true),
            .init("https://example.com/path", "https://example.com/path/", expected: true),
            .init("https://example.com/path?query=value", "https://example.com/path?query=value", expected: true),
            .init(
                "https://example.com/path?query1=value1&query2=value2",
                "https://example.com/path?query2=value2&query1=value1",
                expected: true
            ),
            
            .init("https://example.com", "http://example.com", expected: false),
            .init("https://example.com", "https://example.com/path", expected: false),
            .init("https://example.com/path", "https://different.com/path", expected: false),
            .init("https://example.com", "https://example.com?query=value", expected: false),
            .init("https://example.com?query=value", "https://example.com?query=differentValue", expected: false),
        ]
        
        for testCase in testCases {
            let url1 = try XCTUnwrap(URL(string: testCase.url1))
            let url2 = try XCTUnwrap(URL(string: testCase.url2))
            XCTAssertEqual(
                url1.isSame(as: url2),
                testCase.expected,
                "\(testCase.url1) and \(testCase.url2), expected to be \(testCase.expected)"
            )
        }
    }
}
