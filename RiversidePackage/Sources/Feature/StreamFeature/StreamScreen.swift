import CloudSyncState
import Dependencies
import FeedUseCase
import FlashClient
import Models
import NavigationState
import SwiftData
import SwiftUI
import UIComponents
import Utilities

@MainActor
public struct StreamScreen: View {
    @Dependency(\.feedUseCase) private var feedUseCase
    @Dependency(\.flashClient) private var flashClient
    
    @Environment(CloudSyncState.self) private var cloudSyncState
    @Environment(NavigationState.self) private var navigationState
    @Environment(\.modelContext) private var context
    
    @Query(EntryModel.all, animation: .default) var entries: [EntryModel]
    @Query(FeedModel.all) var feeds: [FeedModel]
    
    @AppStorage("unread-only-stream") private var unreadOnly: Bool = true
    
    @State private var markAllAsReadDialogPresented: Bool = false
    
    public init() {}
    
    public var body: some View {
        @Bindable var navigationState = navigationState
        
        NavigationStack {
            Group {
                if sections.isEmpty {
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
                                    navigationState.routeToSubscribeFeed()
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
                                    StreamEntryRowView(
                                        entry: entry,
                                        onFeedTapped: { feed in
                                            Task {
                                                await navigationState.routeToFeedDetail(feed: feed)
                                            }
                                        }
                                    )
                                    .contentShape(Rectangle())
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
                    .refreshable {
                        do {
                            try await feedUseCase.addNewEpisodesForAllFeeds(context, true)
                        } catch {
                            flashClient.present(
                                type: .error,
                                message: "Failed to refresh feeds: \(error.localizedDescription)"
                            )
                        }
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        if cloudSyncState.syncing {
                            ProgressView()
                        }
                        
                        Menu {
                            Toggle(isOn: $unreadOnly) { Text("Unread only") }
                            Button("Mark all as read...") { markAllAsReadDialogPresented = true }
                                .disabled(entries.filter { !$0.read }.isEmpty)
                        } label: {
                            Image(systemName: "ellipsis")
                        }
                    }
                }
            }
            .alert(
                "Mark all entries as read?",
                isPresented: $markAllAsReadDialogPresented
            ) {
                Button(
                    role: .destructive,
                    action: {
                        for entry in entries {
                            entry.read = true
                        }
                    }
                ) {
                    Text("Confirm")
                }
                Button(role: .cancel, action: {}) { Text("Cancel") }
            }
            .task {
                do {
                    try await feedUseCase.addNewEpisodesForAllFeeds(context, false)
                } catch {
                    print(error)
                }
            }
        }
    }
    
    private var sections: [StreamSection] {
        StreamSectionBuilder.build(entries: entries.filter({ unreadOnly ? $0.read == false : true }))
    }
    
    private var navigationTitle: String {
        let unreadCount = entries.filter { !$0.read }.count
        return unreadCount == 0 ? "Stream" : "Stream (\(unreadCount))"
    }
}

#Preview { @MainActor in
    StreamScreen()
        .environment(CloudSyncState())
        .environment(NavigationState())
        .modelContainer(previewContainer())
}
