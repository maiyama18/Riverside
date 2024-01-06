import Observation
import UIKit
import UniformTypeIdentifiers

@Observable
final class ActionModel {
    var result: Result<URL, any Error>? = nil
    
    private let inputItems: [Any]
    
    init(inputItems: [Any]) {
        self.inputItems = inputItems
    }
    
    func onAppear() async {
        await addFeed()
    }
    
    private func addFeed() async {
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
                result = .success(url)
            } else {
                result = .failure(NSError(domain: "ActionExtension", code: -1))
            }
        } catch {
            result = .failure(error)
        }
    }
}
