import SwiftUI

struct FirstAidProgressView: View {
    let currentStep: Int
    let totalSteps: Int
    let tierColor: Color

    private var fraction: Double {
        guard totalSteps > 0 else { return 0 }
        return Double(currentStep - 1) / Double(totalSteps)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Step \(currentStep) of \(totalSteps)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(totalSteps - currentStep) remaining")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(tierColor.opacity(0.15))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(tierColor)
                        .frame(width: geo.size.width * fraction, height: 6)
                        .animation(.easeInOut(duration: 0.3), value: fraction)
                }
            }
            .frame(height: 6)
        }
    }
}
