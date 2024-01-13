import LicensesFeature
import NavigationState
import SwiftUI

public struct SettingsScreen: View {
    @Environment(NavigationState.self) private var navigationState
    
    public init() {}
    
    public var body: some View {
        @Bindable var navigationState = navigationState
        
        NavigationStack(path: $navigationState.settingsPath) {
            List {
                Section {
                    NavigationLink(value: SettingsRoute.cloudSyncStatus) { Text("Cloud Sync Status") }
                }
                
                Section {
                    if let versionString {
                        HStack {
                            Text("Version")
                                .font(.callout)
                            
                            Spacer()
                            
                            Text(versionString)
                                .font(.callout.monospacedDigit())
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Button("Licenses") {
                        navigationState.settingsPresentation = .licenses
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationDestination(for: SettingsRoute.self) { route in
                switch route {
                case .cloudSyncStatus:
                    CloudSyncScreen()
                }
            }
            .sheet(item: $navigationState.settingsPresentation) { presentation in
                switch presentation {
                case .licenses:
                    LicensesScreen()
                }
            }
        }
    }
    
    private var versionString: String? {
        Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String
    }
}

#Preview {
    SettingsScreen()
}
