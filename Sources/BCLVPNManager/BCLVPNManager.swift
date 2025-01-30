//
//  File.swift
//  
//
//  Created by BCL16 on 12/1/25.
//

import Foundation
import TunnelKitManager
import NetworkExtension

public enum VPNConnectionType: Int {
    case ikev2
    case wireguard
    case openVpn
}

public struct ConnectionDetails {
    public var status: NEVPNStatus?
    public var localizedDescription: String?
    public var serverAddress: String?
}

public typealias VPNStatus = TunnelKitManager.VPNStatus
//public typealias VPNNotification = TunnelKitManager.VPNNotification

public class BCLVPNManager {
    public static let shared = BCLVPNManager()
    private var vpnConnectionManager: VPNConnectionManager!
    //public var connectionType: VPNConnectionType
    //public var connectionStatus: VPNStatus = .disconnected
    
    private init() {
        
    }
    
    public func connect() {
        vpnConnectionManager.connect()
    }
    
    public func disconnect() {
        if vpnConnectionManager == nil {
            NEVPNManager.shared().loadFromPreferences { error in
                let connection = NEVPNManager.shared().connection
                let status = connection.status
                
                if status == .connected {
                    connection.stopVPNTunnel()
                }
            }
            
            NETunnelProviderManager.loadAllFromPreferences() { managers, error in
                guard let managers else {
                    return
                }
                
                for manager in managers {
                    if manager.connection.status == .connected {
                        manager.connection.stopVPNTunnel()
                    }
                }
            }
        } else {
            vpnConnectionManager.disconnect()
        }
    }
    
    public func setup(with config: VPNConnectionConfig) {
        if config is IKEv2ConnectionConfig {
            vpnConnectionManager = IKEv2ConnectionManager.setup(with: config)
        } else if config is OpenVPNConnectionConfig {
            vpnConnectionManager = OpenVPNConnectionManager.setup(with: config)!
        } else if config is WireGuardConnectionConfig {
            vpnConnectionManager = WireGuardConnectionManager.setup(with: config)
        }
    }
    
    func getConnectedVPNManager(completion: @escaping (VPNConnectionManager?) -> Void) {
        NEVPNManager.shared().loadFromPreferences { error in
            let connection = NEVPNManager.shared().connection
            let status = connection.status
            
            if status == .connected {
                let vpnManager = NEVPNManager.shared()
                let ikevProtocol = vpnManager.protocolConfiguration as! NEVPNProtocolIKEv2
                let ikevConfig = IKEv2ConnectionConfig(name: vpnManager.localizedDescription!, remoteIdentifier: ikevProtocol.remoteIdentifier!, serverIp: ikevProtocol.serverAddress!, username: ikevProtocol.username, password: String(data: ikevProtocol.passwordReference!, encoding: .utf8), sharedSecretReference: ikevProtocol.sharedSecretReference)
                let ikevConnectionManager = IKEv2ConnectionManager.setup(with: ikevConfig)
                completion(ikevConnectionManager)
                return
            }
            
            NETunnelProviderManager.loadAllFromPreferences() { managers, error in
                guard let managers else {
                    completion(nil)
                    return
                }
                
                for manager in managers {
                    let status = manager.connection.status
                    if status == .connected {
                        let protocolConfig = manager.protocolConfiguration as! NETunnelProviderProtocol
                        let tunnelIdentifier = protocolConfig.providerBundleIdentifier!
                        if tunnelIdentifier.lowercased().contains("openvpn") {
                            let ovpnConfig = OpenVPNConnectionConfig(name: "", username: "", password: "", appGroup: "", tunnelIdentifier: "", config: "")
                            let ovpnManager = OpenVPNConnectionManager.setup(with: ovpnConfig)
                            completion(ovpnManager)
                        } else {
                            let wgConfig = WireGuardConnectionConfig(name: "", tunnelIdentifier: "", appGroup: "", clientPrivateKey: "", clientAddress: "", serverPublicKey: "", serverAddress: "", serverPort: "", dns: "")
                            let wgManager = WireGuardConnectionManager.setup(with: wgConfig)
                            completion(wgManager)
                        }
                    }
                }
                
                completion(nil)
            }
        }
    }
    
    public func getConnectionStatus(completion: @escaping (NEVPNStatus?) -> Void) {
        getConnectionDetails { details in
            completion(details.status)
        }
    }
    
    public func getConnectionInfo(completion: @escaping (ConnectionDetails) -> Void) {
        getConnectionDetails(completion: completion)
    }
    
    private func getConnectionDetails(completion: @escaping (ConnectionDetails) -> Void) {
        var ikevDetails: ConnectionDetails?
        
        NEVPNManager.shared().loadFromPreferences { error in
            let connection = NEVPNManager.shared().connection
            let status = connection.status
            let localizedDescription = connection.manager.localizedDescription
            let serverAddress = connection.manager.protocolConfiguration?.serverAddress
            ikevDetails = ConnectionDetails(status: status, localizedDescription: localizedDescription, serverAddress: serverAddress)
            
            if status == .connected {
                completion(ikevDetails!)
                return
            }
            
            NETunnelProviderManager.loadAllFromPreferences { managers, error in
                guard let managers else {
                    completion(ikevDetails ?? ConnectionDetails(status: .invalid, localizedDescription: nil, serverAddress: nil))
                    return
                }
                
                var deviceVpnDetails: ConnectionDetails?
                if let manager = managers.first {
                    let connection = manager.connection
                    
                    let status = connection.status
                    let localizedDescription = manager.localizedDescription
                    let serverAddress = manager.protocolConfiguration?.serverAddress
                    deviceVpnDetails = ConnectionDetails(status: status, localizedDescription: localizedDescription, serverAddress: serverAddress)
                }
                
                for manager in managers {
                    let connection = manager.connection
                    let status = connection.status
                    let localizedDescription = manager.localizedDescription
                    let serverAddress = manager.protocolConfiguration?.serverAddress
                    let vpnDetails = ConnectionDetails(status: status, localizedDescription: localizedDescription, serverAddress: serverAddress)
                    
                    if status == .connected {
                        completion(vpnDetails)
                        return
                    }
                }
                
                guard let deviceVpnDetails else {
                    completion(ikevDetails ?? ConnectionDetails(status: .invalid, localizedDescription: nil, serverAddress: nil))
                    return
                }
                completion(deviceVpnDetails)
            }
        }
    }
}
