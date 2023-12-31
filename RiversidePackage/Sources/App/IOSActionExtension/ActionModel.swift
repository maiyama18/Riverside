import Dependencies
import FeedClient
import FeedUseCase
import Observation
import SwiftData
@preconcurrency import UniformTypeIdentifiers

@MainActor
@Observable
final class ActionModel {
    var result: Result<Feed, any Error>? = nil
    
    @ObservationIgnored @Dependency(\.feedUseCase) private var feedUseCase
    
    private let inputItems: [Any]
    private let successCompletion: () -> Void
    
    init(inputItems: [Any], successCompletion: @escaping () -> Void) {
        self.inputItems = inputItems
        self.successCompletion = successCompletion
    }
    
    func onAppear(context: ModelContext) async {
        await subscribeFeed(context: context)
    }
    
    private func subscribeFeed(context: ModelContext) async {
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
