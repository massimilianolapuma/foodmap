import SwiftData
import SwiftUI

/// Edit the user's dietary profile and expiry-alert settings. Sensitive data stays on device.
struct ProfileView: View {
    @EnvironmentObject private var container: AppContainer
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.id) private var profiles: [UserProfile]
    @State private var model: ProfileViewModel?

    private var profile: UserProfile {
        if let existing = profiles.first { return existing }
        let created = UserProfile()
        modelContext.insert(created)
        try? modelContext.save()
        return created
    }

    var body: some View {
        NavigationStack {
            Group {
                if let model {
                    ProfileForm(model: model, authModel: container.authViewModel, profile: profile, save: save)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Profile")
        }
        .task {
            if model == nil {
                model = ProfileViewModel(
                    scheduler: container.notificationScheduler,
                    syncAlerts: container.syncExpiryAlerts
                )
            }
            await model?.resync(leadDays: profile.expiryAlertLeadDays, alertsEnabled: profile.alertsEnabled)
        }
    }

    private func save() {
        try? modelContext.save()
    }
}

/// Thin form bound to the profile `@Model`; routes alert changes through the view model.
private struct ProfileForm: View {
    @ObservedObject var model: ProfileViewModel
    @ObservedObject var authModel: AuthViewModel
    let profile: UserProfile
    let save: () -> Void

    var body: some View {
        Form {
            Section("You") {
                TextField("Your name", text: nameBinding)
                    .textContentType(.givenName)
                    .submitLabel(.done)
                    .onSubmit(save)
                    .accessibilityIdentifier("profile.displayName")
            }

            Section("Diet") {
                Picker("Diet type", selection: Binding(
                    get: { profile.dietType },
                    set: { profile.dietType = $0
                        save()
                    }
                )) {
                    ForEach(DietType.allCases, id: \.self) { Text($0.displayName).tag($0) }
                }
            }

            Section("Allergens") {
                ForEach(Allergen.allCases, id: \.self) { allergen in
                    Toggle(allergen.displayName, isOn: binding(for: allergen))
                }
            }

            Section("Alerts") {
                Toggle("Expiry alerts", isOn: alertsBinding)
                    .accessibilityIdentifier("profile.alertsToggle")
                if profile.alertsEnabled {
                    Stepper(
                        "Notify \(profile.expiryAlertLeadDays) day(s) before",
                        value: leadDaysBinding,
                        in: 1...14
                    )
                    .accessibilityIdentifier("profile.leadDaysStepper")
                }
                Stepper(
                    "Household size: \(profile.householdSize)",
                    value: Binding(get: { profile.householdSize }, set: { profile.householdSize = $0
                        save()
                    }),
                    in: 1...12
                )
                .accessibilityIdentifier("profile.householdStepper")
            }

            Section("Account") {
                LabeledContent("Signed in as", value: accountDescription)
                Button("Sign out", role: .destructive) {
                    Task { await authModel.signOut() }
                }
                .accessibilityIdentifier("profile.signOut")
            }
        }
        .alert("Notifications are off", isPresented: $model.permissionDenied) {
            Button("Open Settings") { openSettings() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enable notifications in Settings to receive expiry alerts.")
        }
    }

    private var accountDescription: String {
        let localName = profile.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let user = authModel.user else {
            return localName.isEmpty ? "Local account" : localName
        }
        if user.isAnonymous {
            return localName.isEmpty ? "Local account" : localName
        }
        return user.email ?? user.displayName ?? "Apple account"
    }

    private var nameBinding: Binding<String> {
        Binding(
            get: { profile.displayName },
            set: { newValue in
                // Sanitize and cap length on write; let SwiftData autosave persist
                // intermediate edits, with an explicit save on submit/focus loss.
                profile.displayName = UserProfile.sanitizedDisplayName(newValue)
            }
        )
    }

    private var alertsBinding: Binding<Bool> {
        Binding(
            get: { profile.alertsEnabled },
            set: { newValue in
                profile.alertsEnabled = newValue
                save()
                Task {
                    let applied = await model.setAlerts(enabled: newValue, leadDays: profile.expiryAlertLeadDays)
                    if applied != newValue {
                        profile.alertsEnabled = applied
                        save()
                    }
                }
            }
        )
    }

    private var leadDaysBinding: Binding<Int> {
        Binding(
            get: { profile.expiryAlertLeadDays },
            set: { newValue in
                profile.expiryAlertLeadDays = newValue
                save()
                Task { await model.resync(leadDays: newValue, alertsEnabled: profile.alertsEnabled) }
            }
        )
    }

    private func binding(for allergen: Allergen) -> Binding<Bool> {
        Binding(
            get: { profile.allergens.contains(allergen) },
            set: { isOn in
                var current = Set(profile.allergens)
                if isOn { current.insert(allergen) } else { current.remove(allergen) }
                profile.allergens = Array(current)
                save()
            }
        )
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
