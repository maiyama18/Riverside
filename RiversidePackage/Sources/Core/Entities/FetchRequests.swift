import CoreData

extension FeedModel {
    public static var all: NSFetchRequest<FeedModel> {
        let request = FeedModel.fetchRequest()
        request.sortDescriptors = [.init(keyPath: \FeedModel.title, ascending: true)]
        return request
    }
}

extension EntryModel {
    public static var all: NSFetchRequest<EntryModel> {
        let request = EntryModel.fetchRequest()
        request.predicate = NSPredicate(format: "feed != nil")
        request.sortDescriptors = [.init(keyPath: \EntryModel.publishedAt, ascending: false)]
        return request
    }
    
    public static func belonging(to feed: FeedModel) -> NSFetchRequest<EntryModel> {
        let request = EntryModel.fetchRequest()
        if let feedURL = feed.url {
            request.predicate = NSPredicate(format: "feed.url == %@", feedURL as any CVarArg)
        }
        request.sortDescriptors = [.init(keyPath: \EntryModel.publishedAt, ascending: false)]
        return request
    }
}
