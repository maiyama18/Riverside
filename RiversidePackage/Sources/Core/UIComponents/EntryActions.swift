import Entities
import CoreData
import SwiftUI

extension View {
    public func entrySwipeActions(context: NSManagedObjectContext, entry: EntryModel) -> some View {
        swipeActions(edge: .trailing, allowsFullSwipe: false) {
            entryMenu(context: context, entry: entry)
        }
    }
    
    public func entryContextMenu(context: NSManagedObjectContext, entry: EntryModel) -> some View {
        contextMenu {
            entryMenu(context: context, entry: entry)
        }
    }
    
    @ViewBuilder
    private func entryMenu(context: NSManagedObjectContext, entry: EntryModel) -> some View {
        if entry.read {
            Button {
                withAnimation {
                    entry.read = false
                    try? context.saveWithRollback()
                }
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
                withAnimation {
                    entry.read = true
                    try? context.saveWithRollback()
                }
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
            withAnimation {
                context.delete(entry)
                try? context.saveWithRollback()
            }
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
