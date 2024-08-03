@testable import CloudSyncState

import CustomDump
import Combine
import TestHelpers
import XCTest

@MainActor
final class CloudSyncStateTests: XCTestCase {
    func test() async throws {
        XCTExpectFailure("Currently this test is flaky on CI")
        
        let subject: PassthroughSubject<CloudSyncEvent, Never> = .init()
        let state = CloudSyncState(publisher: subject)
        await Task.megaYield()
        
        XCTAssertNoDifference(state.syncing, false)
        XCTAssertNoDifference(state.syncTransactions.count, 0)
        
        let uuid1 = UUID()
        let uuid2 = UUID()
        let uuid3 = UUID()
        
        subject.send(CloudSyncEvent(id: uuid1, type: .import, endDate: nil, error: nil))
        try await waitUntilConditionSatisfied { await state.syncing }
        XCTAssertNoDifference(state.syncTransactions.count, 0)
        
        subject.send(CloudSyncEvent(id: uuid2, type: .export, endDate: nil, error: nil))
        try await waitUntilConditionSatisfied { await state.syncing }
        XCTAssertNoDifference(state.syncTransactions.count, 0)
        
        subject.send(CloudSyncEvent(id: uuid2, type: .export, endDate: .now, error: nil))
        try await waitUntilConditionSatisfied { await state.syncing }
        XCTAssertNoDifference(state.syncTransactions.count, 1)
        XCTAssertNoDifference(state.syncTransactions.last?.id, uuid2)
        
        subject.send(CloudSyncEvent(id: uuid1, type: .import, endDate: .now, error: nil))
        try await waitUntilConditionSatisfied { await state.syncing == false }
        XCTAssertNoDifference(state.syncTransactions.count, 2)
        XCTAssertNoDifference(state.syncTransactions.last?.id, uuid1)
        
        subject.send(CloudSyncEvent(id: uuid3, type: .export, endDate: nil, error: nil))
        try await waitUntilConditionSatisfied { await state.syncing }
        XCTAssertNoDifference(state.syncTransactions.count, 2)
        
        subject.send(CloudSyncEvent(id: uuid3, type: .export, endDate: .now, error: nil))
        try await waitUntilConditionSatisfied { await state.syncing == false }
        XCTAssertNoDifference(state.syncTransactions.count, 3)
        XCTAssertNoDifference(state.syncTransactions.last?.id, uuid3)
    }
}

