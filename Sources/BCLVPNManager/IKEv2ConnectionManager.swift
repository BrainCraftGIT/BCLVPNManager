//
//  File.swift
//  
//
//  Created by BCL16 on 22/12/24.
//

import NetworkExtension
import Security
import SwiftyBeaver

private let log = SwiftyBeaver.self

public class IKEv2ConnectionManager {
    private static var ikev2ConnectionManager: IKEv2ConnectionManager!
    private static let vpnManager = NEVPNManager.shared()
    
    
    private init() {}

    public static func getInstance(serverAddress: String, username: String, password: String, sharedSecret: String) -> IKEv2ConnectionManager {
        if ikev2ConnectionManager == nil {
            ikev2ConnectionManager = IKEv2ConnectionManager()
            configureIKEv2(serverAddress: serverAddress, username: username, password: password, sharedSecret: sharedSecret)
        }
        
        return ikev2ConnectionManager
    }
    
    public static func updateConfig(serverAddress: String, username: String, password: String, sharedSecret: String) -> IKEv2ConnectionManager {
        //ikev2ConnectionManager = IKEv2ConnectionManager()
        configureIKEv2(serverAddress: serverAddress, username: username, password: password, sharedSecret: sharedSecret)
        
        return ikev2ConnectionManager
    }
    
    static func configureIKEv2(serverAddress: String, username: String, password: String, sharedSecret: String) {
        vpnManager.loadFromPreferences { error in
            if let error {
                log.verbose("VPN preference loading error: \(String(describing: error))")
            } else {
                if KeychainHelper.savePassword(password, account: "pass") {
                    log.verbose("Password saved.")
                } else {
                    log.verbose("Failed to save password.")
                }
                
                let ikev2Protocol = NEVPNProtocolIKEv2()

                // Basic VPN Configuration
                ikev2Protocol.serverAddress = serverAddress
                ikev2Protocol.username = username
                ikev2Protocol.passwordReference = KeychainHelper.getPassword(account: "pass")
                ikev2Protocol.authenticationMethod = .none
                ikev2Protocol.sharedSecretReference = nil//KeychainHelper.getPassword(account: "ss")

                // Additional Settings
                ikev2Protocol.useExtendedAuthentication = true
                ikev2Protocol.disconnectOnSleep = false // Change if you want disconnection during sleep

                vpnManager.protocolConfiguration = ikev2Protocol
                vpnManager.localizedDescription = "VPN Pro-IKEv2"
                vpnManager.isEnabled = true

                vpnManager.saveToPreferences { error in
                    if let error = error {
                        log.verbose("Failed to save VPN configuration: \(error.localizedDescription)")
                    } else {
                        log.verbose("VPN configuration saved successfully.")
                    }
                }
            }
        }
    }

    public func connect() {
        IKEv2ConnectionManager.vpnManager.loadFromPreferences { error in
            if let error = error {
                log.verbose("Failed to load VPN preferences: \(error.localizedDescription)")
                return
            }

            do {
                try IKEv2ConnectionManager.vpnManager.connection.startVPNTunnel()
                log.verbose("VPN connection started.")
            } catch {
                log.verbose("Failed to start VPN connection: \(error.localizedDescription)")
            }
        }
    }

    public func disconnect() {
        IKEv2ConnectionManager.vpnManager.connection.stopVPNTunnel()
        log.verbose("VPN connection stopped.")
    }
}

// Keychain Wrapper for Secure Password Storage
class KeychainHelper {
    static func savePassword(_ password: String, account: String) -> Bool {
        // Convert password to Data
        guard let passwordData = password.data(using: .utf8) else {
            log.verbose("Failed to encode password.")
            return false
        }

        // Create query to delete existing item (if any)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]

        // Delete any existing item
        let delStatus = SecItemDelete(query as CFDictionary)
        if delStatus == errSecSuccess {
            log.verbose("existing item deleted successfully.")
        }

        // Add new item to the Keychain
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecValueData as String: passwordData
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)

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
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecSuccess, let passwordData = item as? Data {
            return passwordData
        } else {
            log.verbose("Failed to retrieve password. Error code: \(status)")
            return nil
        }
    }
}
