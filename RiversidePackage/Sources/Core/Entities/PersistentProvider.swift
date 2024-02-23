import CoreData
import Dependencies
import Logging

public final class PersistentProvider {
    public static let cloud: PersistentProvider = .init(
        persistentContainer: makePersistentCloudKitContainer(
            containerIdentifier: "iCloud.com.muijp.Riverside"
        )
    )
    
    public static let inMemory: PersistentProvider = .init(
        persistentContainer: {
            let model = NSManagedObjectModel(contentsOf: Bundle.module.url(forResource: "Model", withExtension: "momd")!)!
            let container = NSPersistentCloudKitContainer(name: "Model", managedObjectModel: model)
            container.persistentStoreDescriptions = [NSPersistentStoreDescription(url: URL(fileURLWithPath: "/dev/null"))]
            return container
        }()
    )
    
    private static func storeURL() -> URL {
        // TODO: storeURL を DI するようにする
        let storeDirectory = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.muijp.RiversideIOS"
        )!
        return storeDirectory.appendingPathComponent("Synced.sqlite")
    }
    
    private static func makePersistentCloudKitContainer(containerIdentifier: String) -> NSPersistentContainer {
        @Dependency(\.logger[.iCloud]) var logger
        
        let model = NSManagedObjectModel(contentsOf: Bundle.module.url(forResource: "Model", withExtension: "momd")!)!
        let container = NSPersistentCloudKitContainer(name: "Model", managedObjectModel: model)
        
        let storeURL = Self.storeURL()
        let description = NSPersistentStoreDescription(url: storeURL)
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: containerIdentifier)
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.persistentStoreDescriptions = [description]
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        logger.notice("initialized CloudKitContainer: \(containerIdentifier, privacy: .public) at \(storeURL, privacy: .public)")
        
        return container
    }
    
    public var viewContext: NSManagedObjectContext { persistentContainer.viewContext }
    public var backgroundContext: NSManagedObjectContext { persistentContainer.newBackgroundContext() }
    public var managedObjectModel: NSManagedObjectModel { persistentContainer.managedObjectModel }
    
    public var databaseSize: Int? {
        let storeURL = Self.storeURL()
        let attributes = try? FileManager.default.attributesOfItem(atPath: storeURL.path)
        return attributes?[.size] as? Int
    }
    
    private let persistentContainer: NSPersistentContainer
    
    private init(persistentContainer: NSPersistentContainer) {
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("failed to load CoreData store: \(error)")
            }
        }
        self.persistentContainer = persistentContainer
    }
}
