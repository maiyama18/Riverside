@testable import FeedFetcher

import Foundation
import Vapor
import XCTest

final class FeedFetcherTests: XCTestCase {
    // HTML
    private static let maiyama4HTMLURI = URI(string: "https://maiyama4.hatenablog.com")
    private static let iOSDevWeeklyHTMLURI = URI(string: "https://iosdevweekly.com/issues")
    private static let r7kamuraHTMLURI = URI(string: "https://r7kamura.com/")
    private static let swiftUILabHTMLURI = URI(string: "https://swiftui-lab.com/")
    private static let qiitaHTMLURI = URI(string: "https://qiita.com/")
    private static let stackoverflowSwiftHTMLURI = URI(string: "https://stackoverflow.com/questions/tagged/?tagnames=swift&sort=newest")
    private static let phaNoteHTMLURI = URI(string: "https://note.com/pha/")
    private static let andanteHTMLURI = URI(string: "https://ofni.necocen.info/")
    private static let jxckHTMLURI = URI(string: "https://blog.jxck.io/")
    
    // Favicon
    private static let maiyama4FaviconURI = URI(string: "https://maiyama4.hatenablog.com/icon/favicon")
    private static let r7kamuraFaviconURI = URI(string: "https://r7kamura.com/favicon.ico")
    private static let swiftUILabFaviconURI = URI(string: "https://swiftui-lab.com/favicon.ico")
    
    // RSS
    private static let maiyama4RSSURI = URI(string: "https://maiyama4.hatenablog.com/rss")
    private static let magnoliaURI = URI(string: "https://blog.magnolia.tech/rss")
    private static let iOSDevWeeklyURI = URI(string: "https://iosdevweekly.com/issues.rss")
    private static let iOSCodeReviewURI = URI(string: "https://ioscodereview.com/feed.xml/")
    private static let r7kamuraURI = URI(string: "https://r7kamura.com/feed.xml")
    private static let swiftUILabURI = URI(string: "https://swiftui-lab.com/feed/")
    private static let zennSwiftURI = URI(string: "https://zenn.dev/topics/swift/feed")
    private static let qiitaSwiftURI = URI(string: "https://qiita.com/tags/swift/feed")
    private static let stackoverflowSwiftURI = URI(string: "https://stackoverflow.com/feeds/tag?tagnames=swift&sort=newest")
    private static let phaNoteURI = URI(string: "https://note.com/pha/rss")
    private static let naoyaSizumeURI = URI(string: "https://sizu.me/naoya/rss")
    
    // RDF
    private static let asahiURI = URI(string: "https://www.asahi.com/rss/asahi/newsheadlines.rdf")
    private static let avWatchURI = URI(string: "https://av.watch.impress.co.jp/data/rss/1.0/avw/feed.rdf")
    private static let toiroiroURI = URI(string: "https://toiroiro.blog.jp/index.rdf")

    // Atom
    private static let maiyama4AtomURI = URI(string: "https://maiyama4.hatenablog.com/feed")
    private static let jessesquiresAtomURI = URI(string: "https://www.jessesquires.com/feed.xml")
    private static let andanteURI = URI(string: "https://ofni.necocen.info/atom")
    private static let jxckURI = URI(string: "https://blog.jxck.io/feeds/atom.xml")

    // JSON
    private static let jessesquiresJSONURI = URI(string: "https://www.jessesquires.com/feed.json")

    private var fetcher: FeedFetcher!
    private var app: Application!

