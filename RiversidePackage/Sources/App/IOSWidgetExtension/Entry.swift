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
    
    init(model: EntryModel) {
        self.id = model.url?.absoluteString ?? UUID().uuidString
        self.title = model.title ?? ""
        self.feedTitle = model.feed?.title ?? ""
        self.publishedAt = model.publishedAt ?? .now
    }
}
