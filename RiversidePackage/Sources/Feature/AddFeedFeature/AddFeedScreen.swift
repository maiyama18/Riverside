import Dependencies
import FeedClient
import Models
import SwiftData
import SwiftUI
import Utilities

public struct AddFeedScreen: View {
    @State private var text: String = ""
    @State private var feedState: FetchState<Feed?> = .fetched(nil)
    @State private var localFeed: FeedModel? = nil
    
    @Dependency(\.feedClient) private var feedClient
    @Environment(\.modelContext) private var context
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("URL", text: $text, prompt: Text("https://..."))
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("Blog/Feed URL")
                        .textCase(nil)
                } footer: {
                    if case .fetching = feedState {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 24)
                    }
                }
                
                Section {
                    switch feedState {
                    case .fetching:
                        EmptyView()
                    case .fetched(let feed):
                        if let feed {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(feed.title)
                                    Text(feed.url.absoluteString)
                                        .foregroundStyle(.secondary)
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Button {
                                    addFeed()
                                } label: {
                                    if localFeed == nil {
                                        Image(systemName: "plus")
                                            .padding(.vertical, 8)
                                            .padding(.leading, 8)
                                    } else {
                                        Text("Already added")
                                            .font(.caption)
                                    }
                                }
                                .disabled(localFeed != nil)
                            }
                        }
                    case .failed(let error):
                        HStack {
                            Image(systemName: "xmark.octagon")
                                .font(.title)
                                .foregroundStyle(.red)
                            
                            VStack(alignment: .leading) {
                                Text("Failed to fetch feed.")
                                Text(error.localizedDescription)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .navigationTitle("Add feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Material.ultraThin, for: .navigationBar)
            .task(id: text) {
                await fetchFeed()
            }
            .ifDebug {
                $0.toolbar {
                    ToolbarItem(placement: .navigation) {
                        Menu("", systemImage: "ladybug") {
                            Button("maiyama4 (html)") {
                                text = "https://maiyama4.hatenablog.com"
                            }
                            Button("maiyama4 (rss)") {
                                text = "https://maiyama4.hatenablog.com/rss"
                            }
                            Button("jxck (atom)") {
                                text = "https://blog.jxck.io/feeds/atom.xml"
                            }
                            Button("jessesquires (json)") {
                                text = "https://www.jessesquires.com/feed.json"
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func fetchFeed() async  {
        guard let url = URL(string: text), url.isValid() else { return }
        
        try? await Task.sleep(for: .milliseconds(300))
        
        feedState = .fetching
        do {
            let feed = try await feedClient.fetch(url)
            withAnimation {
                feedState = .fetched(feed)
            }
            
            localFeed = try fetchFeedFromLocal(urlString: url.absoluteString)
        } catch {
            if !Task.isCancelled {
                withAnimation {
                    feedState = .failed(error)
                }
            }
        }
    }
    
    private func addFeed() {
        guard case .fetched(let feed) = feedState, let feed else { return }
        let (feedModel, entryModels) = feed.toModel()
        
        do {
            guard try fetchFeedFromLocal(urlString: feedModel.url) == nil else {
                print("Already added")
                return
            }
            
            context.insert(feedModel)
            try context.save()
            for entryModel in entryModels {
                if try fetchEntryFromLocal(urlString: entryModel.url) == nil {
                    feedModel.entries.append(entryModel)
                }
            }
            
            text = ""
            feedState = .fetched(nil)
        } catch {
            context.rollback()
            print(error)
        }
    }
    
    private func fetchFeedFromLocal(urlString: String) throws -> FeedModel? {
        try context.fetch(
            FetchDescriptor<FeedModel>(predicate: #Predicate { $0.url == urlString })
        ).first
    }
    
    private func fetchEntryFromLocal(urlString: String) throws -> EntryModel? {
        try context.fetch(
            FetchDescriptor<EntryModel>(predicate: #Predicate { $0.url == urlString })
        ).first
    }
}

#Preview { @MainActor in
    AddFeedScreen()
        .modelContainer(previewContainer)
}
