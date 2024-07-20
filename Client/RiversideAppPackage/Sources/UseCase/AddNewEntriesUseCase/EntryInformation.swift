import Entities
import FeedClient
import Foundation

public struct EntryInformation: Sendable {
    public let title: String
    public let feedTitle: String
    public let publishedAt: Date
}
