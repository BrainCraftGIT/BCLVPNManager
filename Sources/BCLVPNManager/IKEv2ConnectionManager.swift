//
//  File.swift
//  
//
//  Created by BCL16 on 22/12/24.
//

import NetworkExtension
import Security
import SwiftyBeaver
import TunnelKitManager

private let log = SwiftyBeaver.self

public class IKEv2ConnectionManager {
    private static var ikev2ConnectionManager: IKEv2ConnectionManager!
    private static let vpnManager = NEVPNManager.shared()
    private static var password: String? = nil
    private static var serverAddress: String = ""
    private static var username: String? = nil
    private static var sharedSecretReference: Data? = nil
    private static var vpnName: String = ""
    
    private init() {
        
    }
    
    @objc private func vpnDidUpdate(_ notification: Notification) {
        
    }
    
    

    public static func getInstance(serverAddress: String, username: String?, password: String?, sharedSecretReference: Data?, vpnName: String) -> IKEv2ConnectionManager {
        if ikev2ConnectionManager == nil {
            ikev2ConnectionManager = IKEv2ConnectionManager()
            configureIKEv2(serverAddress: serverAddress, username: username, password: password, sharedSecretReference: sharedSecretReference, vpnName: vpnName)
        }
        
        return ikev2ConnectionManager
    }
    
    public static func updateConfig(serverAddress: String, username: String?, password: String?, sharedSecretReference: Data?, vpnName: String) -> IKEv2ConnectionManager {
        ikev2ConnectionManager = IKEv2ConnectionManager()
        configureIKEv2(serverAddress: serverAddress, username: username, password: password, sharedSecretReference: sharedSecretReference, vpnName: vpnName)
        
        return ikev2ConnectionManager
    }
    
    static func configureIKEv2(serverAddress: String, username: String?, password: String?, sharedSecretReference: Data?, vpnName: String) {
        self.username = username
        self.password = password
        self.sharedSecretReference = sharedSecretReference
        self.serverAddress = serverAddress
        self.vpnName = vpnName
    }
}

extension IKEv2ConnectionManager: VPNConnectionManager {
    public static func setup(with config: any VPNConnectionConfig) -> (any VPNConnectionManager)? {
        guard let config = config as? IKEv2ConnectionConfig else {
            print("config isn't valid!")
            return nil
        }
        
        return IKEv2ConnectionManager.getInstance(serverAddress: config.serverIp, username: config.username, password: config.password, sharedSecretReference: config.sharedSecretReference, vpnName: config.name)
    }
    
    public func connect() {
        IKEv2ConnectionManager.vpnManager.loadFromPreferences { error in
            if let error {
                log.verbose("VPN preference loading error: \(String(describing: error))")
            } else {
                if KeychainHelper.savePassword(IKEv2ConnectionManager.password, account: "pass") {
                    log.verbose("Password saved.")
                } else {
                    log.verbose("Failed to save password.")
                }
                
                let ikev2Protocol = NEVPNProtocolIKEv2()

                // Basic VPN Configuration
                let sharedSecretReference = IKEv2ConnectionManager.sharedSecretReference
                ikev2Protocol.username = IKEv2ConnectionManager.username
                ikev2Protocol.passwordReference = KeychainHelper.getPassword(account: "pass")
                ikev2Protocol.serverAddress = IKEv2ConnectionManager.serverAddress
                ikev2Protocol.sharedSecretReference = sharedSecretReference
                ikev2Protocol.localIdentifier = IKEv2ConnectionManager.username
                ikev2Protocol.remoteIdentifier = IKEv2ConnectionManager.serverAddress
                
                let usingSharedSecret = sharedSecretReference != nil
                ikev2Protocol.authenticationMethod = usingSharedSecret ? .sharedSecret : .none
                ikev2Protocol.useExtendedAuthentication = !usingSharedSecret
                ikev2Protocol.disconnectOnSleep = false // Change if you want disconnection during sleep

                IKEv2ConnectionManager.vpnManager.protocolConfiguration = ikev2Protocol
                IKEv2ConnectionManager.vpnManager.localizedDescription = IKEv2ConnectionManager.vpnName
                IKEv2ConnectionManager.vpnManager.isEnabled = true
                
                IKEv2ConnectionManager.vpnManager.isOnDemandEnabled = true
                IKEv2ConnectionManager.vpnManager.onDemandRules = [NEOnDemandRule]()

                IKEv2ConnectionManager.vpnManager.saveToPreferences { error in
                    if let error = error {
                        print("Failed to save VPN configuration: \(error.localizedDescription)")
                    } else {
                        print("VPN configuration saved successfully.")
                        IKEv2ConnectionManager.vpnManager.loadFromPreferences { error in
                            if let error = error {
                                print("Failed to load VPN preferences: \(error.localizedDescription)")
                                return
                            }

                            IKEv2ConnectionManager.vpnManager.saveToPreferences { error in
                                if let error = error {
                                    print("Failed to save VPN configuration: \(error.localizedDescription)")
                                } else {
                                    print("VPN configuration saved successfully twice.")
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
                            }
                        }
                    }
                }
            }
        }
    }

    public func disconnect() {
        IKEv2ConnectionManager.vpnManager.connection.stopVPNTunnel()
        log.verbose("VPN connection stopped.")
    }
}
