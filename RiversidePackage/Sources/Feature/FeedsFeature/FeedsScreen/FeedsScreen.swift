import SubscribeFeedFeature
import CloudSyncState
import Dependencies
import FeedUseCase
import Models
import NavigationState
import SwiftData
import SwiftUI
import UIComponents
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
    
    @Dependency(\.clipboardClient) private var clipboardClient
    @Dependency(\.flashClient) private var flashClient
    @Dependency(\.feedUseCase) private var feedUseCase
    
    @Environment(CloudSyncState.self) private var cloudSyncState
    @Environment(NavigationState.self) private var navigationState
    @Environment(\.modelContext) private var context
    
    @State private var presentation: Presentation? = nil
    
    @Query(FeedModel.all) private var feeds: [FeedModel]
    
    private var sortedFeeds: [FeedModel] {
        feeds.sorted(by: { $0.unreadCount > $1.unreadCount })
    }
    
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
                                navigationState.feedsPresentation = .subscribeFeed
                            } label: {
                                Text("Subscribe feed")
                            }
                        }
                    )
                } else {
                    List {
                        ForEach(sortedFeeds) { feed in
                            NavigationLink(value: FeedsRoute.feedDetail(feed: feed)) {
                                FeedRowView(feed: feed)
                                    .contextMenu {
                                        feedMenu(feed: feed)
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        feedMenu(feed: feed)
                                    }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .animation(.default, value: sortedFeeds)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        if cloudSyncState.syncing {
                            ProgressView()
                        }
                        
                        Button {
                            navigationState.feedsPresentation = .subscribeFeed
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(item: $navigationState.feedsPresentation) { presentation in
                switch presentation {
                case .subscribeFeed:
                    SubscribeFeedScreen()
                }
            }
            .navigationTitle("Feeds")
            .navigationBarTitleDisplayMode(.inline)
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
    
    @ViewBuilder
    private func feedMenu(feed: FeedModel) -> some View {
        Button {
            presentation = .remove(feed: feed)
        } label: {
            Label {
                Text("Unsubscribe")
            } icon: {
                Image(systemName: "trash")
            }
        }
        .tint(.red)
        
        Button {
            clipboardClient.copy(feed.url)
            flashClient.present(
                type: .info,
                message: "Copied feed url!\n\(feed.url)"
            )
        } label: {
            Label {
                Text("Copy feed url")
            } icon: {
                Image(systemName: "doc.on.doc")
            }
        }
        .tint(.gray)
        
        if feed.unreadCount > 0 {
            Button {
                presentation = .markAsRead(feed: feed)
            } label: {
                Label {
                    Text("mark all as read")
                } icon: {
                    Image(systemName: "checkmark")
                }
            }
            .tint(.blue)
        }
    }
}

#Preview { @MainActor in
    FeedsScreen()
        .environment(CloudSyncState())
        .environment(NavigationState())
        .modelContainer(previewContainer())
}
