import Models
import SwiftData
import SwiftUI
import UIComponents

struct EntryListView: View {
    var entries: [EntryModel]
    var unreadOnly: Bool
    
    @Binding var selectedFeedID: PersistentIdentifier?
    @Binding var selectedEntryID: PersistentIdentifier?
    
    var body: some View {
        List(selection: $selectedEntryID) {
            if selectedFeedID == nil {
                let sections = StreamSectionBuilder.build(
                    entries: entries,
                    unreadOnly: unreadOnly
                )
                ForEach(sections, id: \.publishedDate) { section in
                    Section {
                        ForEach(section.entries) { entry in
                            StreamEntryRowView(
                                entry: entry,
                                onFeedTapped: { selectedFeedID = $0.id }
                            )
                        }
                    } header: {
                        Text(section.publishedDate.formatted(date: .numeric, time: .omitted))
                            .foregroundStyle(.orange)
                    }
                }
            } else {
                ForEach(entries) { entry in
                    FeedEntryRowView(entry: entry)
                }
            }
        }
    }
}
