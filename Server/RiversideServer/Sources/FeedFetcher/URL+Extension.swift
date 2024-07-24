import Foundation

extension URL {
    func getBaseURL() -> URL? {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return nil
        }
        
        components.path = ""
        components.query = nil
        components.fragment = nil
        components.user = nil
        components.password = nil
        components.port = nil
        
        return components.url
    }
    
    func insertBaseURLIfNeeded(referenceURL: URL) -> URL {
        if scheme != nil && host() != nil { return self }
        
        if let baseURL = referenceURL.getBaseURL() {
            guard var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
                return self
            }
            urlComponents.path = absoluteString.hasPrefix("/") ? absoluteString : "/\(absoluteString)"
            return urlComponents.url ?? self
        } else {
            return self
        }
    }
    
    func isValid() -> Bool {
        absoluteString.firstMatch(of: /https?:\/\/[\w-]+(\.[\w-]+)+[\w.,@?^=%&:\/~+#-]*[\w@?^=%&\/~+#-]/) != nil
    }
}
