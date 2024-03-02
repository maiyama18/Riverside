import CoreData
import Entities
import SwiftUI
import Utilities

struct RefreshHistoryScreen: View {
    @FetchRequest(fetchRequest: BackgroundRefreshHistoryModel.all) private var refreshHistories: FetchedResults<BackgroundRefreshHistoryModel>
    
    var body: some View {
        List {
            ForEach(refreshHistories, id: \.id) { history in
                row(history: history)
            }
        }
        .navigationTitle("Background Refresh History")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private func row(history: BackgroundRefreshHistoryModel) -> some View {
        if let addedEntryTitles = history.addedEntryTitles,
           !addedEntryTitles.isEmpty {
            DisclosureGroup {
                ForEach(addedEntryTitles, id: \.self) { title in
                    Text(title)
                        .font(.caption)
                }
            } label: {
                rowLabel(history: history)
            }
        } else {
            rowLabel(history: history)
        }
    }
    
    func rowLabel(history: BackgroundRefreshHistoryModel) -> some View {
        VStack(alignment: .leading) {
            Text(history.startedAt.map { DateFormatter.log.string(from: $0) } ?? "nil")
                .font(.callout)
            
            if let finishedAt = history.finishedAt {
                Text("-" + DateFormatter.log.string(from: finishedAt))
            }
            if let errorMessage = history.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            } else {
                Text("\(history.addedEntryTitles?.count ?? 0) entries added")
            }
        }
        .font(.caption)
    }
}