    override func setUp() async throws {
        try await super.setUp()

        let responses: [URI: MockResponse] = try [
            // HTML
            Self.maiyama4HTMLURI: .init(type: .html, dataResourceName: "maiyama4"),
            Self.iOSDevWeeklyHTMLURI: .init(type: .html, dataResourceName: "iOSDevWeekly"),
            Self.r7kamuraHTMLURI: .init(type: .html, dataResourceName: "r7kamura"),
            Self.swiftUILabHTMLURI: .init(type: .html, dataResourceName: "swiftUILab"),
            Self.qiitaHTMLURI: .init(type: .html, dataResourceName: "qiita"),
            Self.stackoverflowSwiftHTMLURI: .init(type: .html, dataResourceName: "stackoverflowSwift"),
            Self.phaNoteHTMLURI: .init(type: .html, dataResourceName: "phaNote"),
            Self.andanteHTMLURI: .init(type: .html, dataResourceName: "andante"),
            Self.jxckHTMLURI: .init(type: .html, dataResourceName: "jxck"),
            
            // Favicon
            Self.maiyama4FaviconURI: .init(type: .png, dataResourceName: "dummy"),
            Self.r7kamuraFaviconURI: .init(type: .png, dataResourceName: "dummy"),
            Self.swiftUILabFaviconURI: .init(type: .png, dataResourceName: "dummy"),
            
            // RSS
            Self.maiyama4RSSURI: .init(type: .rssFeed, dataResourceName: "maiyama4_rss"),
            Self.magnoliaURI: .init(type: .rssFeed, dataResourceName: "magnolia"),
            Self.iOSDevWeeklyURI: .init(type: .rssFeed, dataResourceName: "iOSDevWeekly"),
            Self.iOSCodeReviewURI: .init(type: .rssFeed, dataResourceName: "iOSCodeReview"),
            Self.r7kamuraURI: .init(type: .rssFeed, dataResourceName: "r7kamura"),
            Self.swiftUILabURI: .init(type: .rssFeed, dataResourceName: "swiftUILab"),
            Self.zennSwiftURI: .init(type: .rssFeed, dataResourceName: "zennSwift"),
            Self.qiitaSwiftURI: .init(type: .rssFeed, dataResourceName: "qiitaSwift"),
            Self.stackoverflowSwiftURI: .init(type: .rssFeed, dataResourceName: "stackoverflowSwift"),
            Self.phaNoteURI: .init(type: .rssFeed, dataResourceName: "phaNote"),
            Self.naoyaSizumeURI: .init(type: .rssFeed, dataResourceName: "naoyaSizume"),
            
            // RDF
            Self.asahiURI: .init(type: .rdfFeed, dataResourceName: "asahi"),
            Self.avWatchURI: .init(type: .rdfFeed, dataResourceName: "avWatch"),
            Self.toiroiroURI: .init(type: .rdfFeed, dataResourceName: "toiroiro"),

            // Atom
            Self.maiyama4AtomURI: .init(type: .atomFeed, dataResourceName: "maiyama4_atom"),
            Self.jessesquiresAtomURI: .init(type: .atomFeed, dataResourceName: "jessesquires"),
            Self.andanteURI: .init(type: .atomFeed, dataResourceName: "andante"),
            Self.jxckURI: .init(type: .atomFeed, dataResourceName: "jxck"),

            // JSON
            Self.jessesquiresJSONURI: .init(type: .jsonFeed, dataResourceName: "jessesquires"),
        ]
        
        self.app = try await Application.make(.testing)
        self.fetcher = .init(client: MockClient(eventLoop: app.eventLoopGroup.next(), responses: responses), logger: .init(label: "FeedFetcherTests"))
    }
    
    override func tearDown() {
        app.shutdown()
        super.tearDown()
    }
    
    // MARK: - HTML -> Atom

