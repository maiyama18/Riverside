import Dependencies
import Logging
import FlashClient
import SwiftUI

public struct LogScreen: View {
    enum SearchScope: Hashable {
        case all
        case category(LogCategory)
    }
    
    @State private var allLogEntries: [LogEntry] = []
    @State private var searchScope: SearchScope = .all
    @State private var query: String = ""
    @State private var loading: Bool = false
    
    @Dependency(\.flashClient) private var flashClient
    
    private let logStore = LogStore()
    
    public init() {}
    
    private var visibleEntries: [LogEntry] {
        let scopedEntries: [LogEntry]
        switch searchScope {
        case .all:
            scopedEntries = allLogEntries
        case .category(let category):
            scopedEntries = allLogEntries.filter { $0.category == category }
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
                    Picker(selection: $searchScope) {
                        Text("all").tag(SearchScope.all)
                        ForEach(LogCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(SearchScope.category(category))
                        }
                    } label: {
                        Text("Category")
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
