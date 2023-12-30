import SwiftUI

struct AddFeedScreen: View {
    @State private var text: String = ""
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("URL", text: $text, prompt: Text("https://..."))
                        .keyboardType(.URL)
                } header: {
                    Text("Blog/Feed URL")
                        .textCase(nil)
                } footer: {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 24)
                }
            }
            .navigationTitle("Add feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Material.ultraThin, for: .navigationBar)
        }
    }
}

#Preview {
    AddFeedScreen()
}
