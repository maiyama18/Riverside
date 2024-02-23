import AppConfig
import Dependencies

extension AppConfig: DependencyKey {
    public static let liveValue: AppConfig = .init(appGroup: nil)
}
