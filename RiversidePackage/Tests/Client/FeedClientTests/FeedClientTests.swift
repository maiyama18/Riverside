@testable import FeedClient

import SwiftData
import TestHelpers
import XCTest

final class FeedClientTests: XCTestCase {
    // HTML
    private static let maiyama4HTMLURL = URL(string: "https://maiyama4.hatenablog.com")!
    
    // RSS
    private static let maiyama4RSSURL = URL(string: "https://maiyama4.hatenablog.com/rss")!
    private static let iOSDevWeeklyURL = URL(string: "https://iosdevweekly.com/issues.rss")!
    private static let iOSCodeReviewURL = URL(string: "https://ioscodereview.com/feed.xml/")!
    private static let r7kamuraURL = URL(string: "https://r7kamura.com/feed.xml")!
    private static let swiftUILabURL = URL(string: "https://swiftui-lab.com/feed/")!
    private static let zennSwiftURL = URL(string: "https://zenn.dev/topics/swift/feed")!
    private static let qiitaSwiftURL = URL(string: "https://qiita.com/tags/swift/feed")!
    private static let stackoverflowSwiftURL = URL(string: "https://stackoverflow.com/feeds/tag?tagnames=swift&sort=newest")!
    private static let phaNoteURL = URL(string: "https://note.com/pha/rss")!
    private static let naoyaSizumeURL = URL(string: "https://sizu.me/naoya/rss")!

    // Atom
    private static let maiyama4AtomURL = URL(string: "https://maiyama4.hatenablog.com/feed")!
    private static let jessesquiresAtomURL = URL(string: "https://www.jessesquires.com/feed.xml")!
    private static let andanteURL = URL(string: "https://ofni.necocen.info/atom")!
    private static let jxckURL = URL(string: "https://blog.jxck.io/feeds/atom.xml")!

    // JSON
    private static let jessesquiresJSONURL = URL(string: "https://www.jessesquires.com/feed.json")!

    private var client: FeedClient!

    override func setUp() async throws {
        enum ResponseType {
            case rssFeed
            case atomFeed
            case jsonFeed
            case html
            
            var contentType: String {
                switch self {
                case .rssFeed, .atomFeed:
                    "application/rss+xml"
                case .jsonFeed:
                    "application/json"
                case .html:
                    "text/html"
                }
            }
            
            var resourceExtension: String {
                switch self {
                case .rssFeed, .atomFeed:
                    "xml"
                case .jsonFeed:
                    "json"
                case .html:
                    "html"
                }
            }
        }
        
        func setFeedData(to responses: inout [URL: Result<StubResponse, Error>], url: URL, responseType: ResponseType, resourceName: String) throws {
            let resourceURL = try XCTUnwrap(Bundle.module.url(forResource: resourceName, withExtension: responseType.resourceExtension))
            let data = try Data(contentsOf: resourceURL)
            
            responses[url] = .success(
                .init(
                    statusCode: 200,
                    data: data,
                    headerFields: ["Content-Type": responseType.contentType]
                )
            )
        }
        
        try await super.setUp()

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        let urlSession = URLSession(configuration: config)

        var responses: [URL: Result<StubResponse, Error>] = [:]

        // HTML
        try setFeedData(to: &responses, url: Self.maiyama4HTMLURL, responseType: .html, resourceName: "maiyama4")
        
        // RSS
        try setFeedData(to: &responses, url: Self.maiyama4RSSURL, responseType: .rssFeed, resourceName: "maiyama4_rss")
        try setFeedData(to: &responses, url: Self.iOSDevWeeklyURL, responseType: .rssFeed, resourceName: "iOSDevWeekly")
        try setFeedData(to: &responses, url: Self.iOSCodeReviewURL, responseType: .rssFeed, resourceName: "iOSCodeReview")
        try setFeedData(to: &responses, url: Self.r7kamuraURL, responseType: .rssFeed, resourceName: "r7kamura")
        try setFeedData(to: &responses, url: Self.swiftUILabURL, responseType: .rssFeed, resourceName: "swiftUILab")
        try setFeedData(to: &responses, url: Self.zennSwiftURL, responseType: .rssFeed, resourceName: "zennSwift")
        try setFeedData(to: &responses, url: Self.qiitaSwiftURL, responseType: .rssFeed, resourceName: "qiitaSwift")
        try setFeedData(to: &responses, url: Self.stackoverflowSwiftURL, responseType: .rssFeed, resourceName: "stackoverflowSwift")
        try setFeedData(to: &responses, url: Self.phaNoteURL, responseType: .rssFeed, resourceName: "phaNote")
        try setFeedData(to: &responses, url: Self.naoyaSizumeURL, responseType: .rssFeed, resourceName: "naoyaSizume")

        // Atom
        try setFeedData(to: &responses, url: Self.maiyama4AtomURL, responseType: .atomFeed, resourceName: "maiyama4_atom")
        try setFeedData(to: &responses, url: Self.jessesquiresAtomURL, responseType: .atomFeed, resourceName: "jessesquires")
        try setFeedData(to: &responses, url: Self.andanteURL, responseType: .atomFeed, resourceName: "andante")
        try setFeedData(to: &responses, url: Self.jxckURL, responseType: .atomFeed, resourceName: "jxck")

        // JSON
        try setFeedData(to: &responses, url: Self.jessesquiresJSONURL, responseType: .jsonFeed, resourceName: "jessesquires")

        URLProtocolStub.setResponses(responses)
        client = .live(urlSession: urlSession)
    }
    
