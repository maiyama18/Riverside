import Models
import SwiftData
import SwiftUI
import UIComponents

struct EntryListView: View {
    var entries: [EntryModel]
    
    @Binding var selectedFeedID: PersistentIdentifier?
    @Binding var selectedEntryID: PersistentIdentifier?
    
    var body: some View {
        List(selection: $selectedEntryID) {
            ForEach(entries) { entry in
                if selectedFeedID != nil {
                    FeedEntryRowView(entry: entry)
                } else {
                    StreamEntryRowView(
                        entry: entry,
                        onFeedTapped: { selectedFeedID = $0.id }
                    )
                }
            }
        }
    }
}
