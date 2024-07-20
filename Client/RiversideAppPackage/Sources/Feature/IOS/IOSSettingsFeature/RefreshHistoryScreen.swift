import CoreData
import Entities
import SwiftUI
import Utilities

@MainActor
struct RefreshHistoryScreen: View {
    @FetchRequest(fetchRequest: BackgroundRefreshHistoryModel.all) private var refreshHistories: FetchedResults<BackgroundRefreshHistoryModel>
    
    var body: some View {
        List {
            ForEach(refreshHistories, id: \.id) { history in
                row(history: history)
            }
            .listRowSeparatorTint(.black)
        }
        .navigationTitle("Background Refresh History")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    func row(history: BackgroundRefreshHistoryModel) -> some View {
        VStack(alignment: .leading) {
            Text(history.startedAt.map { DateFormatter.log.string(from: $0) } ?? "nil")
                .font(.callout)
            
            if let finishedAt = history.finishedAt {
                Text("- " + DateFormatter.log.string(from: finishedAt))
            }
            
            if let addedEntryTitles = history.addedEntryTitles, !addedEntryTitles.isEmpty {
                VStack(alignment: .leading) {
                    Text("\(addedEntryTitles.count) entries added")
                        .font(.callout)
                    ForEach(addedEntryTitles, id: \.self) { title in
                        Text("- " + title)
                    }
                }
                .padding(.top, 4)
            }
            
            if let errorMessage = history.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .padding(.top, 4)
            }
            
            if let warningMessages = history.warningMessages, !warningMessages.isEmpty {
                ForEach(warningMessages, id: \.self) { message in
                    Text(message)
                }
                .foregroundStyle(.yellow)
                .padding(.top, 4)
            }
        }
        .font(.caption)
    }
}
