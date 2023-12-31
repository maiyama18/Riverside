import Foundation

public extension URL {
    func isValid() -> Bool {
        absoluteString.firstMatch(of: #/https?:\/\/[\w-]+(\.[\w-]+)+[\w.,@?^=%&:\/~+#-]*[\w@?^=%&\/~+#-]/#) != nil
    }
}
