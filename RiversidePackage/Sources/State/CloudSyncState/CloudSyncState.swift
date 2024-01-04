import CoreData
import Combine
import Foundation
import Observation

@Observable
public final class CloudSyncState {
    public enum SyncStatus {
        case notStarted
        case syncing
        case succeeded(date: Date)
        case failed(date: Date, error: any Error)
        
        public var date: Date? {
            switch self {
            case .succeeded(let date), .failed(let date, _):
                return date
            case .notStarted, .syncing:
                return nil
            }
        }
        
        var syncing: Bool {
            if case .syncing = self { return true }
            return false
        }
        
        init(event: Event) {
            if let endDate = event.endDate {
                if let error = event.error {
                    self = .failed(date: endDate, error: error)
                } else {
                    self = .succeeded(date: endDate)
                }
            } else {
                self = .syncing
            }
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
    
    typealias Event = NSPersistentCloudKitContainer.Event
    
    private static let eventsPublisher: some Publisher<Event, Never> = NotificationCenter.default
        .publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
        .compactMap { notification in
            notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? Event
        }
        
    public var importStatus: SyncStatus = .notStarted
    public var exportStatus: SyncStatus = .notStarted
    
    public var syncTransactions: [SyncTransaction] = []
    
    public var syncing: Bool { importStatus.syncing || exportStatus.syncing }
    
    private var cancellable: AnyCancellable? = nil
    
    public init() {
        cancellable = Self.eventsPublisher
            .sink { [weak self] event in
                guard let self else { return }
                
                switch event.type {
                case .setup:
                    break
                case .import:
                    importStatus = .init(event: event)
                case .export:
                    exportStatus = .init(event: event)
                @unknown default:
                    break
                }
                
                if let transaction = SyncTransaction(event: event) {
                    syncTransactions.append(transaction)
                }
            }
    }
}
