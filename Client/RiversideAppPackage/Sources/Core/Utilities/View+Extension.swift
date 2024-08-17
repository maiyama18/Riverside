import SwiftUI

extension View {
    public func ifDebug(transform: (Self) -> some View) -> some View {
        #if DEBUG
        transform(self)
        #else
        self
        #endif
    }
    
    public func onForeground(action: @escaping @Sendable () async -> Void) -> some View {
        modifier(OnForegroundModifier(action: action))
    }
    
    public func onBackground(action: @escaping @Sendable () async -> Void) -> some View {
        modifier(OnBackgroundModifier(action: action))
    }
}

#if os(iOS)
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
#elseif os(macOS)
import AppKit
struct OnForegroundModifier: ViewModifier {
    let action: () async -> Void
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)) { _ in
                Task {
                    await action()
                }
            }
    }
}
#endif

#if os(iOS)
struct OnBackgroundModifier: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    
    let action: () async -> Void
    
    func body(content: Content) -> some View {
        content
            .onChange(of: scenePhase, initial: true) { b, scenePhase in
                if scenePhase == .background {
                    Task {
                        await action()
                    }
                }
            }
    }
}
#elseif os(macOS)
import AppKit
struct OnBackgroundModifier: ViewModifier {
    let action: () async -> Void
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.willResignActiveNotification)) { _ in
                Task {
                    await action()
                }
            }
    }
}
#endif
