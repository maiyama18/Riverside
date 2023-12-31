import AddFeedFeature
import Models
import NavigationState
import SwiftData
import SwiftUI
import Utilities

public struct FeedsScreen: View {
    @Environment(NavigationState.self) private var navigationState
    @Environment(\.modelContext) private var context
    
    @Query(FeedModel.all, animation: .default) var feeds: [FeedModel]
    
    public init() {}
    
    public var body: some View {
        @Bindable var navigationState = navigationState
        
        NavigationStack(path: $navigationState.feedsPath) {
            Group {
                if feeds.isEmpty {
                    ContentUnavailableView(
                        label: {
                            Label(
                                title: { Text("No following feed") },
                                icon: { Image(systemName: "list.dash") }
                            )
                        },
                        actions: {
                            Button {
                                navigationState.feedsPresentation = .addFeed
                            } label: {
                                Text("Add feed")
                            }
                        }
                    )
                } else {
                    List {
                        ForEach(feeds) { feed in
                            NavigationLink(value: FeedsRoute.feedDetail(feed: feed)) {
                                FeedRowView(feed: feed)
                                    .swipeActions(
                                        edge: .trailing,
                                        allowsFullSwipe: false
                                    ) {
                                        Button {
                                            context.delete(feed)
                                        } label: {
                                            Image(systemName: "trash")
                                        }
                                        .tint(.red)
                                    }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        navigationState.feedsPresentation = .addFeed
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $navigationState.feedsPresentation) { presentation in
                switch presentation {
                case .addFeed:
                    AddFeedScreen()
                }
            }
            .navigationTitle("Feeds")
            .navigationDestination(for: FeedsRoute.self) { route in
                switch route {
                case .feedDetail(let feed):
                    FeedDetailScreen(feed: feed)
                }
            }
        }
    }
}

#Preview { @MainActor in
    FeedsScreen()
        .environment(NavigationState())
        .modelContainer(previewContainer())
}
