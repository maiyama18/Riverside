import CoreData
import Dependencies
import FeedClient
import SubscribeFeedUseCase
import Observation
import UniformTypeIdentifiers
import RiversideLogging
import Payloads

@MainActor
@Observable
final class ActionModel {
    var result: Result<Feed, any Error>? = nil
    
    @ObservationIgnored @Dependency(\.logger[.appExtension]) private var logger
    @ObservationIgnored @Dependency(\.subscribeFeedUseCase) private var subscribeFeedUseCase
    
    private let context: NSManagedObjectContext
    private let inputItems: [Any]
    private let successCompletion: () -> Void
    
    init(context: NSManagedObjectContext, inputItems: [Any], successCompletion: @escaping () -> Void) {
        self.context = context
        self.inputItems = inputItems
        self.successCompletion = successCompletion
    }
    
    func subscribeFeed() async {
        let urlProvider = inputItems
            .compactMap { $0 as? NSExtensionItem }
            .compactMap { $0.attachments }
            .flatMap { $0 }
            .first(where: { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) })
        
        guard let urlProvider else {
            logger.error("no URL provider found")
            result = .failure(NSError(domain: "ActionExtension", code: -1))
            return
        }
        
        do {
            let item = try await urlProvider.loadItem(forTypeIdentifier: UTType.url.identifier)
            if let url = item as? URL {
                let feed = try await subscribeFeedUseCase.execute(context, .url(url))
                logger.notice("subscribed feed: \(feed.title, privacy: .public)(\(feed.url.absoluteString, privacy: .public))")
                result = .success(feed)
                
                try? await Task.sleep(for: .seconds(1))
                successCompletion()
            } else {
                logger.error("failed to find url item")
                result = .failure(NSError(domain: "ActionExtension", code: -1))
            }
        } catch {
            logger.notice("failed to subscribe feed: \(error, privacy: .public)")
            result = .failure(error)
        }
    }
}
