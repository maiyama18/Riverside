import SwiftData

@MainActor
public func previewContainer() -> ModelContainer {
    do {
        let container = try ModelContainer(
            for: FeedModel.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        for feed in FeedModel.previewContents {
            container.mainContext.insert(feed)
        }
        return container
    } catch {
        fatalError("Failed to create container")
    }
}

public extension FeedModel {
    static let previewContents: [FeedModel] = [
        .init(url: "https://maiyama4.hatenablog.com/rss", title: "maiyama4's blog", overview: nil),
        .init(url: "https://iosdevweekly.com/issues.rss", title: "iOS Dev Weekly", overview: "Subscribe to a hand-picked round-up of the best iOS development links every week. Curated by Dave Verwer and published every Friday. Free."),
    ]
}
