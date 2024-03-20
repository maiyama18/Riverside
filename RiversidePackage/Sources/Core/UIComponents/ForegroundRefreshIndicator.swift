import ForegroundRefreshState
import SwiftUI

public struct ForegroundRefreshIndicator: View {
    @Environment(ForegroundRefreshState.self) private var foregroundRefreshState
    
    public init() {}
    
    public var body: some View {
        switch foregroundRefreshState.state {
        case .idle:
            EmptyView()
        case .refreshing(let progress):
            Image(systemName: "circle")
                .hidden()
                .overlay {
                    Circle()
                        .subtracting(Circle().inset(by: 8))
                        .fill(
                            AngularGradient(
                                stops: [
                                    .init(color: .accentColor, location: 0),
                                    .init(color: .accentColor, location: progress),
                                    .init(color: .gray.opacity(0.3), location: progress),
                                    .init(color: .gray.opacity(0.3), location: 1),
                                ],
                                center: .center,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(270)
                            )
                        )
                }
            
        }
    }
}

#Preview {
    ForEach([0, 0.25, 0.5, 0.75, 1], id: \.self) { progress in
        ForegroundRefreshIndicator()
            .environment({
                let state = ForegroundRefreshState()
                state.state = .refreshing(progress: progress)
                return state
            }())
            .frame(width: 24)
    }
}
