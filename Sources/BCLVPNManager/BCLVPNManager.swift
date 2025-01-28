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
public typealias VPNNotification = TunnelKitManager.VPNNotification

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
        vpnConnectionManager.disconnect()
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
    
    public func getConnectionStatus(completion: @escaping (NEVPNStatus?) -> Void) {
        getConnectionDetails { details in
            completion(details.status)
        }
    }
    
    public func getConnectionInfo(completion: @escaping (ConnectionDetails) -> Void) {
        getConnectionDetails(completion: completion)
    }
    
    private func getConnectionDetails(completion: @escaping (ConnectionDetails)->Void) {
        var ikevDetails = ConnectionDetails(status: .invalid, localizedDescription: nil, serverAddress: nil)
        
        NEVPNManager.shared().loadFromPreferences { error in
            let connection = NEVPNManager.shared().connection
            let status = connection.status
            let localizedDescription = connection.manager.localizedDescription
            let serverAddress = connection.manager.protocolConfiguration?.serverAddress
            ikevDetails = ConnectionDetails(status: status, localizedDescription: localizedDescription, serverAddress: serverAddress)
            if status == .connected {
                completion(ikevDetails)
                return
            }
        }
        
        NETunnelProviderManager.loadAllFromPreferences { managers, error in
            guard let managers else {
                print("managers is nil")
                completion(ConnectionDetails(status: .invalid, localizedDescription: "No VPN connection found", serverAddress: nil))
                return
            }
            
            var deviceVpnDetails = ConnectionDetails(status: .invalid, localizedDescription: nil, serverAddress: nil)
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
                
                if status == .connected {
                    completion(ConnectionDetails(status: status, localizedDescription: localizedDescription, serverAddress: serverAddress))
                    return
                }
            }
            
            completion(deviceVpnDetails)
        }
        
        completion(ikevDetails)
    }
}
