import SwiftUI

struct WhySheet: View {
    let outcome: ScanOutcome
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                if let tag = TriggerCatalog.tags.first(where: { $0.id == outcome.score.tagId }) {
                    let copy = WhyCopy.lines(for: tag)
                    Text(copy.what)
                    Text(copy.why)
                    Text(copy.small)
                } else if let name = outcome.score.displayName {
                    Text("\(Self.cap(name)) is on AisleOK’s trigger list.")
                    Text("Some people with a sensitive gut notice it more than others.")
                    Text("Small means a modest serve, not a full portion.")
                }
                Spacer()
            }
            .font(.body)
            .padding()
            .navigationTitle(outcome.score.displayName.map(Self.cap) ?? "Why")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private static func cap(_ name: String) -> String {
        guard let first = name.first else { return name }
        return first.uppercased() + name.dropFirst()
    }
}
