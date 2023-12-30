import Dependencies
import FeedClient
import SwiftUI
import Utilities

public struct AddFeedScreen: View {
    @State private var text: String = ""
    @State private var feed: FetchState<Feed?> = .fetched(nil)
    
    @Dependency(\.feedClient) private var feedClient
    
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
                    if case .fetching = feed {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 24)
                    }
                }
                
                Section {
                    switch feed {
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
                                    print("Add")
                                } label: {
                                    Image(systemName: "plus")
                                        .padding(.vertical, 8)
                                        .padding(.leading, 8)
                                }
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
                guard let url = URL(string: text), url.isValid else { return }
                
                try? await Task.sleep(for: .milliseconds(300))
                
                feed = .fetching
                do {
                    let feed = try await feedClient.fetch(url)
                    withAnimation {
                        self.feed = .fetched(feed)
                    }
                } catch {
                    withAnimation {
                        feed = .failed(error)
                    }
                }
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
}

#Preview {
    AddFeedScreen()
}
