import Foundation

extension URL {
    func baseURL() -> URL? {
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
}
