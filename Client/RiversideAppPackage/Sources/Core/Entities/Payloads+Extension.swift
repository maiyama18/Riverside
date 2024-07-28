import Payloads
import CoreData

extension Feed {
    public func toModel(context: NSManagedObjectContext) -> (FeedModel, [EntryModel]) {
        let feedModel = FeedModel(context: context)
        feedModel.url = url
        feedModel.title = title
        feedModel.overview = overview
        feedModel.imageURL = imageURL
        
        let entryModels = entries
            .sorted(by: { $0.publishedAt > $1.publishedAt })
            .map { $0.toModel(context: context) }
        
        return (feedModel, entryModels)
    }
}

extension Entry {
    public func toModel(context: NSManagedObjectContext) -> EntryModel {
        let model = EntryModel(context: context)
        model.url = url
        model.title = title
        model.publishedAt = publishedAt
        model.content = content
        return model
    }
}
