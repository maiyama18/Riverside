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
        .init(url: "https://maiyama4.hatenablog.com/rss", title: "maiyama4's blog", overview: nil, imageURL: "https://maiyama4.hatenablog.com/icon/favicon"),
        .init(url: "https://iosdevweekly.com/issues.rss", title: "iOS Dev Weekly", overview: "Subscribe to a hand-picked round-up of the best iOS development links every week. Curated by Dave Verwer and published every Friday. Free.", imageURL: "https://dxj7eshgz03ln.cloudfront.net/production/publication/publication_icon/1/favicon_442526aa-1e62-489a-87ac-8f09b5f0f867.png"),
    ]
}
