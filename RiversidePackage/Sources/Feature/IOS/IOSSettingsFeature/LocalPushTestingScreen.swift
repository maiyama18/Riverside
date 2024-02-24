import Dependencies
import LocalPushNotificationClient
import SwiftUI

struct LocalPushTestingScreen: View {
    @Dependency(\.localPushNotificationClient) private var localPushNotificationClient
    
    @State private var title = "4 new entries published"
    @State private var message = """
    Swift joins Google Summer of Code 2024 | Swift.org
    How AI code generation works | The GitHub Blog
    What is DevSecOps? A look into security ... | Bitrise Blog
    and more!
    """
    
    var body: some View {
        List {
            Section {
                TextField("Title", text: $title)
                TextEditor(text: $message)
            }
            
            Button("Send") {
                localPushNotificationClient.send(title, message)
            }
        }
    }
}
