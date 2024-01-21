import CoreData
import Entities
import Combine
import SwiftUI

public struct ActionContainerView: View {
    let model: ActionModel
    
    public var body: some View {
        ActionView(model: model)
    }
}

struct ActionView: View {
    let model: ActionModel
    
    var body: some View {
        Group {
            switch model.result {
            case nil:
                ProgressView()
            case .success(let feed):
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(.green)
                    
                    VStack(spacing: 4) {
                        Text("Subscribed!")
                            .font(.title.bold())
                        
                        Text(feed.title)
                        
                        Text(feed.url.absoluteString)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            case .failure(let error):
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(.red)
                    
                    Text(error.localizedDescription)
                        .padding(.horizontal)
                }
            }
        }
        .task {
            await model.subscribeFeed()
        }
    }
}

import UniformTypeIdentifiers

#Preview {
    ForEach(
        [
            URL(string: "https://maiyama4.hatenablog.com/")!,
            URL(string: "https://invalid.url/")!,
        ],
        id: \.absoluteString
    ) { (url: URL) in
        let item: NSExtensionItem = {
            let provider = NSItemProvider(
                item: url as any NSSecureCoding,
                typeIdentifier: UTType.url.identifier
            )
            
            let item = NSExtensionItem()
            item.attachments = [provider]
            return item
        }()
        
        let model = ActionModel(
            context: PersistentProvider.inMemory.viewContext,
            inputItems: [item],
            successCompletion: {}
        )
        
        ActionView(model: model)
    }
}
