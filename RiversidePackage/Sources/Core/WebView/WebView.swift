import Combine
import SwiftUI
import WebKit

@MainActor
public struct WebView: NSViewRepresentable {
    private let url: URL?
    
    private let wkWebView: WKWebView = .init()
    
    @Binding public var state: WebViewState
    @Binding public var action: WebViewAction?
    
    public init(
        url: URL?,
        state: Binding<WebViewState>,
        action: Binding<WebViewAction?>
    ) {
        self.url = url
        self._state = state
        self._action = action
    }

    public func makeNSView(context: Context) -> WKWebView {
        wkWebView.navigationDelegate = context.coordinator
        
        context.coordinator.observation = wkWebView.observe(\.estimatedProgress, options: [.new]) { _, _ in
            Task { @MainActor in
                state.loadingProgress = wkWebView.estimatedProgress
            }
        }
        return wkWebView
    }
    
    public func goBack() {
        if wkWebView.canGoBack {
            wkWebView.goBack()
        }
    }
    
    public func goForward() {
        if wkWebView.canGoForward {
            wkWebView.goForward()
        }
    }

    public func updateNSView(_ webView: WKWebView, context: Context) {
        if let url, webView.url == nil {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        switch action {
        case .goBack:
            webView.goBack()
        case .goForward:
            webView.goForward()
        case .refresh:
            webView.reload()
        case nil:
            break
        }
        action = nil
    }

    @MainActor
    public class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        var observation: NSKeyValueObservation? = nil

        init(_ parent: WebView) {
            self.parent = parent
        }
        
        deinit {
            observation = nil
        }
        
        nonisolated public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            Task { @MainActor in
                parent.state.canGoBack = webView.canGoBack
                parent.state.canGoForward = webView.canGoForward
                parent.state.url = webView.url
            }
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}
