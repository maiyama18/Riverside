import CloudSyncState
import SwiftUI

struct CloudSyncScreen: View {
    @Environment(CloudSyncState.self) private var cloudSyncState
    
    var body: some View {
        List {
            Section {
                statusView(key: "Import", status: cloudSyncState.importStatus)
                statusView(key: "Export", status: cloudSyncState.exportStatus)
            } header: {
                Text("Latest Status")
            }
            
            Section {
                ForEach(cloudSyncState.syncTransactions.sorted(by: { $0.date > $1.date })) { transaction in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(transaction.date.formatted(date: .numeric, time: .standard))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                
                                Group {
                                    switch transaction.type {
                                    case .setup:
                                        Text("Setup")
                                    case .export:
                                        Text("Export")
                                    case .import:
                                        Text("Import")
                                    @unknown default:
                                        Text("Unknown")
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            Group {
                                switch transaction.result {
                                case .success:
                                    Text("Success")
                                        .foregroundStyle(.green)
                                case .failure:
                                    Text("Failed")
                                        .foregroundStyle(.red)
                                }
                            }
                            .font(.callout.bold())
                        }
                        
                        if case .failure(let error) = transaction.result {
                            Text(error.localizedDescription)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
            } header: {
                Text("Transactions")
            }
            
        }
        .navigationTitle("iCloud Sync")
    }

    func statusView(key: String, status: CloudSyncState.SyncStatus) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(key)
                
                Spacer()
                
                Group {
                    switch status {
                    case .notStarted:
                        Text("Not Started")
                            .foregroundStyle(.secondary)
                    case .syncing:
                        Text("Syncing")
                            .foregroundStyle(.secondary)
                    case .succeeded:
                        Text("Success")
                            .foregroundStyle(.green)
                    case .failed:
                        Text("Failed")
                            .foregroundStyle(.red)
                    }
                }
                .font(.callout.bold())
            }
            
            if case .failed(_, let error) = status {
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }
}

#Preview {
    CloudSyncScreen()
        .environment({
            let state = CloudSyncState()
            
            state.importStatus = .succeeded(date: .now)
            state.exportStatus = .failed(date: .now, error: NSError(domain: "", code: 0))
            
            state.syncTransactions = [
                .init(
                    id: UUID(),
                    type: .setup,
                    date: .now,
                    result: .success(())
                ),
                .init(
                    id: UUID(),
                    type: .setup,
                    date: .now.addingTimeInterval(3),
                    result: .failure(NSError(domain: "", code: 0, userInfo: [:]))
                ),
                
                    .init(
                        id: UUID(),
                        type: .export,
                        date: .now.addingTimeInterval(6),
                        result: .success(())
                    ),
                .init(
                    id: UUID(),
                    type: .export,
                    date: .now.addingTimeInterval(9),
                    result: .failure(NSError(domain: "", code: 0, userInfo: [:]))
                ),
                
                    .init(
                        id: UUID(),
                        type: .import,
                        date: .now.addingTimeInterval(12),
                        result: .success(())
                    ),
                .init(
                    id: UUID(),
                    type: .import,
                    date: .now.addingTimeInterval(15),
                    result: .failure(NSError(domain: "", code: 0, userInfo: [:]))
                ),
            ]
            return state
        }())
}
