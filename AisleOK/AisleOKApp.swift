import SwiftUI

@main
struct AisleOKApp: App {
    @StateObject private var settings: TriggerSettings
    @StateObject private var store: StoreKitStore
    @StateObject private var model: AppModel

    init() {
        let settings = TriggerSettings()
        let store = StoreKitStore()
        _settings = StateObject(wrappedValue: settings)
        _store = StateObject(wrappedValue: store)
        _model = StateObject(wrappedValue: AppModel(settings: settings, store: store))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .environmentObject(settings)
                .environmentObject(store)
                .tint(.primary)
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        NavigationStack(path: $model.path) {
            ScanHomeView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .verdict(let id):
                        if let outcome = model.outcomes[id] {
                            VerdictView(id: id, outcome: outcome)
                        } else {
                            Text("We don’t know this one.")
                                .foregroundStyle(.secondary)
                        }
                    case .settings:
                        SettingsView()
                    case .produceSearch:
                        ProduceSearchView()
                    case .labelOCR:
                        LabelOCRView()
                    }
                }
        }
        .fullScreenCover(isPresented: $model.showOnboarding) {
            OnboardingView()
                .environmentObject(model)
                .environmentObject(model.settings)
        }
        .sheet(isPresented: $model.showPaywall) {
            if let recap = model.lastOutcome {
                PaywallView(recap: recap)
                    .presentationDetents([.medium, .large])
                    .environmentObject(model.store)
            }
        }
    }
}
