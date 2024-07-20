import Combine
import Entities
import SwiftUI

public final class ActionController: UIHostingController<ActionContainerView> {
    private let model: ActionModel
    private let persistentContainer = PersistentProvider.cloud
    
    public init(context: NSExtensionContext) {
        model = ActionModel(
            context: persistentContainer.viewContext,
            inputItems: context.inputItems,
            successCompletion: {
                context.completeRequest(returningItems: context.inputItems)
            }
        )
        super.init(rootView: ActionContainerView(model: model))
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

