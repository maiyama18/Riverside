import Dependencies
import FeedClient
import FlashClient
import Models
import SwiftData
import SwiftUI
import Utilities

@MainActor
public struct AddFeedScreen: View {
    @State private var text: String = ""
    @State private var feedState: FetchState<Feed?> = .fetched(nil)
    
    @Query(FeedModel.all) private var feeds: [FeedModel]
    
    @Dependency(\.feedClient) private var feedClient
    @Dependency(\.flashClient) private var flashClient
    
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
                            FeedSummaryView(
                                feed: feed,
                                feedAlreadyAdded: currentFeedAlreadyAdded,
                                onAddTapped: { addFeed() }
                            )
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
    
    private var currentFeedAlreadyAdded: Bool {
        guard case .fetched(let feed) = feedState, let feed else {
            return false
        }
        let addedFeedURLs = feeds.map(\.url).compactMap(URL.init(string:))
        return addedFeedURLs.contains(where: { $0.isSame(as: feed.url) })
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
            guard !currentFeedAlreadyAdded else {
                print("Already added")
                return
            }
            
            context.insert(feedModel)
            try context.save()
            for (i, entryModel) in entryModels.enumerated() {
                entryModel.read = i >= 3
                entryModel.feed = feedModel
            }
            
            text = ""
            feedState = .fetched(nil)
            
            flashClient.present(.info, "'\(feedModel.title)' is added")
        } catch {
            context.rollback()
            flashClient.present(.error, "Failed to add feed: \(error.localizedDescription)")
        }
    }
}

#Preview { @MainActor in
    AddFeedScreen()
        .modelContainer(previewContainer())
}
