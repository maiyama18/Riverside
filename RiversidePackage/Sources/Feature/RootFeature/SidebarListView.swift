import Models
import SwiftData
import SwiftUI
import UIComponents

struct ListRowModifier: ViewModifier {
    struct Unsubscribe {
        let message: String
        let action: () -> Void
    }
    
    let selected: Bool
    let onTapped: () -> Void
    let onMarkAsRead: () -> Void
    let unsubscribe: Unsubscribe?
    
    @State private var unsubscribeAlertPresented: Bool = false
   
    func body(content: Content) -> some View {
        content
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
                
                if unsubscribe != nil {
                    Button(role: .destructive) {
                        unsubscribeAlertPresented = true
                    } label: {
                        Text("Unsubscribe")
                    }
                }
            }
            .alert(
                unsubscribe?.message ?? "",
                isPresented: $unsubscribeAlertPresented,
                actions: {
                    Button(role: .destructive) {
                        unsubscribe?.action()
                    } label: {
                        Text("Unsubscribe")
                    }

                    Button(role: .cancel) {} label: {
                        Text("Cancel")
                    }
                }
            )
    }
}

private extension View {
    func listRow(
        selected: Bool,
        onTapped: @escaping () -> Void,
        onMarkAsRead: @escaping () -> Void,
        unsubscribe: ListRowModifier.Unsubscribe?
    ) -> some View {
        modifier(ListRowModifier(selected: selected, onTapped: onTapped, onMarkAsRead: onMarkAsRead, unsubscribe: unsubscribe))
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
        if feeds.isEmpty {
            ContentUnavailableView(
                label: {
                    Label(
                        title: { Text("No following feed") },
                        icon: { Image(systemName: "list.dash") }
                    )
                },
                actions: {
                    SubscribeFeedButton {
                        Text("Subscribe")
                    }
                }
            )
        } else {
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
                            unsubscribe: nil
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
                            unsubscribe: .init(
                                message: "Are you sure to unsubscribe '\(feed.title)'",
                                action: { context.delete(feed) }
                            )
                        )
                    }
                }
                .selectionDisabled()
            }
            .badgeProminence(.decreased)
        }
    }
}

//#Preview {
//    SidebarListView(selectedFeedID: .constant(nil))
//}
