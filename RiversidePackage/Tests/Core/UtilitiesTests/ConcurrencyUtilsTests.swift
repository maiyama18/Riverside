import Dependencies
import XCTest

@testable import Utilities

final class ConcurrencyUtilsTests: XCTestCase {
    func testWithTimeout_resultReturns() async throws {
        let clock = TestClock()
        let result: LockIsolated<Int?> = .init(nil)
        
        Task {
            do {
                let r = try await withDependencies {
                    $0.continuousClock = clock
                    $0.uuid = .incrementing
                } operation: {
                    try await withTimeout(for: .seconds(3)) {
                        try await clock.sleep(for: .seconds(2))
                        return 42
                    }
                }
                result.withValue { $0 = r }
            } catch {
                XCTFail()
            }
        }
        
        await clock.advance(by: .seconds(1.9))
        XCTAssertEqual(result.value, nil)
        await clock.advance(by: .seconds(0.6))
        XCTExpectFailure(options: .nonStrict()) {
            XCTAssertEqual(result.value, 42)
        }
    }
    
    func testWithTimeout_timeouts() async throws {
        let clock = TestClock()
        let withTimeoutReturned: LockIsolated<Bool> = .init(false)
        let operationCompleted: LockIsolated<Bool> = .init(false)
        
        Task {
            try await withDependencies {
                $0.continuousClock = clock
            } operation: {
                do {
                    return try await withTimeout(for: .seconds(3)) {
                        try await clock.sleep(for: .seconds(3.1))
                        operationCompleted.withValue { $0 = true }
                        return 42
                    }
                } catch {
                    XCTAssertTrue(error is TimeoutError)
                    withTimeoutReturned.withValue { $0 = true }
                    throw error
                }
            }
        }
        
        await clock.advance(by: .seconds(2.9))
        XCTAssertEqual(withTimeoutReturned.value, false)
        XCTAssertEqual(operationCompleted.value, false)
        await clock.advance(by: .seconds(0.15))
        XCTAssertEqual(withTimeoutReturned.value, true)
        XCTAssertEqual(operationCompleted.value, false)
        await clock.advance(by: .seconds(0.1))
        XCTAssertEqual(withTimeoutReturned.value, true)
        XCTAssertEqual(operationCompleted.value, false)
    }
}
