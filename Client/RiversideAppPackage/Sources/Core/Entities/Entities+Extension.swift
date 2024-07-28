import Algorithms
import Foundation
import Utilities
import Payloads

extension FeedModel {
    public func markAll(asRead read: Bool) {
        guard let entries = entries as? Set<EntryModel> else { return }
        for entry in entries {
            entry.read = read
        }
    }
    
    public func addNewEntries(_ fetchedEntries: [Entry]) -> [Entry] {
        guard let managedObjectContext else {
            assertionFailure("FeedModel should have managedObjectContext when addNewEntries called")
            return []
        }
        
        let existingEntries = (entries as? Set<EntryModel>) ?? []
        let existingLatestEntryPublishedAt = existingEntries.compactMap(\.publishedAt).max() ?? Date(timeIntervalSince1970: 0)
        let newEntries = fetchedEntries
            .filter { fetchedEntry in !existingEntries.compactMap(\.url).contains { $0.isSame(as: fetchedEntry.url) } }
            .filter { $0.publishedAt > existingLatestEntryPublishedAt }
        
        for newEntry in newEntries {
            addToEntries(newEntry.toModel(context: managedObjectContext))
        }
        
        return newEntries
    }
}
