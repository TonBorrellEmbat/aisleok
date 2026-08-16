import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var settings: TriggerSettings

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(TriggerFamily.allCases) { family in
                        Toggle(family.title, isOn: settings.binding(for: family))
                    }
                } header: {
                    Text("What should AisleOK watch for?")
                } footer: {
                    Text("You can change these later in Settings. AisleOK is a wellness journal, not a medical device.")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("AisleOK")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Continue") {
                        model.finishOnboarding()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
