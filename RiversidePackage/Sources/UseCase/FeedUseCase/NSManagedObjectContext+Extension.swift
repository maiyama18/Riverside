import CoreData

extension NSManagedObjectContext {
    func saveWithRollback() throws {
        do {
            try save()
        } catch {
            rollback()
            throw error
        }
    }
}
