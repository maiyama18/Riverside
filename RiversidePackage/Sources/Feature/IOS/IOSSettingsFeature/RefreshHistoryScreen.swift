import CoreData
import Entities
import SwiftUI
import Utilities

struct RefreshHistoryScreen: View {
    @FetchRequest(fetchRequest: BackgroundRefreshHistoryModel.all) private var refreshHistories: FetchedResults<BackgroundRefreshHistoryModel>
    
    var body: some View {
        List {
            ForEach(refreshHistories, id: \.id) { history in
                if let startedAt = history.startedAt {
                    Text(DateFormatter.log.string(from: startedAt))
                } else {
                    Text("nil")
                }
            }
            .font(.callout)
        }
        .navigationTitle("Background Refresh History")
        .navigationBarTitleDisplayMode(.inline)
    }
}
