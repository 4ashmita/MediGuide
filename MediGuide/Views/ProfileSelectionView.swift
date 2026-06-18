import SwiftUI

struct ProfileSelectionView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            ProfileSwitcherView()
                .navigationTitle("Who needs help?")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Back") { appState.activeScreen = .welcome }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EmergencyButtonView(context: .noSession)
                    }
                }
        }
    }
}
