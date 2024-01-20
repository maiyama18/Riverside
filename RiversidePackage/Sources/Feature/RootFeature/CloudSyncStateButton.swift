import CloudSyncState
import CloudSyncStatusFeature
import SwiftUI

struct CloudSyncStateButton: View {
    @Environment(CloudSyncState.self) private var cloudSyncState
    
    @State private var isPresented: Bool = false
    
    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            Image(systemName: cloudSyncState.syncing ? "arrow.clockwise.icloud" : "icloud")
        }
        .popover(isPresented: $isPresented) {
            CloudSyncStatusScreen()
        }
    }
}
