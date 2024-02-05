import Foundation

extension Bundle {
    public var isProduction: Bool {
        #if DEBUG
        return false
        #else
        return appStoreReceiptURL?.lastPathComponent != "sandboxReceipt"
        #endif
    }
}