    // MARK: - HTML -> Atom

    func test_maiyama4_html() async throws {
        let feed = try await client.fetch(Self.maiyama4HTMLURL)
        XCTAssertEqual(feed.url, Self.maiyama4HTMLURL)
        XCTAssertEqual(feed.title, "maiyama log")
        XCTAssertEqual(feed.overview, "")

        XCTAssertEqual(feed.entries.count, 4)
        let entry = try XCTUnwrap(feed.entries.first)
        XCTAssertEqual(entry.url, URL(string: "https://maiyama4.hatenablog.com/entry/2023/12/27/142625"))
        XCTAssertEqual(entry.title, "個人開発の SwiftUI アプリのアーキテクチャを MVVM から MV にした")
        XCTAssertEqual(entry.content?.count, 500)
        XCTAssertEqual(entry.content?.prefix(50), "概要 SwiftUI Advent Calendar 2023 の 21 日目です。 最近趣味で i")
        try XCTAssertEqual(entry.publishedAt, Date("2023-12-27T14:26:25+09:00", strategy: .iso8601))
    }

    // MARK: - RSS

    func test_maiyama4_rss() async throws {
        let feed = try await client.fetch(Self.maiyama4RSSURL)
        XCTAssertEqual(feed.url, Self.maiyama4RSSURL)
        XCTAssertEqual(feed.title, "maiyama log")
        XCTAssertEqual(feed.overview, "")

        XCTAssertEqual(feed.entries.count, 4)
        let entry = try XCTUnwrap(feed.entries.first)
        XCTAssertEqual(entry.url, URL(string: "https://maiyama4.hatenablog.com/entry/2023/12/27/142625"))
        XCTAssertEqual(entry.title, "個人開発の SwiftUI アプリのアーキテクチャを MVVM から MV にした")
        XCTAssertEqual(entry.content?.count, 500)
        XCTAssertEqual(entry.content?.prefix(50), "概要 SwiftUI Advent Calendar 2023 の 21 日目です。 最近趣味で i")
        try XCTAssertEqual(entry.publishedAt, Date("2023-12-27T14:26:25+09:00", strategy: .iso8601))
    }

    func test_iOSDevWeekly() async throws {
        let feed = try await client.fetch(Self.iOSDevWeeklyURL)
        XCTAssertEqual(feed.url, Self.iOSDevWeeklyURL)
        XCTAssertEqual(feed.title, "iOS Dev Weekly")
        XCTAssertEqual(feed.overview, "Subscribe to a hand-picked round-up of the best iOS development links every week. Curated by Dave Verwer and published every Friday. Free.")

        XCTAssertEqual(feed.entries.count, 10)
        let entry = try XCTUnwrap(feed.entries.first)
        XCTAssertEqual(entry.url, URL(string: "https://iosdevweekly.com/issues/641"))
        XCTAssertEqual(entry.title, "iOS Dev Weekly - Issue 641 - Dec 29th 2023")
        XCTAssertEqual(entry.content?.count, 500)
        XCTAssertEqual(entry.content?.prefix(50), "Comment Here we are at the end of another year, an")
        try XCTAssertEqual(entry.publishedAt, Date("2023-12-30T00:00:00+09:00", strategy: .iso8601))
    }

