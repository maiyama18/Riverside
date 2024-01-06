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
    
    var body: some View {
        List(selection: $selectedFeedID) {
            Section {
                Text("All")
                    .listRow(
                        selected: selectedFeedID == nil,
                        onTapped: { selectedFeedID = nil }
                    )
            }
            
            Section {
                ForEach(feeds) { feed in
                    HStack {
                        FeedImage(
                            url: feed.imageURL.flatMap(URL.init(string:)),
                            size: 18
                        )
                        
                        Text(feed.title)
                    }
                    .listRow(
                        selected: selectedFeedID == feed.id,
                        onTapped: { selectedFeedID = feed.id }
                    )
                }
            }
            .selectionDisabled()
        }
    }
}

#Preview {
    SidebarListView(selectedFeedID: .constant(nil))
}
