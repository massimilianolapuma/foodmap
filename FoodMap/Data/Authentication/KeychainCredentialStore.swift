import Foundation
import Security

/// Keychain-backed implementation of `CredentialStore`.
///
/// Persists the authenticated session as a single JSON item in the login
/// keychain. Only the Apple user identifier and optional display name/email are
/// stored — never any sensitive pantry, diet, or health data.
public struct KeychainCredentialStore: CredentialStore {
    private let service: String
    private let account: String

    public init(
        service: String = "com.massimilianolapuma.foodmap.auth",
        account: String = "session"
    ) {
        self.service = service
        self.account = account
    }

    public func load() throws -> AuthenticatedUser? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        switch status {
        case errSecSuccess:
            guard let data = item as? Data else { return nil }
            return try JSONDecoder().decode(AuthenticatedUser.self, from: data)
        case errSecItemNotFound:
            return nil
        default:
            throw FoodMapError.persistence(reason: "Keychain read failed (\(status)).")
        }
    }

    public func save(_ user: AuthenticatedUser) throws {
        let data = try JSONEncoder().encode(user)
        let query = baseQuery()
        let attributes: [String: Any] = [kSecValueData as String: data]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        switch updateStatus {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            var insert = query
            insert[kSecValueData as String] = data
            insert[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let addStatus = SecItemAdd(insert as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw FoodMapError.persistence(reason: "Keychain write failed (\(addStatus)).")
            }
        default:
            throw FoodMapError.persistence(reason: "Keychain update failed (\(updateStatus)).")
        }
    }

    public func clear() throws {
        let status = SecItemDelete(baseQuery() as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw FoodMapError.persistence(reason: "Keychain delete failed (\(status)).")
        }
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
