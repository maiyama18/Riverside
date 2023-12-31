import Models
import NavigationState
import SwiftData
import SwiftUI
import Utilities

@MainActor
public struct StreamScreen: View {
    @Environment(NavigationState.self) private var navigationState
    
    @Query(EntryModel.all, animation: .default) var entries: [EntryModel]
    @Query(FeedModel.all) var feeds: [FeedModel]
    
    @AppStorage("unread-only-stream") private var unreadOnly: Bool = true
    
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
                                    title: { Text("You've read all entries") },
                                    icon: { Image(systemName: "list.dash") }
                                )
                            }
                        )
                    }
                } else {
                    List {
                        ForEach(sections, id: \.publishedDate) { section in
                            Section {
                                ForEach(section.entries) { entry in
                                    EntryRowView(
                                        entry: entry,
                                        onFeedTapped: { feed in
                                            Task {
                                                await navigationState.routeToFeedDetail(feed: feed)
                                            }
                                        }
                                    )
                                    .onTapGesture {
                                        guard let url = URL(string: entry.url) else { return }
                                        entry.read = true
                                        showSafari(url: url)
                                    }
                                }
                            } header: {
                                Text(section.publishedDate.formatted(date: .numeric, time: .omitted))
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Stream")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Toggle(isOn: $unreadOnly) { Text("Unread only") }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
    
    private var sections: [StreamSection] {
        StreamSectionBuilder.build(entries: entries, unreadOnly: unreadOnly)
    }
}

#Preview {
    StreamScreen()
}
