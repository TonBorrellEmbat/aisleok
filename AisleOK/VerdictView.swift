import SwiftUI

struct VerdictView: View {
    let id: UUID
    let outcome: ScanOutcome
    @EnvironmentObject private var model: AppModel
    @State private var showWhy = false

    private var current: ScanOutcome {
        model.outcomes[id] ?? outcome
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Text(current.score.band.word)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(current.score.band.wordColor)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text(current.productName)
                    .font(.title3)
                    .multilineTextAlignment(.center)

                if current.score.band == .unknown {
                    Text("We don’t know this one.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else if current.score.band == .eat {
                    Text("No IBS triggers in this one.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else if let name = current.score.displayName {
                    Button {
                        showWhy = true
                    } label: {
                        Text(Self.displayTrigger(name))
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Why this trigger")
                }

                if current.score.band == .small, let dose = current.score.doseLine {
                    Text(dose)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                if current.score.band != .unknown {
                    Button("This looks wrong") {
                        markWrong()
                    }
                    .buttonStyle(.borderless)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }

                if let url = current.offURL, !current.looksWrongApplied {
                    Link("Open Food Facts", destination: url)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.top, 28)

            Spacer()

            Button {
                primaryAction()
            } label: {
                Text(primaryTitle)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AisleOKColor.paprika)
            .controlSize(.large)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AisleOKColor.canvas.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showWhy) {
            WhySheet(outcome: current)
        }
        .accessibilityElement(children: .combine)
    }

    private var primaryTitle: String {
        current.score.band == .unknown ? "Photo of label" : "Scan another"
    }

    private func primaryAction() {
        if current.score.band == .unknown {
            model.openLabelOCR()
        } else {
            model.popToRoot()
        }
    }

    private func markWrong() {
        var next = current
        next.applyLooksWrong()
        model.update(next)
    }

    private static func displayTrigger(_ name: String) -> String {
        guard let first = name.first else { return name }
        return first.uppercased() + name.dropFirst()
    }
}
