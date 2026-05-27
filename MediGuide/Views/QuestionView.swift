import SwiftUI

struct QuestionView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var engine: TriageEngine
    @EnvironmentObject var sessionManager: SessionManager

    var body: some View {
        if let node = navigationManager.currentNode {
            VStack(spacing: 0) {
                emergencyButton
                    .padding([.horizontal, .top])

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if navigationManager.canGoBack {
                            Button(action: navigationManager.goBack) {
                                Label("Back", systemImage: "chevron.left")
                                    .font(.subheadline)
                            }
                        }

                        Text(node.question)
                            .font(.title2)
                            .fontWeight(.semibold)

                        VStack(spacing: 12) {
                            ForEach(node.options, id: \.text) { option in
                                Button(action: { navigationManager.advance(via: option) }) {
                                    Text(option.text)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding()
                                        .foregroundColor(.primary)
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.12))
                                )
                            }
                        }
                    }
                    .padding()
                }

                Divider()
                EscalationButton()
                    .padding(.horizontal)
                    .padding(.vertical, 12)
            }
        }
    }

    private var emergencyButton: some View {
        Button(action: { /* 911 call flow — built in Emergency Response feature */ }) {
            Text("Call 911")
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.red)
                .cornerRadius(10)
        }
    }
}
