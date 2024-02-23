import Entities
import SwiftUI
import WidgetKit

public struct RiversideRecentWidget: Widget {
    public init() {}
    
    public var body: some WidgetConfiguration {
        RiversideRecentWidgetConfiguration()
    }
}

struct RiversideRecentWidgetConfiguration: WidgetConfiguration {
    private let kind: String = "RiversideWidget"
    private let persistentProvider: PersistentProvider = .cloud
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: Provider(managedObjectContext: persistentProvider.viewContext)
        ) { entry in
            WidgetView(entry: entry)
        }
        .configurationDisplayName("Recent")
        .description("Recent unread entries")
        .supportedFamilies([.systemSmall])
    }
}
