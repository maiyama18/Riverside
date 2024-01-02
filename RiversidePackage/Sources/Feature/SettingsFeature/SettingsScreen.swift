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
                } header: {
                    Text("About App")
                }

            }
            .navigationTitle("Settings")
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
