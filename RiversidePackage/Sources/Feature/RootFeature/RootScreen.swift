import Dependencies
import FeedUseCase
import FlashClient
import Models
import SwiftData
import SwiftUI

public struct RootScreen: View {
    @AppStorage("unread-only") private var unreadOnly: Bool = true
    
    @Dependency(\.feedUseCase) private var feedUseCase
    @Dependency(\.flashClient) private var flashClient
    
    @Environment(\.modelContext) private var context
    
    @State private var selectedFeedID: PersistentIdentifier? = nil
    @State private var selectedEntryID: PersistentIdentifier? = nil
    @State private var refreshing: Bool = false
    
    @Query(EntryModel.all) private var entries: [EntryModel]
    
    public init() {}
    
    private var selectedEntry: EntryModel? {
        guard let selectedEntryID else { return nil }
        return entries.first(where: { $0.id == selectedEntryID })
    }    
    
    public var body: some View {
        NavigationSplitView {
            SidebarListView(selectedFeedID: $selectedFeedID)
        } content: {
            EntryListView(
                allEntries: entries,
                unreadOnly: unreadOnly,
                selectedFeedID: $selectedFeedID,
                selectedEntryID: $selectedEntryID
            )
            .navigationTitle("Riverside")
        } detail: {
            if let selectedEntry {
                EntryWebView(entry: selectedEntry)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack {
                    Button {
                        Task {
                            refreshing = true
                            defer { refreshing = false }
                            do {
                                try await feedUseCase.addNewEpisodesForAllFeeds(context, true)
                            } catch {
                                flashClient.present(.error, "Failed to refresh feeds: \(error.localizedDescription)")
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(refreshing)
                    
                Toggle(isOn: $unreadOnly) {
                    Text("Unread only")
                }
                .toggleStyle(.checkbox)
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
    }
}

#Preview {
    RootScreen()
}
