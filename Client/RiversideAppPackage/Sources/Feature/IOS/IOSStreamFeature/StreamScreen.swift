import Algorithms
import CloudSyncState
import CoreData
import Dependencies
import Entities
import FlashClient
import ForegroundRefreshState
import NavigationState
import SwiftUI
import UIComponents
import Utilities

@MainActor
public struct StreamScreen: View {
    @Environment(CloudSyncState.self) private var cloudSyncState
    @Environment(ForegroundRefreshState.self) private var foregroundRefreshState
    @Environment(NavigationState.self) private var navigationState
    @Environment(\.managedObjectContext) private var context

    @Dependency(\.flashClient) private var flashClient
    
    @FetchRequest(fetchRequest: EntryModel.all) private var entries: FetchedResults<EntryModel>
    @FetchRequest(fetchRequest: FeedModel.all) private var feeds: FetchedResults<FeedModel>
    
    @AppStorage("unread-only-stream") private var unreadOnly: Bool = true
    
    @State private var markAllAsReadDialogPresented: Bool = false
    
    private var uniquedEntries: [EntryModel] {
        entries.uniqued(on: \.url)
    }
    
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
                                VStack(spacing: 12) {
                                    Button {
                                        navigationState.routeToSubscribeFeed()
                                    } label: {
                                        Text("Add feed")
                                    }
                                    
                                    refreshButton
                                }
                                .padding(.top, 12)
                            }
                        )
                    } else {
                        ContentUnavailableView(
                            label: {
                                Label(
                                    title: { Text("You've read all entries") },
                                    icon: { Image(systemName: "list.dash") }
                                )
                            },
                            actions: {
                                refreshButton
                                    .padding(.top, 12)
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
                                    .entrySwipeActions(context: context, entry: entry)
                                    .entryContextMenu(context: context, entry: entry)
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
                                }
                            } header: {
                                Text(section.publishedDate.formatted(date: .numeric, time: .omitted))
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await forceRefresh()
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        ForegroundRefreshIndicator()
                        
                        Menu {
                            Toggle(isOn: $unreadOnly) { Text("Unread only") }
                            Button("Mark all as read...") { markAllAsReadDialogPresented = true }
                                .disabled(entries.filter { !$0.read }.isEmpty)
                        } label: {
                            Image(systemName: "ellipsis")
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    if cloudSyncState.syncing {
                        VStack {
                            Image(systemName: "arrow.clockwise.icloud")
                                .opacity(0.5)
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
    
    private var refreshButton: some View {
        Button {
            Task {
                await forceRefresh()
            }
        } label: {
            if foregroundRefreshState.isRefreshing {
                Text("Refreshing...")
            } else {
                Text("Refresh")
            }
        }
        .disabled(cloudSyncState.syncing || foregroundRefreshState.isRefreshing)
    }
    
    private var sections: [StreamSection] {
        StreamSectionBuilder.build(entries: uniquedEntries.filter({ unreadOnly ? $0.read == false : true }))
    }
    
    private var navigationTitle: String {
        let unreadCount = uniquedEntries.filter { !$0.read }.count
        return unreadCount == 0 ? "Stream" : "Stream (\(unreadCount))"
    }
    
    private func forceRefresh() async {
        do {
            try await foregroundRefreshState.refresh(
                context: context,
                cloudSyncState: cloudSyncState,
                force: true,
                timeout: .seconds(15),
                retryCount: 3
            )
        } catch {
            flashClient.present(
                type: .error,
                message: "Failed refresh feed: \(error.localizedDescription)"
            )
        }
    }
}

#Preview { @MainActor in
    StreamScreen()
        .environment(CloudSyncState())
        .environment(NavigationState())
}
