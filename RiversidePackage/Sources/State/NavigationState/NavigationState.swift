import Models
import Observation
import SwiftUI

@Observable
@MainActor
public final class NavigationState {
    public enum FeedsPresentation: String, Identifiable {
        case addFeed
        
        public var id: String { self.rawValue }
    }
    
    public init() {}
    
    // MARK: - Properties
    
    public var mainTab: MainTab = .stream
    
    public var feedsPath: [FeedsRoute] = []
    public var feedsPresentation: FeedsPresentation? = nil
    
    // MARK: - Methods
    
    public func routeToAddFeed() {
        mainTab = .feeds
        feedsPresentation = .addFeed
    }
    
    public func routeToFeedDetail(feed: FeedModel) async {
        mainTab = .feeds
        feedsPath = []
        
        try? await Task.sleep(for: .milliseconds(300))
        feedsPath.append(.feedDetail(feed: feed))
    }
}
