import SwiftData
import SwiftUI

/// Edit the user's dietary profile. Sensitive data stays on device.
struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile {
        if let existing = profiles.first { return existing }
        let created = UserProfile()
        modelContext.insert(created)
        try? modelContext.save()
        return created
    }

    var body: some View {
        NavigationStack {
            Form {
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
                    Stepper(
                        "Notify \(profile.expiryAlertLeadDays) day(s) before",
                        value: Binding(get: { profile.expiryAlertLeadDays }, set: { profile.expiryAlertLeadDays = $0
                            save()
                        }),
                        in: 1...14
                    )
                    Stepper(
                        "Household size: \(profile.householdSize)",
                        value: Binding(get: { profile.householdSize }, set: { profile.householdSize = $0
                            save()
                        }),
                        in: 1...12
                    )
                }
            }
            .navigationTitle("Profile")
        }
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

    private func save() {
        try? modelContext.save()
    }
}
