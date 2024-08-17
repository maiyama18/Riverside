import Dependencies
import RiversideLogging
import FlashClient
import OSLog
import SwiftUI

public struct LogScreen: View {
    enum SearchScope: Hashable {
        case all
        case category(LogCategory)
    }
    
    @State private var allLogEntries: [LogEntry] = []
    @State private var searchScope: SearchScope = .all
    @State private var logLevel: OSLogEntryLog.Level = .notice
    @State private var query: String = ""
    @State private var loading: Bool = false
    
    @Dependency(\.flashClient) private var flashClient
    
    private let logStore = LogStore()
    
    public init() {}
    
    private var visibleEntries: [LogEntry] {
        let filteredEntries = allLogEntries.filter { $0.level >= logLevel }
        
        let scopedEntries: [LogEntry]
        switch searchScope {
        case .all:
            scopedEntries = filteredEntries
        case .category(let category):
            scopedEntries = filteredEntries.filter { $0.category == category }
        }
        
        let trimmedQuery = query.trimmingCharacters(in: .whitespaces)
        return trimmedQuery.isEmpty ? scopedEntries : scopedEntries.filter { $0.message.range(of: trimmedQuery, options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive]) != nil }
    }
    
    public var body: some View {
        Group {
            if loading {
                ProgressView()
                    .controlSize(.extraLarge)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Picker(selection: $searchScope) {
                            Text("all").tag(SearchScope.all)
                            ForEach(LogCategory.allCases, id: \.self) { category in
                                Text(category.rawValue).tag(SearchScope.category(category))
                            }
                        } label: {
                            Text("Category")
                        }
                        
                        Picker(selection: $logLevel) {
                            ForEach(OSLogEntryLog.Level.allCases, id: \.rawValue) { logLevel in
                                Text(logLevel.string).tag(logLevel)
                            }
                        } label: {
                            Text("Level")
                        }
                    }
                    .padding(.horizontal, 8)

                    List {
                        ForEach(visibleEntries, id: \.date) { entry in
                            LogRowView(entry: entry)
                                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                        }
                    }
                    .listStyle(.plain)
                }
                .searchable(text: $query)
            }
        }
        .task {
            guard allLogEntries.isEmpty else { return }
            
            loading = true
            defer { loading = false }
            
            do {
                allLogEntries = try await logStore.getAllLogEntries()
            } catch {
                flashClient.present(type: .error, message: "Failed to fetch logs: \(error)")
            }
        }
        .navigationTitle("Log")
    }
}

extension OSLogEntryLog.Level: CaseIterable {
    public static var allCases: [OSLogEntryLog.Level] {
        [.debug, .info, .notice, .error, .fault]
    }
}

extension OSLogEntryLog.Level: Comparable {
    public static func < (lhs: OSLogEntryLog.Level, rhs: OSLogEntryLog.Level) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension OSLogEntryLog.Level {
    var string: String {
        switch self {
        case .undefined:
            "undefined"
        case .debug:
            "debug"
        case .info:
            "info"
        case .notice:
            "notice"
        case .error:
            "error"
        case .fault:
            "fault"
        @unknown default:
            "unknown"
        }
    }
}
