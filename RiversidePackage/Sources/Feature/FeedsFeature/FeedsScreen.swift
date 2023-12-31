import AddFeedFeature
import NavigationState
import SwiftUI

public struct FeedsScreen: View {
    @Environment(NavigationState.self) private var navigationState
    
    public init() {}
    
    public var body: some View {
        @Bindable var navigationState = navigationState
        
        NavigationStack {
            VStack {
                Text("Feeds")
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        navigationState.feedsPresentation = .addFeed
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $navigationState.feedsPresentation) { presentation in
                switch presentation {
                case .addFeed:
                    AddFeedScreen()
                }
            }
        }
    }
}
