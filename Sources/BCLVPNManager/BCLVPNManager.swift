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
    var status: NEVPNStatus?
    var localizedDescription: String?
    var serverAddress: String?
}

public typealias VPNStatus = TunnelKitManager.VPNStatus
public typealias VPNNotification = TunnelKitManager.VPNNotification

public class BCLVPNManager {
    public static let shared = BCLVPNManager()
    private var vpnConnectionManager: VPNConnectionManager!
    //public var connectionType: VPNConnectionType
    public var connectionStatus: VPNStatus {
        get {
            getConnectionStatus()
        }
    }
    
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
    
    public func getConnectionStatus() -> VPNStatus {
        return .disconnected
    }
    
    public func getConnectionInfo() {
        
    }
}
