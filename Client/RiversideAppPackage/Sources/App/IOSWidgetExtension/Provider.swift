import CoreData
import Dependencies
import Entities
import RiversideLogging
import WidgetKit

struct Provider: TimelineProvider {
    let managedObjectContext: NSManagedObjectContext
    
    @Dependency(\.logger[.widget]) private var logger
    
    func placeholder(in context: Context) -> Entry {
        Entry(
            date: Date(),
            result: .success(
                (1...10).map { i in
                    .init(
                        id: "\(i)",
                        title: "Dummy Entry Title \(i)",
                        feedTitle: "Dummy Feed",
                        publishedAt: .now
                    )
                }
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        let entry = getEntry()
        completion(entry)
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let entry = getEntry()
        let refreshDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
    
    func getEntry() -> Entry {
        do {
            let unreadEntries = try managedObjectContext.fetch(EntryModel.unreads)
            let items = unreadEntries.map(Item.init)
            logger.notice("\(items.count) unread entries found")
            return Entry(date: Date(), result: .success(items))
        } catch {
            logger.notice("failed to fetch entries: \(error, privacy: .public))")
            return Entry(date: Date(), result: .failure(error))
        }
    }
}
