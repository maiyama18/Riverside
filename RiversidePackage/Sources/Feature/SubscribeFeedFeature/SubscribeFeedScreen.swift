import Dependencies
import FeedClient
import FeedUseCase
import FlashClient
import Models
import SwiftData
import SwiftUI
import Utilities

@MainActor
public struct SubscribeFeedScreen: View {
    @State private var text: String = ""
    @State private var feedState: FetchState<Feed?> = .fetched(nil)
    
    @Query(FeedModel.all) private var feeds: [FeedModel]
    
    @Dependency(\.feedClient) private var feedClient
    @Dependency(\.feedUseCase) private var feedUseCase
    @Dependency(\.flashClient) private var flashClient
    
    @Environment(\.modelContext) private var context
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        #if os(iOS)
                        TextField("URL", text: $text, prompt: Text("https://..."))
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                        #else
                        TextField("URL", text: $text, prompt: Text("https://..."))
                        #endif
                        
                        Button {
                            text = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .tint(.secondary)
                                .padding(4)
                                .offset(x: 4)
                        }
                        .buttonStyle(.plain)
                    }
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
                                feedAlreadySubscribed: currentFeedAlreadySubscribed,
                                onSubscribeTapped: {
                                    Task { await subscribeFeed() }
                                }
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
            .navigationTitle("Subscribe feed")
            .iOSInlineNavigationBar()
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
    
    private var currentFeedAlreadySubscribed: Bool {
        guard case .fetched(let feed) = feedState, let feed else {
            return false
        }
        let subscribedFeedURLs = feeds.map(\.url).compactMap(URL.init(string:))
        return subscribedFeedURLs.contains(where: { $0.isSame(as: feed.url) })
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
    
    private func subscribeFeed() async {
        guard case .fetched(let feed) = feedState, let feed else { return }
        
        do {
            _ = try await feedUseCase.subscribeFeed(context, .feed(feed))
            
            text = ""
            feedState = .fetched(nil)
            
            flashClient.present(.info, "'\(feed.title)' is subscribed")
        } catch {
            context.rollback()
            flashClient.present(.error, "Failed to add feed: \(error.localizedDescription)")
        }
    }
}

private extension View {
    func iOSInlineNavigationBar() -> some View {
        #if os(iOS)
        self
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Material.ultraThin, for: .navigationBar)
        #else
        self
        #endif
    }
}

#Preview { @MainActor in
    SubscribeFeedScreen()
        .modelContainer(previewContainer())
}
