import NavigationState
import SwiftUI

struct LicensesScreen: View {
    private var licenses: [LicensesPlugin.License] = LicensesPlugin.licenses

    var body: some View {
        List {
            ForEach(licenses) { license in
                if let licenseText = license.licenseText {
                    NavigationLink(value: SettingsRoute.licenseDetail(licenseName: license.name, licenseText: licenseText)) {
                        Text(license.name)
                    }
                } else {
                    Text(license.name)
                }
            }
        }
        .navigationTitle("Licenses")
    }
}
