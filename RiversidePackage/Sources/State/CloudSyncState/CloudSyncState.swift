import CoreData
import Combine
import Foundation
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
        
        init?(event: NSPersistentCloudKitContainer.Event) {
            guard let endDate = event.endDate else { return nil }
            
            self.init(
                id: event.identifier,
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
    
    private var cancellable: AnyCancellable? = nil
    private var ongoingEvents: Dictionary<UUID, NSPersistentCloudKitContainer.EventType> = [:]
    
    public init(notificationCenter: NotificationCenter = .default) {
        cancellable = notificationCenter
            .publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
            .receive(on: DispatchQueue.main)
            .compactMap { notification in
                notification.userInfo?[
                    NSPersistentCloudKitContainer.eventNotificationUserInfoKey
                ] as? NSPersistentCloudKitContainer.Event
            }
            .sink { [weak self] event in
                guard let self else { return }
                
                if event.endDate == nil {
                    ongoingEvents[event.identifier] = event.type
                } else {
                    ongoingEvents.removeValue(forKey: event.identifier)
                }
                
                if let transaction = SyncTransaction(event: event) {
                    syncTransactions.append(transaction)
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
