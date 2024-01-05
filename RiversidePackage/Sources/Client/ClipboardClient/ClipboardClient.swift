import Dependencies
import UIKit

public struct ClipboardClient: Sendable {
    public var copy: @Sendable (String) -> Void
    public var copiedString: @Sendable () -> String?
}

extension ClipboardClient {
    public static let live: ClipboardClient = ClipboardClient(
        copy: { UIPasteboard.general.string = $0 },
        copiedString: { UIPasteboard.general.string }
    )
}

extension ClipboardClient: DependencyKey {
    public static let liveValue: ClipboardClient = .live
}

extension DependencyValues {
    public var clipboardClient: ClipboardClient {
        get { self[ClipboardClient.self] }
        set { self[ClipboardClient.self] = newValue }
    }
}
