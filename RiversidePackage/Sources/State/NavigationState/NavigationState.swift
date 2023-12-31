import Models
import Observation
import SwiftUI

@Observable
@MainActor
public final class NavigationState {
    public enum FeedsPresentation: String, Identifiable {
        case subscribeFeed
        
        public var id: String { self.rawValue }
    }
    
    public init() {}
    
    // MARK: - Properties
    
    public var mainTab: MainTab = .stream
    
    public var feedsPath: [FeedsRoute] = []
    public var feedsPresentation: FeedsPresentation? = nil
    
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
}
