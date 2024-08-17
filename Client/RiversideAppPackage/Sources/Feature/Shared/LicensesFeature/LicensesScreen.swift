import SwiftUI

public struct LicensesScreen: View {
    private let licenses: [LicensesPlugin.License] = LicensesPlugin.licenses
    
    @State private var selectedLicense: LicensesPlugin.License?
    
    public init() {}

    public var body: some View {
        NavigationSplitView {
            List(selection: $selectedLicense) {
                ForEach(licenses) { license in
                    if license.licenseText != nil {
                        NavigationLink(value: license) {
                            Text(license.name)
                        }
                    } else {
                        Text(license.name)
                    }
                }
            }
            .navigationTitle("Licenses")
        } detail: {
            if let selectedLicense {
                ScrollView {
                    Group {
                        if let licenseText = selectedLicense.licenseText {
                            Text(licenseText)
                        } else {
                            Text("No license text provided")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                }
                .navigationTitle(selectedLicense.name)
            }
        }
    }
}
