import Dependencies

public struct AppConfig: Sendable {
    public let appGroup: String?
    
    public init(appGroup: String?) {
        self.appGroup = appGroup
    }
}

extension AppConfig: TestDependencyKey {
    public static let testValue: AppConfig = AppConfig(appGroup: nil)
}

extension DependencyValues {
    public var appConfig: AppConfig {
        get { self[AppConfig.self] }
        set { self[AppConfig.self] = newValue }
    }
}
