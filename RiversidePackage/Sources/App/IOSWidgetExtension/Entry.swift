import WidgetKit

struct Entry: TimelineEntry {
    let date: Date
    let result: Result<[Item], any Error>
}

struct Item {
    let title: String
    let feedTitle: String
    let publishedAt: Date
}
