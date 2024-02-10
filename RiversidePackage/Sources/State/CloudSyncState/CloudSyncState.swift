import CoreData
import CombineSchedulers
import Combine
import Dependencies
import Foundation
import Logging
import Observation

@Observable
@MainActor
public final class CloudSyncState {
    public enum SyncStatus {
        case notStarted
        case syncing
        case succeeded(date: Date)
        case failed(date: Date, error: any Error)
        
        var syncing: Bool {
            if case .syncing = self { return true }
            return false
        }
    }
    
    public struct SyncTransaction: Identifiable {
        public let id: UUID
        public let type: NSPersistentCloudKitContainer.EventType
        public let date: Date
        public let result: Result<Void, any Error>
        
        public init(id: UUID, type: NSPersistentCloudKitContainer.EventType, date: Date, result: Result<Void, any Error>) {
            self.id = id
            self.type = type
            self.date = date
            self.result = result
        }
        
        init?(event: CloudSyncEvent) {
            guard let endDate = event.endDate else { return nil }
            
            self.init(
                id: event.id,
                type: event.type,
                date: endDate,
                result: {
                    if let error = event.error {
                        .failure(error)
                    } else {
                        .success(())
                    }
                }()
            )
        }
    }
    
    public var importStatus: SyncStatus { syncStatus(for: .import) }
    public var exportStatus: SyncStatus { syncStatus(for: .export) }
    public var syncing: Bool { importStatus.syncing || exportStatus.syncing }
    public var syncTransactions: [SyncTransaction] = []
    
    private var ongoingEvents: Dictionary<UUID, NSPersistentCloudKitContainer.EventType> = [:]
    
    @ObservationIgnored
    @Dependency(\.logger[.iCloud]) private var logger
    
    public init(
        publisher: some Publisher<CloudSyncEvent, Never> = NotificationCenter.default
            .publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
            .compactMap { notification in
                notification.userInfo?[
                    NSPersistentCloudKitContainer.eventNotificationUserInfoKey
                ] as? NSPersistentCloudKitContainer.Event
            }
            .map { CloudSyncEvent(event: $0) }
    ) {
        logger.notice("CloudSyncState init")
        Task {
            for await event in publisher.buffer(size: .max, prefetch: .byRequest, whenFull: .dropOldest).values {
                let eventType: String = switch event.type {
                case .setup: "Setup"
                case .import: "Import"
                case .export: "Export"
                @unknown default: "Unknown"
                }
                logger.notice("\(eventType, privacy: .public)(\(event.id, privacy: .public)) \(event.endDate == nil ? "started" : "ended", privacy: .public)")
                
                if event.endDate == nil {
                    ongoingEvents[event.id] = event.type
                } else {
                    ongoingEvents.removeValue(forKey: event.id)
                }
                
                if let transaction = SyncTransaction(event: event) {
                    syncTransactions.append(transaction)
                }
            }
        }
    }
    
    private func syncStatus(for type: NSPersistentCloudKitContainer.EventType) -> SyncStatus {
        guard !ongoingEvents.values.contains(type) else {
            return .syncing
        }
        guard let lastTransaction = syncTransactions.last(where: { $0.type == type }) else {
            return .notStarted
        }
        switch lastTransaction.result {
        case .success:
            return .succeeded(date: lastTransaction.date)
        case .failure(let error):
            return .failed(date: lastTransaction.date, error: error)
        }
    }
}
