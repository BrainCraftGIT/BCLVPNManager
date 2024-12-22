//
//  File.swift
//  
//
//  Created by BCL16 on 22/12/24.
//

import NetworkExtension

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
    
    static func configureIKEv2(serverAddress: String, username: String, password: String, sharedSecret: String) {
        let ikev2Protocol = NEVPNProtocolIKEv2()

        // Basic VPN Configuration
        ikev2Protocol.serverAddress = serverAddress
        ikev2Protocol.username = username
        ikev2Protocol.passwordReference = KeychainWrapper.savePassword(password)
        ikev2Protocol.authenticationMethod = .sharedSecret
        ikev2Protocol.sharedSecretReference = KeychainWrapper.savePassword(sharedSecret)

        // Additional Settings
        ikev2Protocol.useExtendedAuthentication = true
        ikev2Protocol.disconnectOnSleep = false // Change if you want disconnection during sleep

        vpnManager.protocolConfiguration = ikev2Protocol
        vpnManager.localizedDescription = "My IKEv2 VPN"
        vpnManager.isEnabled = true

        vpnManager.saveToPreferences { error in
            if let error = error {
                print("Failed to save VPN configuration: \(error.localizedDescription)")
            } else {
                print("VPN configuration saved successfully.")
            }
        }
    }

    public func connect() {
        IKEv2ConnectionManager.vpnManager.loadFromPreferences { error in
            if let error = error {
                print("Failed to load VPN preferences: \(error.localizedDescription)")
                return
            }

            do {
                try IKEv2ConnectionManager.vpnManager.connection.startVPNTunnel()
                print("VPN connection started.")
            } catch {
                print("Failed to start VPN connection: \(error.localizedDescription)")
            }
        }
    }

    public func disconnect() {
        IKEv2ConnectionManager.vpnManager.connection.stopVPNTunnel()
        print("VPN connection stopped.")
    }
}

// Keychain Wrapper for Secure Password Storage
class KeychainWrapper {
    static func savePassword(_ password: String) -> Data? {
        guard let passwordData = password.data(using: .utf8) else { return nil }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "VPNPassword",
            kSecValueData as String: passwordData
        ]

        SecItemDelete(query as CFDictionary) // Remove old item
        let status = SecItemAdd(query as CFDictionary, nil)

        return status == errSecSuccess ? passwordData : nil
    }
}
