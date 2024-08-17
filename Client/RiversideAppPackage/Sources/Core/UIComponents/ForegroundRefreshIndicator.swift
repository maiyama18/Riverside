import ForegroundRefreshState
import SwiftUI

public struct ForegroundRefreshIndicator: View {
    @Environment(ForegroundRefreshState.self) private var foregroundRefreshState
    
    public init() {}
    
    public var body: some View {
        if foregroundRefreshState.state == .refreshing {
            ProgressView()
                .progressViewStyle(.circular)
        } else {
            EmptyView()
        }
    }
}
