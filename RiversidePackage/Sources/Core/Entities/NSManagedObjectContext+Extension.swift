import CoreData

extension NSManagedObjectContext {
    public func saveWithRollback() throws {
        do {
            try save()
        } catch {
            rollback()
            throw error
        }
    }
}
