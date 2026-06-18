import SwiftUI

struct StepDisplayView: View {
    let step: FirstAidStep
    let stepNumber: Int
    let tierColor: Color
    let vm: FirstAidViewModel
    let onTimerStart: () -> Void
    let onTimerComplete: () -> Void
    let onSwitchType: (FirstAidEmergencyType) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                stepHeader
                instructionBlock
                if let key = step.illustrationKey {
                    IllustrationView(key: key)
                }
                if step.isCPRTimer {
                    CPRTimerView()
                    // CPR is continuous — never blocks Next button
                } else if let seconds = step.timerSeconds {
                    StepTimerView(totalSeconds: seconds, onComplete: onTimerComplete)
                        .onAppear { onTimerStart() }
                }
                if let warning = step.warning {
                    warningBox(warning)
                }
                if step.id == "stroke_record_time" {
                    onsetRecorder
                }
                if let linked = step.linkedEmergencyType,
                   let type = FirstAidEmergencyType(rawValue: linked) {
                    linkedTypeButton(type)
                }
            }
            .padding()
        }
    }

    // MARK: - Subviews

    private var stepHeader: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("Step \(stepNumber)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(tierColor)
                .cornerRadius(8)
            Spacer()
        }
    }

    private var instructionBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(step.instruction)
                .font(.title3)
                .fontWeight(.semibold)
                .fixedSize(horizontal: false, vertical: true)

            if let detail = step.detail {
                Text(detail)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func warningBox(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .padding(.top, 2)
            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(Color.orange.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(10)
    }

    private var onsetRecorder: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let recorded = vm.symptomOnsetTime {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Symptom onset recorded")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        Text(recorded, format: .dateTime.hour().minute().second())
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                }
                .padding(12)
                .background(Color.green.opacity(0.08))
                .cornerRadius(10)
            } else {
                Button(action: vm.recordSymptomOnsetTime) {
                    Label("Record Current Time as Symptom Onset", systemImage: "clock.badge.checkmark.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.blue.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(10)
                }
            }
        }
    }

    private func linkedTypeButton(_ type: FirstAidEmergencyType) -> some View {
        Button(action: { onSwitchType(type) }) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.right.circle.fill")
                Text("Begin \(type.displayName) Instructions")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(Color.red.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.red.opacity(0.3), lineWidth: 1.5)
            )
            .cornerRadius(12)
        }
    }
}
