import Entities
import WidgetKit

struct Entry: TimelineEntry {
    let date: Date
    let result: Result<[Item], any Error>
}

struct Item: Identifiable {
    let id: String
    let title: String
    let feedTitle: String
    let publishedAt: Date
    
    init(id: String, title: String, feedTitle: String, publishedAt: Date) {
        self.id = id
        self.title = title
        self.feedTitle = feedTitle
        self.publishedAt = publishedAt
    }
    
    init(model: EntryModel) {
        self.init(
            id: model.url?.absoluteString ?? UUID().uuidString,
            title: model.title ?? "",
            feedTitle: model.feed?.title ?? "",
            publishedAt: model.publishedAt ?? .now
        )
    }
}
