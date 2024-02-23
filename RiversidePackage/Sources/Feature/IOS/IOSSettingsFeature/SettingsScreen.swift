import CloudSyncStatusFeature
import Dependencies
import Entities
import LicensesFeature
import LocalPushNotificationClient
import LogFeature
import NavigationState
import SwiftUI
import Utilities

public struct SettingsScreen: View {
    @AppStorage("appearance") private var appearance: UIUserInterfaceStyle = .unspecified
    @AppStorage("background-refresh-enabled") private var backgroundRefreshEnabled: Bool = true
    @AppStorage("background-refresh-push-notification-enabled") private var backgroundRefreshPushNotificationEnabled: Bool = false
    
    @Dependency(\.localPushNotificationClient) private var localPushNotificationClient
    
    @Environment(NavigationState.self) private var navigationState
    
    @State private var notificationSettingsAlertPresented: Bool = false
    
    private let persistentProvider: PersistentProvider
    
    public init(persistentProvider: PersistentProvider = .cloud) {
        self.persistentProvider = persistentProvider
    }
    
    public var body: some View {
        @Bindable var navigationState = navigationState
        
        NavigationStack(path: $navigationState.settingsPath) {
            List {
                Section {
                    HStack {
                        Text("Refresh")
                            .font(.callout)
                        
                        Spacer()
                        
                        Toggle(isOn: $backgroundRefreshEnabled) { Text("") }
                    }
                    
                    if backgroundRefreshEnabled {
                        HStack {
                            Text("Push Notifications")
                                .font(.callout)
                            
                            Spacer()
                            
                            Toggle(isOn: $backgroundRefreshPushNotificationEnabled) { Text("") }
                        }
                        .onChange(of: backgroundRefreshPushNotificationEnabled, initial: false) { _, notificationEnabled in
                            if notificationEnabled {
                                Task {
                                    let permission = await localPushNotificationClient.getPermission()
                                    if permission != .authorized {
                                        backgroundRefreshPushNotificationEnabled = false
                                        notificationSettingsAlertPresented = true
                                    }
                                }
                            }
                        }
                        .alert(
                            "No permission",
                            isPresented: $notificationSettingsAlertPresented,
                            actions: {
                                Button("Open settings") {
                                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                                }
                                Button("Cancel", role: .cancel) {}
                            },
                            message: {
                                Text("Enable notifications in settings to receive background refresh notifications.")
                            }
                        )
                    }
                } header: {
                    Text("Background")
                }
                .tint(.accentColor)
                
                Section {
                    HStack {
                        Text("Appearance")
                            .font(.callout)
                        
                        Spacer()
                        
                        Picker("", selection: $appearance) {
                            ForEach(UIUserInterfaceStyle.all, id: \.self) { appearance in
                                Text(appearance.string)
                                    .font(.callout)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                Section {
                    if let databaseSize = persistentProvider.databaseSize {
                        HStack {
                            Text("Storage")
                                .font(.callout)
                            
                            Spacer()
                            
                            Text(ByteFormatter.format(databaseSize))
                                .font(.callout.monospacedDigit())
                                .foregroundColor(.gray)
                        }
                    }
                    
                    NavigationLink(value: SettingsRoute.cloudSyncStatus) {
                        Text("Cloud Sync Status")
                    }
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
                } header: {
                    Text("About App")
                }
                
                if !Bundle.main.isProduction {
                    Section {
                        NavigationLink(value: SettingsRoute.log) {
                            Text("Debug Log")
                        }
                        
                        Button("Local Push") {
                            localPushNotificationClient.send("Test title", "test body test body test body test body")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationDestination(for: SettingsRoute.self) { route in
                switch route {
                case .cloudSyncStatus:
                    CloudSyncStatusScreen()
                case .log:
                    LogScreen()
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
    SettingsScreen(persistentProvider: .inMemory)
}