    func test_iOSCodeReview() async throws {
        let feed = try await client.fetch(Self.iOSCodeReviewURL)
        XCTAssertEqual(feed.url, Self.iOSCodeReviewURL)
        XCTAssertEqual(feed.title, " iOS Code Review | Curated code improvement tips")
        XCTAssertEqual(feed.overview, "Bi-weekly newsletter amplifying code improvement tips from the Apple developer community in a bite-sized format. Swift, Objective-C, iOS, macOS, SwiftUI, UIKit and more.  Curated by Marina Gornostaeva and published every other Thursday. ")

        XCTAssertEqual(feed.entries.count, 97)
        let entry = try XCTUnwrap(feed.entries.first)
        XCTAssertEqual(entry.url, URL(string: "https://ioscodereview.com/issues/issue-61/"))
        XCTAssertEqual(entry.title, " Issue #61 ")
        XCTAssertEqual(entry.content?.count, 500)
        XCTAssertEqual(entry.content?.prefix(50), "Hi there, welcome to the 61st issue of iOS Code Re")
        try XCTAssertEqual(entry.publishedAt, Date("2023-12-07T22:38:43+09:00", strategy: .iso8601))
    }

    func test_r7kamura() async throws {
        let feed = try await client.fetch(Self.r7kamuraURL)
        XCTAssertEqual(feed.url, Self.r7kamuraURL)
        XCTAssertEqual(feed.title, "r7kamura.com")
        XCTAssertEqual(feed.overview, "r7kamuraの生活やプログラミングに関するウェブサイト")

        XCTAssertEqual(feed.entries.count, 20)
        let entry = try XCTUnwrap(feed.entries.first)
        XCTAssertEqual(entry.url, URL(string: "https://r7kamura.com/articles/2023-12-29-vscode-ruby-light"))
        XCTAssertEqual(entry.title, "vscode-ruby-light開発日記 - Prismパーサー導入編")
        XCTAssertEqual(entry.content?.count, 500)
        XCTAssertEqual(entry.content?.prefix(50), "vscode-ruby-lightの開発中に考えたことを書いていきます。今回は、内部で利用しているR")
        try XCTAssertEqual(entry.publishedAt, Date("2023-12-29T00:00:00+09:00", strategy: .iso8601))
    }

    func test_swiftUILab() async throws {
        let feed = try await client.fetch(Self.swiftUILabURL)
        XCTAssertEqual(feed.url, Self.swiftUILabURL)
        XCTAssertEqual(feed.title, "The SwiftUI Lab")
        XCTAssertEqual(feed.overview, "When the documentation is missing, we experiment.")

        XCTAssertEqual(feed.entries.count, 25)
        let entry = try XCTUnwrap(feed.entries.first)
        XCTAssertEqual(entry.url, URL(string: "https://swiftui-lab.com/swiftui-animations-part7/?utm_source=rss&utm_medium=rss&utm_campaign=swiftui-animations-part7"))
        XCTAssertEqual(entry.title, "Advanced SwiftUI Animations – Part 7: PhaseAnimator")
        XCTAssertEqual(entry.content?.count, 500)
        XCTAssertEqual(entry.content?.prefix(50), "In part 6 of the Advanced SwiftUI Animations serie")
        try XCTAssertEqual(entry.publishedAt, Date("2023-10-31T00:41:54+09:00", strategy: .iso8601))
    }

    func test_zennSwift() async throws {
        let feed = try await client.fetch(Self.zennSwiftURL)
        XCTAssertEqual(feed.url, Self.zennSwiftURL)
        XCTAssertEqual(feed.title, "Zennの「Swift」のフィード")
        XCTAssertEqual(feed.overview, "Zennのトピック「Swift」のRSSフィードです")

        XCTAssertEqual(feed.entries.count, 20)
        let entry = try XCTUnwrap(feed.entries.first)
        XCTAssertEqual(entry.url, URL(string: "https://zenn.dev/dena/articles/f5f6f9f9b89695"))
        XCTAssertEqual(entry.title, "[SF-0001] Calendar Sequence Enumeration の解説")
        XCTAssertEqual(entry.content?.count, 298)
        XCTAssertEqual(entry.content?.prefix(50), "この記事はSwiftWednesday Advent Calendar 2023の21日目の記事です")
        try XCTAssertEqual(entry.publishedAt, Date("2023-12-29T12:17:53+09:00", strategy: .iso8601))
    }

