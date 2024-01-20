@preconcurrency import CoreData
import Dependencies
import FeedClient
import FeedUseCase
import Observation
import UniformTypeIdentifiers

@MainActor
@Observable
final class ActionModel {
    var result: Result<Feed, any Error>? = nil
    
    @ObservationIgnored @Dependency(\.feedUseCase) private var feedUseCase
    
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
            result = .failure(NSError(domain: "ActionExtension", code: -1))
            return
        }
        
        do {
            let item = try await urlProvider.loadItem(forTypeIdentifier: UTType.url.identifier)
            if let url = item as? URL {
                let feed = try await feedUseCase.subscribeFeed(context, .url(url))
                result = .success(feed)
                
                try? await Task.sleep(for: .seconds(1))
                successCompletion()
            } else {
                result = .failure(NSError(domain: "ActionExtension", code: -1))
            }
        } catch {
            result = .failure(error)
        }
    }
}