    func test_maiyama4_html() async throws {
        let feed = try await fetcher.fetch(url: Self.maiyama4HTMLURI.url)
        XCTAssertEqual(feed.url, Self.maiyama4AtomURI.url)
        XCTAssertEqual(feed.title, "maiyama log")
        XCTAssertEqual(feed.overview, "")
        XCTAssertEqual(feed.imageURL, URL(string: "https://maiyama4.hatenablog.com/icon/favicon"))

        XCTAssertEqual(feed.entries.count, 4)
        let entry = try XCTUnwrap(feed.entries.first)
        XCTAssertEqual(entry.url, URL(string: "https://maiyama4.hatenablog.com/entry/2023/12/27/142625"))
        XCTAssertEqual(entry.title, "個人開発の SwiftUI アプリのアーキテクチャを MVVM から MV にした")
        XCTAssertEqual(entry.content?.count, 500)
        XCTAssertEqual(entry.content?.prefix(50), "概要 SwiftUI Advent Calendar 2023 の 21 日目です。 最近趣味で i")
        XCTAssertEqual(entry.publishedAt, Date.fromISO8601String("2023-12-27T14:26:25+09:00"))
    }

    // MARK: - RSS

    func test_maiyama4_rss() async throws {
        let feed = try await fetcher.fetch(url: Self.maiyama4RSSURI.url)
        XCTAssertEqual(feed.url, Self.maiyama4RSSURI.url)
        XCTAssertEqual(feed.title, "maiyama log")
        XCTAssertEqual(feed.overview, "")
        XCTAssertEqual(feed.imageURL, URL(string: "https://maiyama4.hatenablog.com/icon/favicon")!)

        XCTAssertEqual(feed.entries.count, 4)
        let entry = try XCTUnwrap(feed.entries.first)
        XCTAssertEqual(entry.url, URL(string: "https://maiyama4.hatenablog.com/entry/2023/12/27/142625"))
        XCTAssertEqual(entry.title, "個人開発の SwiftUI アプリのアーキテクチャを MVVM から MV にした")
        XCTAssertEqual(entry.content?.count, 500)
        XCTAssertEqual(entry.content?.prefix(50), "概要 SwiftUI Advent Calendar 2023 の 21 日目です。 最近趣味で i")
        XCTAssertEqual(entry.publishedAt, Date.fromISO8601String("2023-12-27T14:26:25+09:00"))
    }
    
    func test_magnolia() async throws {
        let feed = try await fetcher.fetch(url: Self.magnoliaURI.url)
        XCTAssertEqual(feed.url, Self.magnoliaURI.url)
        XCTAssertEqual(feed.title, "Magnolia Tech")
        XCTAssertEqual(feed.overview, "いつもコードのことばかり考えている人のために。")

        XCTAssertEqual(feed.entries.count, 30)
        let entry = try XCTUnwrap(feed.entries.first)
        XCTAssertEqual(entry.url, URL(string: "https://blog.magnolia.tech/entry/2024/01/27/195444"))
        XCTAssertEqual(entry.title, "Keychron Q60 MAXを買った")
        XCTAssertEqual(entry.content?.count, 500)
        XCTAssertEqual(entry.content?.prefix(100), "Keychron Q60 Max QMK/VIA ワイヤレス カスタム メカニカルキーボード（US ANSI 配列） – Keychron Japan 去年は、Keychron Q60はいいぞ！と言い")
        XCTAssertEqual(entry.publishedAt, Date.fromISO8601String("2024-01-27T10:54:44+00:00"))
   }

    func test_iOSDevWeekly() async throws {
        let feed = try await fetcher.fetch(url: Self.iOSDevWeeklyURI.url)
        XCTAssertEqual(feed.url, Self.iOSDevWeeklyURI.url)
        XCTAssertEqual(feed.title, "iOS Dev Weekly")
        XCTAssertEqual(feed.overview, "Subscribe to a hand-picked round-up of the best iOS development links every week. Curated by Dave Verwer and published every Friday. Free.")
        XCTAssertEqual(feed.imageURL, URL(string: "https://dxj7eshgz03ln.cloudfront.net/production/publication/publication_icon/1/favicon_442526aa-1e62-489a-87ac-8f09b5f0f867.png")!)

        XCTAssertEqual(feed.entries.count, 10)
        let entry = try XCTUnwrap(feed.entries.first)
        XCTAssertEqual(entry.url, URL(string: "https://iosdevweekly.com/issues/641"))
        XCTAssertEqual(entry.title, "iOS Dev Weekly - Issue 641 - Dec 29th 2023")
        XCTAssertEqual(entry.content?.count, 500)
        XCTAssertEqual(entry.content?.prefix(50), "Comment Here we are at the end of another year, an")
        XCTAssertEqual(entry.publishedAt, Date.fromISO8601String("2023-12-30T00:00:00+09:00"))
    }

