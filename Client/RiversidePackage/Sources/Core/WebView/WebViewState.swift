import Foundation

public struct WebViewState {
    public var canGoBack: Bool = false
    public var canGoForward: Bool = false
    public var loadingProgress: Double = 0
    
    public var url: URL? = nil
    
    public init() {}
}
