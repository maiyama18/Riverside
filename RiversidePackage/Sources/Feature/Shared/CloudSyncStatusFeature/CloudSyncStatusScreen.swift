import CloudKit
import CloudSyncState
import SwiftUI

public struct CloudSyncStatusScreen: View {
    @Environment(CloudSyncState.self) private var cloudSyncState
    
    public init() {}
    
    public var body: some View {
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
                            VStack(alignment: .leading) {
                                if let ckError = error as? CKError {
                                    Text(ckError.localizedDescription)
                                    Text("Code: \(ckError.errorCode)")
                                    if let underlying = (ckError.errorUserInfo[NSUnderlyingErrorKey] as? NSError)?.localizedDescription {
                                        Text(underlying)
                                    }
                                } else {
                                    Text(error.localizedDescription)
                                }
                            }
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

// TODO: Preview を追加