    func test_iOSCodeReview() async throws {
        let feed = try await fetcher.fetch(url: Self.iOSCodeReviewURI.url)
        XCTAssertEqual(feed.url, Self.iOSCodeReviewURI.url)
        XCTAssertEqual(feed.title, " iOS Code Review | Curated code improvement tips")
        XCTAssertEqual(feed.overview, "Bi-weekly newsletter amplifying code improvement tips from the Apple developer community in a bite-sized format. Swift, Objective-C, iOS, macOS, SwiftUI, UIKit and more.  Curated by Marina Gornostaeva and published every other Thursday. ")
        XCTAssertEqual(feed.imageURL, URL(string: "https://ioscodereview.com/favicon.png")!)

        XCTAssertEqual(feed.entries.count, 97)
        let entry = try XCTUnwrap(feed.entries.first)
        XCTAssertEqual(entry.url, URL(string: "https://ioscodereview.com/issues/issue-61/"))
        XCTAssertEqual(entry.title, " Issue #61 ")
        XCTAssertEqual(entry.content?.count, 500)
        XCTAssertEqual(entry.content?.prefix(50), "Hi there, welcome to the 61st issue of iOS Code Re")
        XCTAssertEqual(entry.publishedAt, Date.fromISO8601String("2023-12-07T22:38:43+09:00"))
    }

    func test_r7kamura() async throws {
        let feed = try await fetcher.fetch(url: Self.r7kamuraURI.url)
        XCTAssertEqual(feed.url, Self.r7kamuraURI.url)
        XCTAssertEqual(feed.title, "r7kamura.com")
        XCTAssertEqual(feed.overview, "r7kamuraの生活やプログラミングに関するウェブサイト")
        XCTAssertEqual(feed.imageURL, URL(string: "https://r7kamura.com/favicon.ico")!)
        XCTAssertEqual(feed.entries.count, 20)

        let entry = try XCTUnwrap(feed.entries.first)
        XCTAssertEqual(entry.url, URL(string: "https://r7kamura.com/articles/2023-12-29-vscode-ruby-light"))
        XCTAssertEqual(entry.title, "vscode-ruby-light開発日記 - Prismパーサー導入編")
        XCTAssertEqual(entry.content?.count, 500)
        XCTAssertEqual(entry.content?.prefix(50), "vscode-ruby-lightの開発中に考えたことを書いていきます。今回は、内部で利用しているR")
        XCTAssertEqual(entry.publishedAt, Date.fromISO8601String("2023-12-29T00:00:00+09:00"))
    }

    func test_swiftUILab() async throws {
        let feed = try await fetcher.fetch(url: Self.swiftUILabURI.url)
        XCTAssertEqual(feed.url, Self.swiftUILabURI.url)
        XCTAssertEqual(feed.title, "The SwiftUI Lab")
        XCTAssertEqual(feed.overview, "When the documentation is missing, we experiment.")
        XCTAssertEqual(feed.imageURL, URL(string: "https://swiftui-lab.com/favicon.ico")!)

        XCTAssertEqual(feed.entries.count, 25)
        let entry = try XCTUnwrap(feed.entries.first)
        XCTAssertEqual(entry.url, URL(string: "https://swiftui-lab.com/swiftui-animations-part7/?utm_source=rss&utm_medium=rss&utm_campaign=swiftui-animations-part7"))
        XCTAssertEqual(entry.title, "Advanced SwiftUI Animations – Part 7: PhaseAnimator")
        XCTAssertEqual(entry.content?.count, 500)
        XCTAssertEqual(entry.content?.prefix(50), "In part 6 of the Advanced SwiftUI Animations serie")
        XCTAssertEqual(entry.publishedAt, Date.fromISO8601String("2023-10-31T00:41:54+09:00"))
    }