    func test_qiitaSwift() async throws {
        let feed = try await client.fetch(Self.qiitaSwiftURL)
        XCTAssertEqual(feed.url, Self.qiitaSwiftURL)
        XCTAssertEqual(feed.title, "Swiftタグが付けられた新着記事 - Qiita")
        XCTAssertEqual(feed.overview, "")

        XCTAssertEqual(feed.entries.count, 4)
        let entry = try XCTUnwrap(feed.entries.first)
        XCTAssertEqual(entry.url, URL(string: "https://qiita.com/masakihori/items/54d4209a700ec4584083"))
        XCTAssertEqual(entry.title, "[Swift]むりやりPoint-Free Style")
        XCTAssertEqual(entry.content?.count, 103)
        XCTAssertEqual(entry.content?.prefix(50), "Point-Free Styleとは 関数を渡す関数を使う時にTrailing closureを使わ")
        try XCTAssertEqual(entry.publishedAt, Date("2023-12-30T09:55:43+09:00", strategy: .iso8601))
    }

    func test_stackoverflowSwift() async throws {
        let feed = try await client.fetch(Self.stackoverflowSwiftURL)
        XCTAssertEqual(feed.url, Self.stackoverflowSwiftURL)
        XCTAssertEqual(feed.title, "Newest questions tagged swift - Stack Overflow")
        XCTAssertEqual(feed.overview, "most recent 30 from stackoverflow.com")

        XCTAssertEqual(feed.entries.count, 30)
        let entry = try XCTUnwrap(feed.entries.first)
        XCTAssertEqual(entry.url, URL(string: "https://stackoverflow.com/questions/77734853/swiftui-scrollview-entire-phone-screen"))
        XCTAssertEqual(entry.title, "SwiftUI ScrollView entire phone screen")
        XCTAssertEqual(entry.content?.count, 500)
        XCTAssertEqual(entry.content?.prefix(50), "I'm trying to figure out how to create a Scrolling")
        try XCTAssertEqual(entry.publishedAt, Date("2023-12-30T13:23:26+09:00", strategy: .iso8601))
    }

    func test_phaNote() async throws {
        let feed = try await client.fetch(Self.phaNoteURL)
        XCTAssertEqual(feed.url, Self.phaNoteURL)
        XCTAssertEqual(feed.title, "pha")
        XCTAssertEqual(feed.overview, "毎日寝て暮らしたい。読んだ本の感想やだらだらした日常のことを書いている日記です。毎回最初の1日分は無料で読めるようにしています。雑誌などに書いた文章もここに載せたりします。")

        XCTAssertEqual(feed.entries.count, 25)
        let entry = try XCTUnwrap(feed.entries.first)
        XCTAssertEqual(entry.url, URL(string: "https://note.com/pha/n/n0b28a1a3b1b0"))
        XCTAssertEqual(entry.title, "11月25日（土）～12月1日（金） 調べずに海沿いを")
        XCTAssertEqual(entry.content?.count, 180)
        XCTAssertEqual(entry.content?.prefix(50), "11月25日（土）起きると疲れている。Titleに文フリで出した2冊を納品してから、店へ。明日の日記")
        try XCTAssertEqual(entry.publishedAt, Date("2023-12-22T19:23:55+09:00", strategy: .iso8601))
    }

    func test_naoyaSizume() async throws {
        let feed = try await client.fetch(Self.naoyaSizumeURL)
        XCTAssertEqual(feed.url, Self.naoyaSizumeURL)
        XCTAssertEqual(feed.title, "naoya - しずかなインターネット")
        XCTAssertEqual(feed.overview, "naoya さんの記事一覧のRSSフィードです")

        XCTAssertEqual(feed.entries.count, 3)
        let entry = try XCTUnwrap(feed.entries.first)
        XCTAssertEqual(entry.url, URL(string: "https://sizu.me/naoya/posts/7vxkuwvowo0z"))
        XCTAssertEqual(entry.title, "自分を救うプログラミング")
        XCTAssertEqual(entry.content?.count, 201)
        XCTAssertEqual(entry.content?.prefix(50), "子どものころは絵を描くのが好きだった。 学校の休み時間は、クラスメートはみな外にサッカーをしにいって")
        try XCTAssertEqual(entry.publishedAt, Date("2023-12-28T07:39:45+09:00", strategy: .iso8601))
    }

    // MARK: - Atom
    
