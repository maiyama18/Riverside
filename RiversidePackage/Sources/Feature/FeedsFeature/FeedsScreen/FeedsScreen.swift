import AddFeedFeature
import CloudSyncState
import Dependencies
import FeedUseCase
import Models
import NavigationState
import SwiftData
import SwiftUI
import Utilities

@MainActor
public struct FeedsScreen: View {
    enum Presentation: Identifiable {
        case remove(feed: FeedModel)
        case markAsRead(feed: FeedModel)
        
        var id: String {
            switch self {
            case .remove(let feed):
                "remove-\(feed.id)"
            case .markAsRead(let feed):
                "mark-as-read-\(feed.id)"
            }
        }
    }
    
    @Dependency(\.feedUseCase) private var feedUseCase
    
    @Environment(CloudSyncState.self) private var cloudSyncState
    @Environment(NavigationState.self) private var navigationState
    @Environment(\.modelContext) private var context
    
    @State private var presentation: Presentation? = nil
    
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
                                            presentation = .remove(feed: feed)
                                        } label: {
                                            Image(systemName: "trash")
                                        }
                                        .tint(.red)
                                        
                                        if feed.unreadCount > 0 {
                                            Button {
                                                presentation = .markAsRead(feed: feed)
                                            } label: {
                                                Image(systemName: "checkmark")
                                            }
                                            .tint(.blue)
                                        }
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if cloudSyncState.syncing {
                        ProgressView()
                    }
                }
            }
            .navigationDestination(for: FeedsRoute.self) { route in
                switch route {
                case .feedDetail(let feed):
                    FeedDetailScreen(feed: feed)
                }
            }
        }
        .task {
            do {
                try await feedUseCase.addNewEpisodesForAllFeeds(context, false)
            } catch {
                print(error)
            }
        }
        .alert(item: $presentation) { presentation in
            switch presentation {
            case .remove(let feed):
                Alert(
                    title: Text("Are you sure to remove feed '\(feed.title)'"),
                    primaryButton: .destructive(Text("Remove")) {
                        context.delete(feed)
                    },
                    secondaryButton: .cancel()
                )
            case .markAsRead(let feed):
                Alert(
                    title: Text("Mark all entries of '\(feed.title)' as read?"),
                    primaryButton: .default(Text("Confirm")) {
                        guard let entries = feed.entries else { return }
                        for entry in entries {
                            entry.read = true
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}

#Preview { @MainActor in
    FeedsScreen()
        .environment(CloudSyncState())
        .environment(NavigationState())
        .modelContainer(previewContainer())
}