    func test_zennSwift() async throws {
        let feed = try await fetcher.fetch(url: Self.zennSwiftURI.url)
        XCTAssertEqual(feed.url, Self.zennSwiftURI.url)
        XCTAssertEqual(feed.title, "Zennの「Swift」のフィード")
        XCTAssertEqual(feed.overview, "Zennのトピック「Swift」のRSSフィードです")
        XCTAssertEqual(feed.imageURL, URL(string: "https://storage.googleapis.com/zenn-user-upload/topics/84dd786118.png")!)

        XCTAssertEqual(feed.entries.count, 20)
        let entry = try XCTUnwrap(feed.entries.first)
        XCTAssertEqual(entry.url, URL(string: "https://zenn.dev/dena/articles/f5f6f9f9b89695"))
        XCTAssertEqual(entry.title, "[SF-0001] Calendar Sequence Enumeration の解説")
        XCTAssertEqual(entry.content?.count, 298)
        XCTAssertEqual(entry.content?.prefix(50), "この記事はSwiftWednesday Advent Calendar 2023の21日目の記事です")
        XCTAssertEqual(entry.publishedAt, Date.fromISO8601String("2023-12-29T12:17:53+09:00"))
    }

    func test_qiitaSwift() async throws {
        let feed = try await fetcher.fetch(url: Self.qiitaSwiftURI.url)
        XCTAssertEqual(feed.url, Self.qiitaSwiftURI.url)
        XCTAssertEqual(feed.title, "Swiftタグが付けられた新着記事 - Qiita")
        XCTAssertEqual(feed.overview, "")
        XCTAssertEqual(feed.imageURL, URL(string: "https://cdn.qiita.com/assets/favicons/public/production-c620d3e403342b1022967ba5e3db1aaa.ico")!)

        XCTAssertEqual(feed.entries.count, 4)
        let entry = try XCTUnwrap(feed.entries.first)
        XCTAssertEqual(entry.url, URL(string: "https://qiita.com/masakihori/items/54d4209a700ec4584083"))
        XCTAssertEqual(entry.title, "[Swift]むりやりPoint-Free Style")
        XCTAssertEqual(entry.content?.count, 100)
        XCTAssertEqual(entry.content?.prefix(50), "Point-Free Styleとは 関数を渡す関数を使う時にTrailing closureを使わ")
        XCTAssertEqual(entry.publishedAt, Date.fromISO8601String("2023-12-30T09:55:43+09:00"))
    }

    func test_stackoverflowSwift() async throws {
        let feed = try await fetcher.fetch(url: Self.stackoverflowSwiftURI.url)
        XCTAssertEqual(feed.url, Self.stackoverflowSwiftURI.url)
        XCTAssertEqual(feed.title, "Newest questions tagged swift - Stack Overflow")
        XCTAssertEqual(feed.overview, "most recent 30 from stackoverflow.com")
        XCTAssertEqual(feed.imageURL, URL(string: "https://cdn.sstatic.net/Sites/stackoverflow/Img/favicon.ico?v=ec617d715196")!)

        XCTAssertEqual(feed.entries.count, 30)
        let entry = try XCTUnwrap(feed.entries.first)
        XCTAssertEqual(entry.url, URL(string: "https://stackoverflow.com/questions/77734853/swiftui-scrollview-entire-phone-screen"))
        XCTAssertEqual(entry.title, "SwiftUI ScrollView entire phone screen")
        XCTAssertEqual(entry.content?.count, 500)
        XCTAssertEqual(entry.content?.prefix(50), "I'm trying to figure out how to create a Scrolling")
        XCTAssertEqual(entry.publishedAt, Date.fromISO8601String("2023-12-30T13:23:26+09:00"))
    }

