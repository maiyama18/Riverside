import Models
import SwiftData
import SwiftUI

extension View {
    public func entrySwipeActions(context: ModelContext, entry: EntryModel) -> some View {
        swipeActions(edge: .trailing, allowsFullSwipe: false) {
            entryMenu(context: context, entry: entry)
        }
    }
    
    public func entryContextMenu(context: ModelContext, entry: EntryModel) -> some View {
        contextMenu {
            entryMenu(context: context, entry: entry)
        }
    }
    
    @ViewBuilder
    private func entryMenu(context: ModelContext, entry: EntryModel) -> some View {
        if entry.read {
            Button {
                entry.read = false
            } label: {
                Label {
                    Text("Mark as unread")
                } icon: {
                    Image(systemName: "arrow.counterclockwise")
                }
            }
            .tint(.gray)
        } else {
            Button {
                entry.read = true
            } label: {
                Label {
                    Text("Mark as read")
                } icon: {
                    Image(systemName: "checkmark")
                }
            }
            .tint(.blue)
        }
        
        #if DEBUG
        Button {
            context.delete(entry)
        } label: {
            Label {
                Text("Delete")
            } icon: {
                Image(systemName: "trash")
            }
        }
        .tint(.red)
        #endif
    }
}
