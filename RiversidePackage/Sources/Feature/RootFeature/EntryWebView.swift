import Models
import SwiftUI
import WebKit

struct EntryWebView: NSViewRepresentable {
    let entry: EntryModel
    
    func makeNSView(context: Context) -> WKWebView {
        WKWebView()
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        guard let url = URL(string: entry.url) else { return }
        let request = URLRequest(url: url)
        webView.load(request)
    }
}
