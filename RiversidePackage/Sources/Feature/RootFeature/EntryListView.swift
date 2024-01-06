import Models
import SwiftData
import SwiftUI

struct EntryListView: View {
    var entries: [EntryModel]
    
    @Binding var selectedEntryID: PersistentIdentifier?
    
    var body: some View {
        List(selection: $selectedEntryID) {
            ForEach(entries) { entry in
                Text(entry.title)
                    .onTapGesture {
                        selectedEntryID = entry.id
                    }
            }
        }
    }
}
