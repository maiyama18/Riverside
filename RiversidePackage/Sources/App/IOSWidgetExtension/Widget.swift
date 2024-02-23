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
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WidgetView(entry: entry)
        }
        .configurationDisplayName("Recent")
        .description("Recent unread entries")
        .supportedFamilies([.systemSmall])
    }
}