    func test_phaNote() async throws {
        let feed = try await fetcher.fetch(url: Self.phaNoteURI.url)
        XCTAssertEqual(feed.url, Self.phaNoteURI.url)
        XCTAssertEqual(feed.title, "pha")
        XCTAssertEqual(feed.overview, "毎日寝て暮らしたい。読んだ本の感想やだらだらした日常のことを書いている日記です。毎回最初の1日分は無料で読めるようにしています。雑誌などに書いた文章もここに載せたりします。")
        XCTAssertEqual(feed.imageURL, URL(string: "https://assets.st-note.com/poc-image/manual/note-common-images/production/icons/android-chrome-192x192.png")!)

        XCTAssertEqual(feed.entries.count, 25)
        let entry = try XCTUnwrap(feed.entries.first)
        XCTAssertEqual(entry.url, URL(string: "https://note.com/pha/n/n0b28a1a3b1b0"))
        XCTAssertEqual(entry.title, "11月25日（土）～12月1日（金） 調べずに海沿いを")
        XCTAssertEqual(entry.content?.count, 184)
        XCTAssertEqual(entry.content?.prefix(50), "11月25日（土） 起きると疲れている。Titleに文フリで出した2冊を納品してから、店へ。明日の日")
        XCTAssertEqual(entry.publishedAt, Date.fromISO8601String("2023-12-22T19:23:55+09:00"))
    }

    func test_naoyaSizume() async throws {
        let feed = try await fetcher.fetch(url: Self.naoyaSizumeURI.url)
        XCTAssertEqual(feed.url, Self.naoyaSizumeURI.url)
        XCTAssertEqual(feed.title, "naoya - しずかなインターネット")
        XCTAssertEqual(feed.overview, "naoya さんの記事一覧のRSSフィードです")
        XCTAssertEqual(feed.imageURL, URL(string: "https://r2.sizu.me/users/15658/avatar.jpeg?v=1701072017204")!)

        XCTAssertEqual(feed.entries.count, 3)
        let entry = try XCTUnwrap(feed.entries.first)
        XCTAssertEqual(entry.url, URL(string: "https://sizu.me/naoya/posts/7vxkuwvowo0z"))
        XCTAssertEqual(entry.title, "自分を救うプログラミング")
        XCTAssertEqual(entry.content?.count, 201)
        XCTAssertEqual(entry.content?.prefix(50), "子どものころは絵を描くのが好きだった。 学校の休み時間は、クラスメートはみな外にサッカーをしにいって")
        XCTAssertEqual(entry.publishedAt, Date.fromISO8601String("2023-12-28T07:39:45+09:00"))
    }

    // MARK: - Atom
    
    func test_maiyama4_atom() async throws {
        let feed = try await fetcher.fetch(url: Self.maiyama4AtomURI.url)
        XCTAssertEqual(feed.url, Self.maiyama4AtomURI.url)
        XCTAssertEqual(feed.title, "maiyama log")
        XCTAssertEqual(feed.overview, "")
        XCTAssertEqual(feed.imageURL, URL(string: "https://maiyama4.hatenablog.com/icon/favicon")!)

        XCTAssertEqual(feed.entries.count, 4)
        let entry = try XCTUnwrap(feed.entries.first)
        XCTAssertEqual(entry.url, URL(string: "https://maiyama4.hatenablog.com/entry/2023/12/27/142625"))
        XCTAssertEqual(entry.title, "個人開発の SwiftUI アプリのアーキテクチャを MVVM から MV にした")
        XCTAssertEqual(entry.content?.count, 500)
        XCTAssertEqual(entry.content?.prefix(50), "概要 SwiftUI Advent Calendar 2023 の 21 日目です。 最近趣味で i")
        XCTAssertEqual(entry.publishedAt, Date.fromISO8601String("2023-12-27T14:26:25+09:00"))
    }

