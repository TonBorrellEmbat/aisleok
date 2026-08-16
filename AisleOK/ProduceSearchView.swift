import SwiftUI

struct ProduceSearchView: View {
    @EnvironmentObject private var model: AppModel
    @State private var query = ""
    @State private var outcome: ScanOutcome?
    @State private var markedUseful = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search produce", text: $query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onSubmit { score(markAttempt: true) }
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 20)
            .padding(.top, 8)

            if let outcome {
                verdictBlock(outcome)
            } else {
                Spacer()
            }

            if let outcome {
                Button {
                    if outcome.score.band == .unknown {
                        model.openLabelOCR()
                    } else {
                        model.popToRoot()
                    }
                } label: {
                    Text(outcome.score.band == .unknown ? "Photo of label" : "Scan another")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AisleOKColor.paprika)
                .controlSize(.large)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AisleOKColor.canvas.ignoresSafeArea())
        .navigationTitle("Search produce")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: query) { _, _ in
            score(markAttempt: false)
        }
        .sheet(isPresented: $model.showPaywall) {
            if let outcome {
                PaywallView(recap: outcome)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    @ViewBuilder
    private func verdictBlock(_ outcome: ScanOutcome) -> some View {
        VStack(spacing: 12) {
            Text(outcome.score.band.word)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(outcome.score.band.wordColor)
                .multilineTextAlignment(.center)
            Text(outcome.productName)
                .font(.title3)
            if outcome.score.band == .unknown {
                Text("We don’t know this one.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            } else if outcome.score.band == .eat {
                Text("No IBS triggers in this one.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            } else if let name = outcome.score.displayName {
                Text(cap(name))
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            if outcome.score.band == .small, let dose = outcome.score.doseLine {
                Text(dose)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
    }

    private func score(markAttempt: Bool) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            outcome = nil
            return
        }
        let next = model.handleProduce(trimmed)
        outcome = next
        let trusted = next.score.band != .unknown
        if (markAttempt || trusted) && !markedUseful {
            markedUseful = true
            model.outcomes[next.id] = next
            model.recordUsefulScan()
        }
    }

    private func cap(_ name: String) -> String {
        guard let first = name.first else { return name }
        return first.uppercased() + name.dropFirst()
    }
}
