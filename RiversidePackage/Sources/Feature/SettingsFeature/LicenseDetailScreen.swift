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
        .background(backgroundColor)
        .navigationTitle(licenseName)
    }
    
    private var backgroundColor: Color {
        #if canImport(UIKit)
            Color(.systemGroupedBackground)
        #elseif canImport(AppKit)
            Color(.controlBackgroundColor)
        #else
            Color.gray.opacity(0.3)
        #endif
    }
}
