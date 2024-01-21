import Algorithms

extension FeedModel {
    public func markAll(asRead read: Bool) {
        guard let entries = entries as? Set<EntryModel> else { return }
        for entry in entries {
            entry.read = read
        }
    }
}
