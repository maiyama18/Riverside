import SwiftUI

public extension View {
    func ifDebug(transform: (Self) -> some View) -> some View {
        #if DEBUG
        transform(self)
        #else
        self
        #endif
    }
}
