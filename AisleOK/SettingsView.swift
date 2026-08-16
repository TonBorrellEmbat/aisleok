import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: TriggerSettings
    @EnvironmentObject private var store: StoreKitStore

    var body: some View {
        List {
            Section("Triggers") {
                ForEach(TriggerFamily.allCases) { family in
                    Toggle(family.title, isOn: settings.binding(for: family))
                }
            }
            Section {
                Button("Restore purchases") {
                    Task { await store.restore() }
                }
            }
            Section {
                Link("Privacy", destination: AisleOKLinks.privacy)
                Link("Terms", destination: AisleOKLinks.terms)
            } footer: {
                Text("AisleOK is a wellness journal, not a medical device.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
