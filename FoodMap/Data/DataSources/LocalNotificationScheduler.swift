import Foundation
import UserNotifications

/// Schedules local expiry notifications via UserNotifications.
public final class LocalNotificationScheduler: NotificationScheduler {
    private let center: UNUserNotificationCenter

    public init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    public func requestAuthorization() async throws -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            throw FoodMapError.notificationPermissionDenied
        }
    }

    public func scheduleExpiryAlert(for product: Product, leadDays: Int) async throws {
        guard let expiry = product.expiryDate else { return }
        guard let fireDate = Calendar.current.date(byAdding: .day, value: -leadDays, to: expiry),
              fireDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Expiring soon"
        content.body = "\(product.name) expires on \(Self.formatter.string(from: expiry))."
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: product.id.uuidString, content: content, trigger: trigger)

        do {
            try await center.add(request)
        } catch {
            throw FoodMapError.persistence(reason: error.localizedDescription)
        }
    }

    public func cancelAlert(for productID: UUID) async {
        center.removePendingNotificationRequests(withIdentifiers: [productID.uuidString])
    }

    public func cancelAll() async {
        center.removeAllPendingNotificationRequests()
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}
