import SwiftUI

struct EmergencyButtonView: View {
    let context: EmergencyContext
    @EnvironmentObject private var coordinator: EmergencyButtonCoordinator
    @EnvironmentObject private var appState: AppState
    @StateObject private var vm = EmergencyButtonViewModel()

    var body: some View {
        Button {
            coordinator.buttonTapped(context: context, appState: appState)
        } label: {
            VStack(spacing: 2) {
                Image(systemName: "phone.fill")
                    .font(.system(size: EmergencyButtonStyleGuide.iconSize, weight: .bold))
                Text("911")
                    .font(.system(size: EmergencyButtonStyleGuide.labelFontSize, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(
                width: EmergencyButtonStyleGuide.diameter,
                height: EmergencyButtonStyleGuide.diameter
            )
            .background(EmergencyButtonStyleGuide.red)
            .clipShape(Circle())
            .shadow(
                color: EmergencyButtonStyleGuide.red.opacity(EmergencyButtonStyleGuide.shadowOpacity),
                radius: EmergencyButtonStyleGuide.shadowRadius,
                y: EmergencyButtonStyleGuide.shadowY
            )
            .scaleEffect(vm.isPressed ? EmergencyButtonStyleGuide.pressedScale : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: vm.isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in vm.setPressed(true) }
                .onEnded   { _ in vm.setPressed(false) }
        )
        .disabled(context == .countdownActive)
        .accessibilityLabel("Emergency button. Double tap to call 911.")
    }
}