    func test_jessesquires_atom() async throws {
        let feed = try await fetcher.fetch(url: Self.jessesquiresAtomURI.url)
        XCTAssertEqual(feed.url, Self.jessesquiresAtomURI.url)
        XCTAssertEqual(feed.title, "Jesse Squires")
        XCTAssertEqual(feed.overview, "Turing complete with a stack of 0xdeadbeef")
        XCTAssertEqual(feed.imageURL, URL(string: "https://www.jessesquires.com/img/logo.png")!)
    
        XCTAssertEqual(feed.entries.count, 30)
        let entry = try XCTUnwrap(feed.entries.first)
        XCTAssertEqual(entry.url, URL(string: "https://www.jessesquires.com/blog/2023/12/29/reading-list-2023/"))
        XCTAssertEqual(entry.title, "A list of books I read in 2023")
        XCTAssertEqual(entry.content?.count, 500)
        XCTAssertEqual(entry.content?.prefix(50), "Continuing another tradition, here are the books I")
        XCTAssertEqual(entry.publishedAt, Date.fromISO8601String("2023-12-30T05:02:14+09:00"))
    }

    func test_andante() async throws {
        let feed = try await fetcher.fetch(url: Self.andanteURI.url)
        XCTAssertEqual(feed.url, Self.andanteURI.url)
        XCTAssertEqual(feed.title, "andante")
        XCTAssertEqual(feed.overview, "個人的な日記です")
        XCTAssertEqual(feed.imageURL, URL(string: "https://ofni.necocen.info/static/favicon.png")!)

        XCTAssertEqual(feed.entries.count, 10)
        let entry = try XCTUnwrap(feed.entries.first)
        XCTAssertEqual(entry.url, URL(string: "https://ofni.necocen.info/5006"))
        XCTAssertEqual(entry.title, "1229")
        XCTAssertEqual(entry.content?.count, 0)
        XCTAssertEqual(
            entry.publishedAt.timeIntervalSince1970,
            Date.fromISO8601String("2023-12-30T01:23:48+09:00").timeIntervalSince1970,
            accuracy: 1
        )
    }

    func test_jxck() async throws {
        let feed = try await fetcher.fetch(url: Self.jxckURI.url)
        XCTAssertEqual(feed.url, Self.jxckURI.url)
        XCTAssertEqual(feed.title, "blog.jxck.io")
        XCTAssertEqual(feed.overview, "")
        XCTAssertEqual(feed.imageURL, URL(string: "https://blog.jxck.io/assets/img/jxck.120x120.png")!)

        XCTAssertEqual(feed.entries.count, 185)
        let entry = try XCTUnwrap(feed.entries.first)
        XCTAssertEqual(entry.url, URL(string: "https://blog.jxck.io/entries/2023-12-30/after-deprecation.html"))
        XCTAssertEqual(entry.title, "3PCA 最終日: 3rd Party Cookie 亡き後の Web はどうなるか?")
        XCTAssertEqual(entry.content?.count, 308)
        XCTAssertEqual(entry.content?.prefix(50), "このエントリは、 3rd Party Cookie Advent Calendar の最終日である。")
        XCTAssertEqual(entry.publishedAt, Date.fromISO8601String("2023-12-30T09:00:00+09:00"))
    }
    
    // MARK: - RDF

    func test_asahi() async throws {
        let feed = try await fetcher.fetch(url: Self.asahiURI.url)
        XCTAssertEqual(feed.url, Self.asahiURI.url)
        XCTAssertEqual(feed.title, "朝日新聞デジタル")
        XCTAssertEqual(feed.overview, "朝日新聞デジタル")
        XCTAssertNil(feed.imageURL)

        XCTAssertEqual(feed.entries.count, 40)
        let entry = try XCTUnwrap(feed.entries.first)
        XCTAssertEqual(entry.url, URL(string: "http://www.asahi.com/articles/ASS4X4VWGS4XUDCB00KM.html?ref=rss"))
        XCTAssertEqual(entry.title, "JR内房線で女児が電車にはねられ搬送　千葉・館山")
        XCTAssertEqual(entry.content?.count, 0)
        XCTAssertEqual(entry.publishedAt, Date.fromISO8601String("2024-04-29T00:20:00+09:00"))
    }
    
