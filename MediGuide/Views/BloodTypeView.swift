import SwiftUI

struct BloodTypeView: View {
    @Binding var selection: BloodType

    // 8 known types in a 3-column grid, Unknown spans full width below
    private let gridTypes: [BloodType] = [
        .aPositive, .aNegative,
        .bPositive, .bNegative,
        .abPositive, .abNegative,
        .oPositive, .oNegative
    ]

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(gridTypes, id: \.self) { type in
                    bloodTypeCell(type)
                }
            }

            // Unknown spans the full width
            bloodTypeCell(.unknown)
                .frame(maxWidth: .infinity)

            Text("If you don't know your blood type, leave this as Unknown. Do not guess.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func bloodTypeCell(_ type: BloodType) -> some View {
        let isSelected = selection == type
        return Button {
            guard selection != type else { return }
            selection = type
        } label: {
            VStack(spacing: 2) {
                Text(type.rawValue)
                    .font(.headline)
                    .fontWeight(isSelected ? .bold : .regular)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.red.opacity(0.12) : Color.gray.opacity(0.08),
                        in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.red : Color.clear, lineWidth: 1.5)
            )
            .foregroundStyle(isSelected ? .red : .primary)
        }
        .buttonStyle(.plain)
    }
}
