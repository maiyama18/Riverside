import Dependencies

public struct ClipboardClient: Sendable {
    public var copy: @Sendable (String) -> Void
    public var copiedString: @Sendable () -> String?
}

#if canImport(UIKit)
import UIKit

extension ClipboardClient {
    public static let live: ClipboardClient = ClipboardClient(
        copy: { UIPasteboard.general.string = $0 },
        copiedString: { UIPasteboard.general.string }
    )
}
#endif

#if canImport(AppKit)
import AppKit

extension ClipboardClient {
    public static let live: ClipboardClient = ClipboardClient(
        copy: {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString($0, forType: .string)
        },
        copiedString: {
            NSPasteboard.general.string(forType: .string)
        }
    )
}
#endif

extension ClipboardClient: DependencyKey {
    public static let liveValue: ClipboardClient = .live
}

extension DependencyValues {
    public var clipboardClient: ClipboardClient {
        get { self[ClipboardClient.self] }
        set { self[ClipboardClient.self] = newValue }
    }
}
