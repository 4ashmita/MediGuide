import SwiftUI

struct QuickCallConfirmationView: View {
    let context: EmergencyContext
    let profileName: String?
    var onConfirm: () -> Void
    var onCancel: () -> Void

    @State private var autoDismissProgress: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 0) {
            if context.autoDismisses {
                autoDismissBar
            }

            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(EmergencyButtonStyleGuide.red)
                        .padding(.top, 28)

                    Text("Call 911?")
                        .font(.title2.bold())

                    if let name = profileName {
                        Text("For: \(name)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    if !context.confirmationMessage.isEmpty {
                        Text(context.confirmationMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }
                }

                VStack(spacing: 12) {
                    Button(action: onConfirm) {
                        Text("Yes, Call 911")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(EmergencyButtonStyleGuide.red)
                            .cornerRadius(14)
                    }
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(.systemGray5))
                            .cornerRadius(14)
                    }
                }
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            guard context.autoDismisses else { return }
            withAnimation(.linear(duration: 5)) {
                autoDismissProgress = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                onCancel()
            }
        }
    }

    private var autoDismissBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                Rectangle()
                    .fill(EmergencyButtonStyleGuide.red)
                    .frame(width: geo.size.width * autoDismissProgress)
            }
        }
        .frame(height: 3)
    }
}
