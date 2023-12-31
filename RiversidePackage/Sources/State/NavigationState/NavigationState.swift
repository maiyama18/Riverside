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
    
    public var mainTab: MainTab = .stream
    
    public var feedsPresentation: FeedsPresentation? = nil
}
