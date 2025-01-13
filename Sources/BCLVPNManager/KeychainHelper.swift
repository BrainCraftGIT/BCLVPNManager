//
//  File.swift
//  
//
//  Created by BCL16 on 13/1/25.
//

import Foundation
import SwiftyBeaver

private let log = SwiftyBeaver.self
// Keychain Wrapper for Secure Password Storage
class KeychainHelper {
    static func savePassword(_ password: String?, account: String) -> Bool {
        // Create query to delete existing item (if any)
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
            kSecAttrAccount as String: account
        ]
        
        let delStatus = SecItemDelete(query as CFDictionary)
        if delStatus == errSecSuccess {
            log.verbose("existing item deleted successfully.")
        }
        
        guard let passwordData = password?.data(using: .utf8) else {
            log.verbose("password is invalid!")
            return false
        }
        
        query[kSecValueData as String] = passwordData
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            log.verbose("Password saved successfully.")
            return true
        } else {
            log.verbose("Failed to save password. Error code: \(status)")
            return false
        }
    }

    static func getPassword(account: String) -> Data? {
        // Create query to retrieve password
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
            kSecAttrAccount as String: account,
            kSecMatchLimitOne as String: true,
            kSecReturnPersistentRef as String: true
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status != errSecSuccess {
            log.verbose("Failed to retrieve password. Error code: \(status)")
            return nil
        }

        let passwordData = item as? Data
        return passwordData
    }
}
