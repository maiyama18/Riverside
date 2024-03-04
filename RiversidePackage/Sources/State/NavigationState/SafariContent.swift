import Foundation

public struct SafariContent: Equatable {
    public static func == (lhs: SafariContent, rhs: SafariContent) -> Bool {
        lhs.url == rhs.url
    }
    
    public let url: URL
    public let onDisappear: () -> Void
}
