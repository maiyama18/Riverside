import SwiftUI

public extension View {
    func ifDebug(transform: (Self) -> some View) -> some View {
        #if DEBUG
        transform(self)
        #else
        self
        #endif
    }
    
    func onForeground(action: @escaping @Sendable () async -> Void) -> some View {
        modifier(OnForegroundModifier(action: action))
    }
}

struct OnForegroundModifier: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    
    let action: () async -> Void
    
    func body(content: Content) -> some View {
        content
            .onChange(of: scenePhase, initial: true) { _, scenePhase in
                if scenePhase == .active {
                    Task {
                        await action()
                    }
                }
            }
    }
}