    func test_avWatch() async throws {
        let feed = try await fetcher.fetch(url: Self.avWatchURI.url)
        XCTAssertEqual(feed.url, Self.avWatchURI.url)
        XCTAssertEqual(feed.title, "AV Watch")
        XCTAssertEqual(feed.overview, "オーディオ・ビジュアル総合情報サイト")
        XCTAssertNil(feed.imageURL)

        XCTAssertEqual(feed.entries.count, 20)
        let entry = try XCTUnwrap(feed.entries.first)
        XCTAssertEqual(entry.url, URL(string: "https://av.watch.impress.co.jp/docs/news/1588070.html"))
        XCTAssertEqual(entry.title, "究極ポータブルオーディオ「FUGAKU」、ティアックのディスクリートDAC兼ヘッドフォンアンプも")
        XCTAssertEqual(entry.content?.count, 140)
        XCTAssertEqual(entry.content?.prefix(50), "「春のヘッドフォン祭 2024」が4月27日に東京駅八重洲直結のステーションコンファレンス東京で開催")
        XCTAssertEqual(entry.publishedAt, Date.fromISO8601String("2024-04-27T18:37:10+09:00"))
    }
    
    func test_toiroiro() async throws {
        let feed = try await fetcher.fetch(url: Self.toiroiroURI.url)
        XCTAssertEqual(feed.url, Self.toiroiroURI.url)
        XCTAssertEqual(feed.title, "トイロ公式ブログ【日々のこと～暮らしを彩る料理とモノ～】")
        XCTAssertEqual(feed.overview, "おうちごはんや、お弁当、手作りおやつ、あったら便利なグッズ、好きなモノ・場所のことなど。暮らしを楽しむ様々なアイデアや日々のことを綴る、トイロのオフィシャルブログです。\n")
        XCTAssertNil(feed.imageURL)

        XCTAssertEqual(feed.entries.count, 10)
        let entry = try XCTUnwrap(feed.entries.first)
        XCTAssertEqual(entry.url, URL(string: "https://toiroiro.blog.jp/archives/27826149.html"))
        XCTAssertEqual(entry.title, "とり天＆おにぎりランチと、今日のVoicy")
        XCTAssertEqual(entry.content?.count, 500)
        XCTAssertEqual(entry.publishedAt, Date.fromISO8601String("2024-04-27T22:27:13+09:00"))
    }

    // MARK: - JSON

    func test_jessesquires_json() async throws {
        let feed = try await fetcher.fetch(url: Self.jessesquiresJSONURI.url)
        XCTAssertEqual(feed.url, Self.jessesquiresJSONURI.url)
        XCTAssertEqual(feed.title, "Jesse Squires")
        XCTAssertEqual(feed.overview, "Turing complete with a stack of 0xdeadbeef")
        XCTAssertEqual(feed.imageURL, URL(string: "https://www.jessesquires.com/favicon.ico")!)

        XCTAssertEqual(feed.entries.count, 31)
        let entry = try XCTUnwrap(feed.entries.first)
        XCTAssertEqual(entry.url, URL(string: "https://www.jessesquires.com/blog/2023/12/29/reading-list-2023/"))
        XCTAssertEqual(entry.title, "A list of books I read in 2023")
        XCTAssertEqual(entry.content?.count, 500)
        XCTAssertEqual(entry.content?.prefix(50), "Continuing another tradition, here are the books I")
        XCTAssertEqual(entry.publishedAt, Date.fromISO8601String("2023-12-30T05:02:14+09:00"))
    }
}

extension URI {
    var url: URL { URL(string: string)! }
}
