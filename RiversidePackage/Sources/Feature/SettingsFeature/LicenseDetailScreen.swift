import SwiftUI

struct LicenseDetailScreen: View {
    var licenseName: String
    var licenseText: String

    var body: some View {
        ScrollView {
            Text(licenseText)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(licenseName)
    }
}
