import Foundation

public extension URL {
    func isValid() -> Bool {
        absoluteString.firstMatch(of: #/https?:\/\/[\w-]+(\.[\w-]+)+[\w.,@?^=%&:\/~+#-]*[\w@?^=%&\/~+#-]/#) != nil
    }
    
    func isSame(as other: URL) -> Bool {
        guard scheme == other.scheme,
              host() == other.host(),
              pathComponents.drop(while: { $0 == "/" }) == other.pathComponents.drop(while: { $0 == "/" }) else {
            return false
        }
        
        let queryItems = URLComponents(url: self, resolvingAgainstBaseURL: false)?.queryItems?.sorted(by: { $0.name < $1.name })
        let otherQueryItems = URLComponents(url: other, resolvingAgainstBaseURL: false)?.queryItems?.sorted(by: { $0.name < $1.name })
        guard queryItems == otherQueryItems else { return false }
        
        return true
    }
}
