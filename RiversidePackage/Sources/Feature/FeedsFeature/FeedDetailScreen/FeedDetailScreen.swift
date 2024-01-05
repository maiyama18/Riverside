import Algorithms
import ClipboardClient
import CloudSyncState
import Dependencies
import FeedUseCase
import FlashClient
import Models
import NavigationState
import SwiftData
import SwiftUI
import Utilities

@MainActor
struct FeedDetailScreen: View {
    private let feed: FeedModel
    
    @Dependency(\.clipboardClient) private var clipboardClient
    @Dependency(\.feedUseCase) private var feedUseCase
    @Dependency(\.flashClient) private var flashClient
    
    @Environment(CloudSyncState.self) private var cloudSyncState
    @Environment(\.modelContext) private var context
    
    @Query private var entries: [EntryModel]
    
    @AppStorage("unread-only-feed-detail") private var unreadOnly: Bool = true
    
    @State private var markAllAsReadDialogPresented: Bool = false
    
    init(feed: FeedModel) {
        self.feed = feed
        self._entries = Query(EntryModel.all(for: feed))
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
                        EntryRowView(entry: entry)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                guard let url = URL(string: entry.url) else { return }
                                entry.read = true
                                showSafari(url: url)
                            }
                            .swipeActions(
                                edge: .trailing,
                                allowsFullSwipe: false
                            ) {
                                Button {
                                    entry.read = true
                                } label: {
                                    Image(systemName: "checkmark")
                                }
                                .tint(.blue)
                                
                                #if DEBUG
                                Button {
                                    context.delete(entry)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .tint(.red)
                                #endif
                            }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    do {
                        try await feedUseCase.addNewEpisodes(feed)
                    } catch {
                        flashClient.present(.error, "Failed refresh feed: \(error.localizedDescription)")
                    }
                }
            }
        }
        .task {
            do {
                try await feedUseCase.addNewEpisodes(feed)
            } catch {
                print(error)
            }
        }
        .navigationTitle(feed.title)
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
                                clipboardClient.copy(feed.url)
                                flashClient.present(.info, "Copied!\n\(feed.url)")
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
                    for entry in entries {
                        entry.read = true
                    }
                }
            ) {
                Text("Confirm")
            }
            Button(role: .cancel, action: {}) { Text("Cancel") }
        }
    }
    
    private var filteredEntries: [EntryModel] {
        entries.uniqued(on: \.url).filter { unreadOnly ? $0.read == false : true }
    }
}
