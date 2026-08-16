import SwiftUI

struct PaywallView: View {
    let recap: ScanOutcome
    @EnvironmentObject private var store: StoreKitStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            recapChip
            Text("That’s one down. The aisle has thousands more.")
                .font(.title2.weight(.bold))
                .fixedSize(horizontal: false, vertical: true)

            Button {
                Task { await store.purchaseYearly() }
            } label: {
                Text("Start 7-day trial")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AisleOKColor.paprika)
            .controlSize(.large)

            Text("$49.99/year")
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)

            Button("$9.99/month") {
                Task { await store.purchaseMonthly() }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)

            Text("7-day free trial, then $49.99/year. Cancel anytime.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)

            if let error = store.lastError {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Button("Restore purchases") {
                Task { await store.restore() }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Link("Privacy", destination: AisleOKLinks.privacy)
                Link("Terms", destination: AisleOKLinks.terms)
            }
            .font(.footnote)

            Spacer(minLength: 0)
        }
        .padding(24)
        .onChange(of: store.isEntitled) { _, entitled in
            if entitled { dismiss() }
        }
    }

    private var recapChip: some View {
        HStack(spacing: 6) {
            Text(recap.score.band.word)
                .foregroundStyle(recap.score.band.wordColor)
            if let name = recap.score.displayName {
                Text("·")
                Text(name)
            }
        }
        .font(.subheadline.weight(.semibold))
        .accessibilityElement(children: .combine)
    }
}
