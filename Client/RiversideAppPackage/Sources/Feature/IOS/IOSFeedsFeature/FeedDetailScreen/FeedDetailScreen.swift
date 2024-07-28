import Algorithms
import ClipboardClient
import CloudSyncState
import CoreData
import Dependencies
import Entities
import FeedClient
import FlashClient
import NavigationState
import SwiftUI
import Utilities
import UIComponents

@MainActor
struct FeedDetailScreen: View {
    private let feed: FeedModel
    
    @Dependency(\.clipboardClient) private var clipboardClient
    @Dependency(\.feedClient) private var feedClient
    @Dependency(\.flashClient) private var flashClient
    
    @Environment(CloudSyncState.self) private var cloudSyncState
    @Environment(NavigationState.self) private var navigationState
    @Environment(\.managedObjectContext) private var context
    
    @FetchRequest private var entries: FetchedResults<EntryModel>
    
    @AppStorage("unread-only-feed-detail") private var unreadOnly: Bool = true
    
    @State private var markAllAsReadDialogPresented: Bool = false
    
    private var filteredEntries: [EntryModel] {
        entries.uniqued(on: \.url).filter { unreadOnly ? $0.read == false : true }
    }
    
    init(feed: FeedModel) {
        self.feed = feed
        self._entries = FetchRequest(fetchRequest: EntryModel.belonging(to: feed))
    }
    
    var body: some View {
        Group {
            if filteredEntries.isEmpty {
                ContentUnavailableView(
                    label: {
                        Label(
                            title: { Text("You've read all entries") },
                            icon: { Image(systemName: "list.dash") }
                        )
                    }
                )
            } else {
                List {
                    ForEach(filteredEntries) { entry in
                        FeedEntryRowView(entry: entry)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                guard let url = entry.url else { return }
                                navigationState.routeToSafari(
                                    url: url,
                                    onDisappear: {
                                        withAnimation {
                                            entry.read = true
                                            try? context.saveWithRollback()
                                        }
                                    }
                                )
                            }
                            .entrySwipeActions(context: context, entry: entry)
                            .entryContextMenu(context: context, entry: entry)
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    do {
                        guard let feedURL = feed.url else { return }
                        let fetchedFeed = try await feedClient.fetchFeed(feedURL)
                        _ = feed.addNewEntries(fetchedFeed.entries)
                    } catch {
                        flashClient.present(
                            type: .error,
                            message: "Failed refresh feed: \(error.localizedDescription)"
                        )
                    }
                }
            }
        }
        .task {
            do {
                guard let feedURL = feed.url else { return }
                let fetchedFeed = try await feedClient.fetchFeed(feedURL)
                _ = feed.addNewEntries(fetchedFeed.entries)
            } catch {}
        }
        .navigationTitle(feed.title ?? "")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    if cloudSyncState.syncing {
                        ProgressView()
                    }
                    
                    Menu {
                        Section {
                            Toggle(isOn: $unreadOnly) { Text("Unread only") }
                        }
                        
                        Section {
                            Button("Mark all as read...") { markAllAsReadDialogPresented = true }
                                .disabled(entries.filter { !$0.read }.isEmpty)
                            Button("Copy Feed URL") {
                                guard let urlString = feed.url?.absoluteString else { return }
                                clipboardClient.copy(urlString)
                                flashClient.present(
                                    type: .info,
                                    message: "Copied!\n\(urlString)"
                                )
                            }
                        }
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
                    withAnimation {
                        for entry in entries {
                            entry.read = true
                        }
                        try? context.saveWithRollback()
                    }
                }
            ) {
                Text("Confirm")
            }
            Button(role: .cancel, action: {}) { Text("Cancel") }
        }
    }
}
