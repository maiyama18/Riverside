import Models
import SwiftData
import SwiftUI
import UIComponents

private extension View {
    func listRow(selected: Bool, onTapped: @escaping () -> Void) -> some View {
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
    }
}

struct SidebarListView: View {
    @Binding var selectedFeedID: PersistentIdentifier?
    
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
                        onTapped: { selectedFeedID = nil }
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
                        onTapped: { selectedFeedID = feed.id }
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
