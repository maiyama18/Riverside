import Combine
import Entities
import SwiftUI
import WebView

@MainActor
struct EntryContentView: View {
    let entry: EntryModel
    
    @State private var state: WebViewState = .init()
    @State private var action: WebViewAction? = nil
    
    init(entry: EntryModel) {
        self.entry = entry
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                HStack(spacing: 8) {
                    Button {
                        action = .goBack
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(!state.canGoBack)
                    
                    Button {
                        action = .goForward
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(!state.canGoForward)
                    
                    Button {
                        action = .refresh
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 8) {
                    Button {
                        guard let url = state.url else { return }
                        NSWorkspace.shared.open(url)
                    } label: {
                        Image(systemName: "globe")
                    }
                    .disabled(state.url == nil)
                }
            }
            .padding(8)
            
            WebView(
                url: entry.url,
                state: $state,
                action: $action
            )
            .overlay(alignment: .top) {
                LinearProgressView(progress: state.loadingProgress)
            }
        }
    }
}

struct LinearProgressView: View {
    let progress: Double
    let height: CGFloat = 4
    
    @State private var width: CGFloat? = nil
    
    var body: some View {
        HStack {
            if let width {
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: width * progress)
                    .opacity((progress == 0 || progress == 1) ? 0 : 1)
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear { width = proxy.size.width }
                    .onChange(of: proxy.size.width) { _, width in self.width = width }
            }
        }
    }
}
