import Algorithms

extension FeedModel {
    public var unreadCount: Int {
        guard let entries = entries as? Set<EntryModel> else { return 0 }
        return entries.uniqued(on: \.url).filter { $0.read == false }.count
    }
    
    public func markAll(asRead read: Bool) {
        guard let entries = entries as? Set<EntryModel> else { return }
        for entry in entries {
            entry.read = read
        }
    }
}