    func test_maiyama4_atom() async throws {
        let feed = try await client.fetch(Self.maiyama4AtomURL)
        XCTAssertEqual(feed.url, Self.maiyama4AtomURL)
        XCTAssertEqual(feed.title, "maiyama log")
        XCTAssertEqual(feed.overview, "")

        XCTAssertEqual(feed.entries.count, 4)
        let entry = try XCTUnwrap(feed.entries.first)
        XCTAssertEqual(entry.url, URL(string: "https://maiyama4.hatenablog.com/entry/2023/12/27/142625"))
        XCTAssertEqual(entry.title, "個人開発の SwiftUI アプリのアーキテクチャを MVVM から MV にした")
        XCTAssertEqual(entry.content?.count, 500)
        XCTAssertEqual(entry.content?.prefix(50), "概要 SwiftUI Advent Calendar 2023 の 21 日目です。 最近趣味で i")
        try XCTAssertEqual(entry.publishedAt, Date("2023-12-27T14:26:25+09:00", strategy: .iso8601))
    }

    func test_jessesquires_atom() async throws {
        let feed = try await client.fetch(Self.jessesquiresAtomURL)
        XCTAssertEqual(feed.url, Self.jessesquiresAtomURL)
        XCTAssertEqual(feed.title, "Jesse Squires")
        XCTAssertEqual(feed.overview, "Turing complete with a stack of 0xdeadbeef")

        XCTAssertEqual(feed.entries.count, 30)
        let entry = try XCTUnwrap(feed.entries.first)
        XCTAssertEqual(entry.url, URL(string: "https://www.jessesquires.com/blog/2023/12/29/reading-list-2023/"))
        XCTAssertEqual(entry.title, "A list of books I read in 2023")
        XCTAssertEqual(entry.content?.count, 500)
        XCTAssertEqual(entry.content?.prefix(50), "Continuing another tradition, here are the books I")
        try XCTAssertEqual(entry.publishedAt, Date("2023-12-30T05:02:14+09:00", strategy: .iso8601))
    }

    func test_andante() async throws {
        let feed = try await client.fetch(Self.andanteURL)
        XCTAssertEqual(feed.url, Self.andanteURL)
        XCTAssertEqual(feed.title, "andante")
        XCTAssertEqual(feed.overview, "個人的な日記です")

        XCTAssertEqual(feed.entries.count, 10)
        let entry = try XCTUnwrap(feed.entries.first)
        XCTAssertEqual(entry.url, URL(string: "https://ofni.necocen.info/5006"))
        XCTAssertEqual(entry.title, "1229")
        XCTAssertEqual(entry.content?.count, 0)
        try XCTAssertEqual(
            entry.publishedAt.timeIntervalSince1970,
            Date("2023-12-30T01:23:48+09:00", strategy: .iso8601).timeIntervalSince1970,
            accuracy: 1
        )
    }

    func test_jxck() async throws {
        let feed = try await client.fetch(Self.jxckURL)
        XCTAssertEqual(feed.url, Self.jxckURL)
        XCTAssertEqual(feed.title, "blog.jxck.io")
        XCTAssertEqual(feed.overview, "")

        XCTAssertEqual(feed.entries.count, 185)
        let entry = try XCTUnwrap(feed.entries.first)
        XCTAssertEqual(entry.url, URL(string: "https://blog.jxck.io/entries/2023-12-30/after-deprecation.html"))
        XCTAssertEqual(entry.title, "3PCA 最終日: 3rd Party Cookie 亡き後の Web はどうなるか?")
        XCTAssertEqual(entry.content?.count, 308)
        XCTAssertEqual(entry.content?.prefix(50), "このエントリは、 3rd Party Cookie Advent Calendar の最終日である。")
        try XCTAssertEqual(entry.publishedAt, Date("2023-12-30T09:00:00+09:00", strategy: .iso8601))
    }

    // MARK: - JSON

    func test_jessesquires_json() async throws {
        let feed = try await client.fetch(Self.jessesquiresJSONURL)
        XCTAssertEqual(feed.url, Self.jessesquiresJSONURL)
        XCTAssertEqual(feed.title, "Jesse Squires")
        XCTAssertEqual(feed.overview, "Turing complete with a stack of 0xdeadbeef")

        XCTAssertEqual(feed.entries.count, 31)
        let entry = try XCTUnwrap(feed.entries.first)
        XCTAssertEqual(entry.url, URL(string: "https://www.jessesquires.com/blog/2023/12/29/reading-list-2023/"))
        XCTAssertEqual(entry.title, "A list of books I read in 2023")
        XCTAssertEqual(entry.content?.count, 500)
        XCTAssertEqual(entry.content?.prefix(50), "Continuing another tradition, here are the books I")
        try XCTAssertEqual(entry.publishedAt, Date("2023-12-30T05:02:14+09:00", strategy: .iso8601))
    }
}
