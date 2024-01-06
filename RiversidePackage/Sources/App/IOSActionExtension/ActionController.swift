import Combine
import SwiftUI

public final class ActionController: UIHostingController<ActionView> {
    private let model: ActionModel
    
    public init(context: NSExtensionContext) {
        model = ActionModel(inputItems: context.inputItems)
        super.init(rootView: ActionView(model: model))
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

