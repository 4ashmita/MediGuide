import SwiftUI

struct ValidationErrorView: View {
    let failures: [ValidationFailure]

    var body: some View {
        if !failures.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(failures) { failure in
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: failure.severity == .error
                              ? "exclamationmark.circle.fill"
                              : "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(failure.severity == .error ? .red : .orange)
                        Text(failure.message)
                            .font(.caption)
                            .foregroundStyle(failure.severity == .error ? .red : .orange)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
            .animation(.easeInOut(duration: 0.2), value: failures.count)
        }
    }
}
