import Combine
import Models
import SwiftUI

public final class ActionController: UIHostingController<ActionContainerView> {
    private let model: ActionModel
    
    public init(context: NSExtensionContext) {
        model = ActionModel(
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

