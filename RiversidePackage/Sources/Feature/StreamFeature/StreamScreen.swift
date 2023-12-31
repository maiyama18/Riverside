import Models
import NavigationState
import SwiftData
import SwiftUI

public struct StreamScreen: View {
    @Environment(NavigationState.self) private var navigationState
    
    @Query(EntryModel.all, animation: .default) var entries: [EntryModel]
    @Query(FeedModel.all) var feeds: [FeedModel]
    
    public init() {}
    
    public var body: some View {
        @Bindable var navigationState = navigationState
        
        NavigationStack {
            Group {
                if entries.isEmpty {
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
                                    navigationState.routeToAddFeed()
                                } label: {
                                    Text("Add feed")
                                }
                            }
                        )
                    } else {
                        ContentUnavailableView(
                            label: {
                                Label(
                                    title: { Text("You read all feeds") },
                                    icon: { Image(systemName: "list.dash") }
                                )
                            }
                        )
                    }
                } else {
                    List {
                        ForEach(entries) { entry in
                            EntryRowView(
                                entry: entry,
                                onFeedTapped: { feed in
                                    Task {
                                        await navigationState.routeToFeedDetail(feed: feed)
                                    }
                                }
                            )
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Stream")
        }
    }
}

#Preview {
    StreamScreen()
}
