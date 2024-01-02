import NavigationState
import SwiftUI

public struct SettingsScreen: View {
    public init() {}
    
    public var body: some View {
        NavigationStack {
            List {
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
                    
                    NavigationLink(value: SettingsRoute.licenses) { Text("Licenses") }
                } header: {
                    Text("About App")
                }

            }
            .navigationTitle("Settings")
            .navigationDestination(for: SettingsRoute.self) { route in
                switch route {
                case .licenses:
                    LicensesScreen()
                case .licenseDetail(let licenseName, let licenseText):
                    LicenseDetailScreen(licenseName: licenseName, licenseText: licenseText)
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
