import CoreData

public struct CloudSyncEvent: Sendable {
    public let id: UUID
    public let type: NSPersistentCloudKitContainer.EventType
    public let endDate: Date?
    public let error: (any Error)?
    
    public init(event: NSPersistentCloudKitContainer.Event) {
        self.init(
            id: event.identifier,
            type: event.type,
            endDate: event.endDate,
            error: event.error
        )
    }
    
    public init(id: UUID, type: NSPersistentCloudKitContainer.EventType, endDate: Date?, error: (any Error)?) {
        self.id = id
        self.type = type
        self.endDate = endDate
        self.error = error
    }
}
