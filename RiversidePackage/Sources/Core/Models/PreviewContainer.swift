import SwiftData

@MainActor
public let previewContainer: ModelContainer = {
    do {
        let container = try ModelContainer(
            for: FeedModel.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return container
    } catch {
        fatalError("Failed to create container")
    }
}()
