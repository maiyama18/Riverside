import Models
import SwiftData
import SwiftUI
import UIComponents

private extension View {
    func listRow(
        selected: Bool,
        onTapped: @escaping () -> Void,
        onMarkAsRead: @escaping () -> Void,
        onUnsubscribe: (() -> Void)?
    ) -> some View {
        self
            .foregroundStyle(selected ? .white : .primary)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(selected ? .teal : .clear)
                    .padding(.horizontal, -4)
                    .padding(.vertical, -2)
            )
            .contentShape(Rectangle())
            .onTapGesture(perform: onTapped)
            .contextMenu {
                Button("Mark all as read") {
                    onMarkAsRead()
                }
                
                if let onUnsubscribe {
                    Button(role: .destructive) {
                        onUnsubscribe()
                    } label: {
                        Text("Unsubscribe")
                    }
                }
            }
    }
}

struct SidebarListView: View {
    @Binding var selectedFeedID: PersistentIdentifier?
    
    @Environment(\.modelContext) private var context
    
    @Query(FeedModel.all) private var feeds: [FeedModel]
    
    private var sortedFeeds: [FeedModel] {
        feeds.sorted(by: { $0.unreadCount > $1.unreadCount })
    }
    
    var body: some View {
        List(selection: $selectedFeedID) {
            Section {
                Text("All")
                    .badge(feeds.map(\.unreadCount).reduce(into: 0) { $0 += $1 })
                    .listRow(
                        selected: selectedFeedID == nil,
                        onTapped: { selectedFeedID = nil },
                        onMarkAsRead: {
                            for feed in sortedFeeds {
                                feed.markAll(read: true)
                            }
                        },
                        onUnsubscribe: nil
                    )
            }
            
            Section {
                ForEach(sortedFeeds) { feed in
                    HStack {
                        FeedImage(
                            url: feed.imageURL.flatMap(URL.init(string:)),
                            size: 18
                        )
                        
                        Text(feed.title)
                    }
                    .badge(feed.unreadCount)
                    .listRow(
                        selected: selectedFeedID == feed.id,
                        onTapped: { selectedFeedID = feed.id },
                        onMarkAsRead: { feed.markAll(read: true) },
                        onUnsubscribe: { context.delete(feed) }
                    )
                }
            }
            .selectionDisabled()
        }
        .badgeProminence(.decreased)
    }
}

#Preview {
    SidebarListView(selectedFeedID: .constant(nil))
}
