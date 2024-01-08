import ClipboardClient
import Dependencies
import Models
import SwiftData
import SwiftUI
import UIComponents

private struct ListRowModifier: ViewModifier {
    let entry: EntryModel
    
    @Dependency(\.clipboardClient) private var clipboardClient
    
    func body(content: Content) -> some View {
        content
            .contextMenu {
                Button {
                    clipboardClient.copy(entry.url)
                } label: {
                    Text("Copy URL")
                }
                
                Button {
                    entry.read.toggle()
                } label: {
                    Text(entry.read ? "Mark as unread" : "Mark as read")
                }
            }
    }
}

private extension View {
    func listRow(entry: EntryModel) -> some View {
        modifier(ListRowModifier(entry: entry))
    }
}

struct EntryListView: View {
    var allEntries: [EntryModel]
    var unreadOnly: Bool
    
    @Binding var selectedFeedID: PersistentIdentifier?
    @Binding var selectedEntryID: PersistentIdentifier?
    
    private var filteredEntries: [EntryModel] {
        let unreadFilteredEntries = allEntries
            .filter { entry in
                if entry.id == selectedEntryID { return true }
                return unreadOnly ? entry.read == false : true
            }
        guard let selectedFeedID else { return unreadFilteredEntries }
        return unreadFilteredEntries.filter { $0.feed?.id == selectedFeedID }
    }
    
    var body: some View {
        List(selection: $selectedEntryID) {
            if selectedFeedID == nil {
                let sections = StreamSectionBuilder.build(
                    entries: filteredEntries
                )
                ForEach(sections, id: \.publishedDate) { section in
                    Section {
                        ForEach(section.entries) { entry in
                            StreamEntryRowView(
                                entry: entry,
                                onFeedTapped: { selectedFeedID = $0.id }
                            )
                            .listRow(entry: entry)
                        }
                    } header: {
                        Text(section.publishedDate.formatted(date: .numeric, time: .omitted))
                            .foregroundStyle(.orange)
                    }
                }
            } else {
                ForEach(filteredEntries) { entry in
                    FeedEntryRowView(entry: entry)
                        .listRow(entry: entry)
                }
            }
        }
        .animation(.default, value: filteredEntries)
        .onChange(of: selectedEntryID) { _, selectedEntryID in
            guard let entry = allEntries.first(where: { $0.id == selectedEntryID }) else {
                return
            }
            entry.read = true
        }
    }
}
