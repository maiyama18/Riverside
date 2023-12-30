import Foundation

public struct Feed {
    public struct Entry {
        public let url: URL
        public let title: String
        public let publishedAt: Date
        public let content: String?
    }

    public let url: URL
    public let title: String
    public let overview: String?
    public let entries: [Entry]
}

