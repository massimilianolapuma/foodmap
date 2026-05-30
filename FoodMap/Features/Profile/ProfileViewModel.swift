import Foundation

/// Owns the imperative alert behavior for the profile screen: requesting
/// notification authorization and keeping scheduled alerts in sync with the
/// user's settings. Depends only on Domain protocols/use cases.
@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var permissionDenied = false

    private let scheduler: NotificationScheduler
    private let syncAlerts: SyncExpiryAlertsUseCase

    init(scheduler: NotificationScheduler, syncAlerts: SyncExpiryAlertsUseCase) {
        self.scheduler = scheduler
        self.syncAlerts = syncAlerts
    }

    /// Applies an alerts on/off change. When enabling, requests authorization
    /// first; if the user denies, surfaces guidance and reports the effective
    /// state as disabled so the caller can revert the toggle.
    /// - Returns: the effective enabled state after handling authorization.
    func setAlerts(enabled: Bool, leadDays: Int) async -> Bool {
        if enabled {
            let granted = await (try? scheduler.requestAuthorization()) ?? false
            guard granted else {
                permissionDenied = true
                try? await syncAlerts(leadDays: leadDays, alertsEnabled: false)
                return false
            }
        }
        try? await syncAlerts(leadDays: leadDays, alertsEnabled: enabled)
        return enabled
    }

    /// Re-syncs scheduled alerts without prompting for authorization. Used when
    /// the lead-days change or when the screen appears.
    func resync(leadDays: Int, alertsEnabled: Bool) async {
        try? await syncAlerts(leadDays: leadDays, alertsEnabled: alertsEnabled)
    }
}
