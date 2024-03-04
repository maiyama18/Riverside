import Entities
import Observation
import SwiftUI

@Observable
@MainActor
public final class NavigationState {
    public enum FeedsPresentation: String, Identifiable {
        case subscribeFeed
        
        public var id: String { self.rawValue }
    }
    
    public enum SettingsPresentation: String, Identifiable {
        case licenses
        
        public var id: String { self.rawValue }
    }
    
    public init() {}
    
    // MARK: - Properties
    
    public var mainTab: MainTab = .stream
    
    public var feedsPath: [FeedsRoute] = []
    public var feedsPresentation: FeedsPresentation? = nil
    
    public var settingsPath: [SettingsRoute] = []
    public var settingsPresentation: SettingsPresentation? = nil
    
    public var safariContent: SafariContent? = nil
    
    // MARK: - Methods
    
    public func routeToSubscribeFeed() {
        mainTab = .feeds
        feedsPresentation = .subscribeFeed
    }
    
    public func routeToFeedDetail(feed: FeedModel) async {
        mainTab = .feeds
        feedsPath = []
        
        try? await Task.sleep(for: .milliseconds(300))
        feedsPath.append(.feedDetail(feed: feed))
    }
    
    public func routeToSafari(url: URL, onDisappear: @escaping () -> Void) {
        safariContent = SafariContent(url: url, onDisappear: onDisappear)
    }
}
