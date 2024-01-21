import CoreData
import Entities
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

@MainActor
struct SidebarListView: View {
    @Binding var selectedFeedID: ObjectIdentifier?
    
    @Environment(\.managedObjectContext) private var context
    
    @FetchRequest(fetchRequest: FeedModel.all) private var feeds: FetchedResults<FeedModel>
    @FetchRequest(fetchRequest: EntryModel.unreads) private var unreadEntries: FetchedResults<EntryModel>
    
    @State private var unreadCountByFeedURL: [URL?: Int] = [:]
    
    private var sortedFeeds: [FeedModel] {
        feeds.sorted(by: { unreadCount(of: $0) > unreadCount(of: $1) })
    }
    
    private func unreadCount(of feed: FeedModel) -> Int {
        unreadCountByFeedURL[feed.url] ?? 0
    }
    
    var body: some View {
        if sortedFeeds.isEmpty {
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
                        .badge(sortedFeeds.map({ unreadCount(of: $0) }).reduce(into: 0) { $0 += $1 })
                        .listRow(
                            selected: selectedFeedID == nil,
                            onTapped: { selectedFeedID = nil },
                            onMarkAsRead: {
                                for feed in sortedFeeds {
                                    feed.markAll(asRead: true)
                                }
                                try? context.saveWithRollback()
                            },
                            unsubscribe: nil
                        )
                }
                
                Section {
                    ForEach(sortedFeeds) { feed in
                        HStack {
                            FeedImage(
                                url: feed.imageURL,
                                size: 18
                            )
                            
                            Text(feed.title ?? "")
                        }
                        .badge(unreadCount(of: feed))
                        .listRow(
                            selected: selectedFeedID == feed.id,
                            onTapped: { selectedFeedID = feed.id },
                            onMarkAsRead: {
                                feed.markAll(asRead: true)
                                try? context.saveWithRollback()
                            },
                            unsubscribe: .init(
                                message: "Are you sure to unsubscribe '\(feed.title ?? "")'",
                                action: {
                                    context.delete(feed)
                                    try? context.saveWithRollback()
                                }
                            )
                        )
                    }
                }
                .selectionDisabled()
            }
            .badgeProminence(.decreased)
            .onChange(of: unreadEntries.map { $0 }, initial: true) { _, unreadEntries in
                self.unreadCountByFeedURL = Dictionary(
                    grouping: unreadEntries.uniqued(on: \.url),
                    by: { $0.feed?.url }
                )
                .mapValues(\.count)
            }
        }
    }
}
