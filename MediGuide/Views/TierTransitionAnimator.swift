import SwiftUI

private struct TierTransitionModifier: ViewModifier {
    let tier: RecommendationTier
    @State private var flashOpacity: Double = 0

    func body(content: Content) -> some View {
        content
            .animation(.easeInOut(duration: 0.35), value: tier)
            .overlay(
                Color.red
                    .opacity(flashOpacity)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            )
            .onChange(of: tier) { _, newTier in
                guard newTier == .call911 else { return }
                flashOpacity = 0.4
                withAnimation(.easeOut(duration: 0.4)) {
                    flashOpacity = 0
                }
            }
    }
}

extension View {
    func tierTransition(tier: RecommendationTier) -> some View {
        modifier(TierTransitionModifier(tier: tier))
    }
}
