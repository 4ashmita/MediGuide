import SwiftUI

struct EmergencyAlertView: View {
    @StateObject private var vm: EmergencyAlertViewModel
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var wakeVM: ScreenWakeViewModel
    @State private var showSMSCompose = false
    @State private var pulse = false

    init(session: TriageSession) {
        _vm = StateObject(wrappedValue: EmergencyAlertViewModel(session: session))
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.red.ignoresSafeArea()

            switch vm.phase {
            case .countdown:
                countdownContent
            case .showSMS, .callPlaced:
                callPlacedContent
            }

            // Button remains visible but disabled — countdown is already the emergency action.
            EmergencyButtonView(context: .countdownActive)
                .padding(.top, 56)
                .padding(.trailing, EmergencyButtonStyleGuide.trailingPadding)
        }
        .onAppear {
            wakeVM.activate(context: .emergencyCountdown)
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .onDisappear {
            wakeVM.deactivate(context: .emergencyCountdown)
        }
        .onChange(of: vm.phase) { _, phase in
            if phase == .showSMS {
                if MessageComposeView.canSendText && !vm.smsRecipient.isEmpty {
                    showSMSCompose = true
                } else {
                    vm.dismissSMS()
                }
            }
        }
        .sheet(isPresented: $showSMSCompose, onDismiss: { vm.dismissSMS() }) {
            MessageComposeView(
                recipient: vm.smsRecipient,
                body: vm.smsBody,
                onDismiss: { showSMSCompose = false }
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $vm.showCancelConfirm) {
            CancelConfirmationView(
                onConfirmCancel: { appState.isEmergencyCountdownRunning = false },
                onResume: {}
            )
        }
    }

    // MARK: - Countdown

    private var countdownContent: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 8) {
                Text("Calling 911")
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                Text("in")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer().frame(height: 32)

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 220, height: 220)
                    .scaleEffect(pulse ? 1.12 : 1.0)
                Circle()
                    .fill(Color.white.opacity(0.14))
                    .frame(width: 170, height: 170)

                Text("\(vm.secondsRemaining)")
                    .font(.system(size: 100, weight: .black))
                    .foregroundColor(.white)
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.easeInOut(duration: 0.3), value: vm.secondsRemaining)
            }

            Spacer().frame(height: 32)

            Text("Stay on the line after the call connects.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            VStack(spacing: 14) {
                Button(action: vm.callNow) {
                    HStack(spacing: 10) {
                        Image(systemName: "phone.fill")
                        Text("Call 911 Now")
                            .fontWeight(.bold)
                    }
                    .font(.title3)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.white)
                    .cornerRadius(16)
                }

                Button(action: vm.cancel) {
                    Text("Cancel")
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.85))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                        )
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 44)
        }
    }

    // MARK: - Call Placed

    private var callPlacedContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "phone.fill.arrow.up.right")
                        .font(.system(size: 52, weight: .bold))
                        .foregroundColor(.white)

                    Text("Call Placed")
                        .font(.largeTitle)
                        .fontWeight(.black)
                        .foregroundColor(.white)

                    Text("Stay on the line with dispatch.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)
                .padding(.horizontal)

                DispatcherInfoView(session: vm.session)
                    .padding(.horizontal)

                Button(action: { appState.isEmergencyCountdownRunning = false }) {
                    Text("Done")
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(14)
                }
                .padding(.horizontal)
                .padding(.bottom, 44)
            }
        }
    }
}
