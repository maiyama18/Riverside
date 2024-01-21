import CoreData
import Dependencies
import SwiftUI

public extension View {
    func deleteDuplicatedEntriesOnce() -> some View {
        modifier(DeleteDuplicatedEntriesOnceModifier())
    }
}

struct DeleteDuplicatedEntriesOnceModifier: ViewModifier {
    @Dependency(\.deleteDuplicatedEntriesUseCase) private var deleteDuplicatedEntriesUseCase
    
    @Environment(\.managedObjectContext) private var context
    
    @State private var deleteExecuted: Bool = false
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                guard !deleteExecuted else { return }
                defer { deleteExecuted = true }
                
                do {
                    try deleteDuplicatedEntriesUseCase.execute(context)
                } catch {
                    print(error)
                }
            }
    }
}
