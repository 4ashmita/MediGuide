import SwiftUI

struct FirstAidView: View {
    @StateObject private var vm: FirstAidViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var wakeVM: ScreenWakeViewModel
    @State private var stepTimerBlocking = false
    @State private var showCompletion = false
    @State private var showAlternatives = false

    init(emergencyType: FirstAidEmergencyType, session: TriageSession) {
        _vm = StateObject(wrappedValue: FirstAidViewModel(emergencyType: emergencyType, session: session))
    }

    private var tierColor: Color {
        switch vm.emergencyType.tier {
        case .call911:    return .red
        case .goToER:     return Color(red: 1.0, green: 0.4, blue: 0.0)
        case .urgentCare: return Color(red: 1.0, green: 0.7, blue: 0.0)
        case .monitor:    return Color(red: 0.0, green: 0.67, blue: 0.0)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if vm.navManager.isComplete {
                completionView
            } else if let step = vm.navManager.currentStep {
                StepDisplayView(
                    step: step,
                    stepNumber: vm.navManager.currentStepIndex + 1,
                    tierColor: tierColor,
                    vm: vm,
                    onTimerStart:    { stepTimerBlocking = true },
                    onTimerComplete: { handleTimerComplete(step: step) },
                    onSwitchType:    { switchTo($0) }
                )
                .id(step.id)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal:   .move(edge: .leading).combined(with: .opacity)
                ))
            } else {
                Spacer()
                ProgressView()
                Spacer()
            }

            if !vm.navManager.isComplete {
                Divider()
                navigationBar
            }
        }
        .onAppear { wakeVM.activate(context: .firstAidGuidance) }
        .onDisappear { wakeVM.deactivate(context: .firstAidGuidance) }
        .onChange(of: vm.navManager.currentStepIndex) { _, _ in
            withAnimation(.easeInOut(duration: 0.25)) { }
            stepTimerBlocking = false
        }
        .sheet(isPresented: $showAlternatives) {
            alternativesSheet
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.down")
                        Text("Back")
                    }
                    .font(.subheadline)
                    .foregroundColor(tierColor)
                }

                Spacer()

                VStack(spacing: 2) {
                    Text(vm.emergencyType.displayName)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    if !vm.alternativeTypes.isEmpty {
                        Button("Switch guidance") { showAlternatives = true }
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                EmergencyButtonView(context: .firstAid)
            }

            if vm.navManager.totalSteps > 0 {
                FirstAidProgressView(
                    currentStep: vm.navManager.currentStepIndex + 1,
                    totalSteps:  vm.navManager.totalSteps,
                    tierColor:   tierColor
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            tierColor.opacity(0.08).ignoresSafeArea(edges: .top)
        }
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack(spacing: 16) {
            Button(action: goBack) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("Previous")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(vm.navManager.canGoBack ? tierColor : .secondary)
            }
            .disabled(!vm.navManager.canGoBack)

            Spacer()

            Button(action: goForward) {
                HStack(spacing: 6) {
                    Text(vm.navManager.isLastStep ? "Done" : "Next Step")
                    if !vm.navManager.isLastStep {
                        Image(systemName: "chevron.right")
                    }
                }
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(stepTimerBlocking ? Color.gray : tierColor)
                .cornerRadius(12)
            }
            .disabled(stepTimerBlocking)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Completion

    private var completionView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)

            VStack(spacing: 8) {
                Text("Steps Complete")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Continue monitoring until help arrives or symptoms improve.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if vm.emergencyType.tier == .call911 {
                    Text("Stay with the person — help is on the way.")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                        .padding(.top, 4)
                }
            }

            Button("Return to Recommendation") { dismiss() }
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(tierColor)
                .cornerRadius(14)
                .padding(.horizontal)

            Button("Review Steps Again") {
                vm.navManager.reset()
            }
            .font(.subheadline)
            .foregroundColor(tierColor)

            Spacer()
        }
    }

    // MARK: - Alternatives Sheet

    private var alternativesSheet: some View {
        NavigationStack {
            List(vm.alternativeTypes, id: \.self) { type in
                Button(action: {
                    switchTo(type)
                    showAlternatives = false
                }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(type.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(type.tier.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Switch Guidance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAlternatives = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Actions

    private func goForward() {
        withAnimation(.easeInOut(duration: 0.25)) {
            vm.navManager.advance()
        }
        stepTimerBlocking = false
    }

    private func goBack() {
        withAnimation(.easeInOut(duration: 0.25)) {
            vm.navManager.goBack()
        }
        stepTimerBlocking = false
    }

    private func switchTo(_ type: FirstAidEmergencyType) {
        withAnimation {
            vm.loadContent(for: type)
            stepTimerBlocking = false
        }
    }

    private func handleTimerComplete(step: FirstAidStep) {
        stepTimerBlocking = false
        guard step.isAutoAdvance else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.25)) {
                vm.navManager.advance()
            }
        }
    }
}
