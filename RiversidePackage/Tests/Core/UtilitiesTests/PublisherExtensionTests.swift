@preconcurrency import Combine
import XCTest

@testable import Utilities

final class PublisherExtensionTests: XCTestCase {
    func testNextValue_receiveValue() async {
        let subject = PassthroughSubject<Int, Never>()

        let expectation = self.expectation(description: "expectation")
        Task {
            let value = try await subject.nextValue()
            XCTAssertEqual(value, 42)
            expectation.fulfill()
        }
        Task {
            try await Task.sleep(for: .seconds(0.1))
            subject.send(42)
        }
        await fulfillment(of: [expectation], timeout: 1)
    }

    func testNextValue_cancel() async {
        let subject = PassthroughSubject<Int, Never>()

        let expectation = self.expectation(description: "expectation")
        let task = Task {
            do {
                _ = try await subject.nextValue()
            } catch {
                XCTAssertTrue(error is CancellationError)
                expectation.fulfill()
            }
        }
        Task {
            try await Task.sleep(for: .seconds(0.1))
            task.cancel()
        }
        await fulfillment(of: [expectation], timeout: 1)
    }
}
