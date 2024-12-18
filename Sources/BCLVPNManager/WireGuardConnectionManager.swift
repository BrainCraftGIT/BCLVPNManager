//
//  File.swift
//  
//
//  Created by BCL16 on 17/12/24.
//

import Foundation
import TunnelKitManager
import TunnelKitWireGuard
import TunnelKitWireGuardAppExtension

public typealias WireGuardTunnelProvider = TunnelKitWireGuardAppExtension.WireGuardTunnelProvider

public class WireGuardConnectionManager {
    private static var wireguardConnectionManager: WireGuardConnectionManager!
    private static let vpn = NetworkExtensionVPN()
    let name: String
    let tunnelIdentifier: String
    let appGroup: String
    let clientPrivateKey: String
    let clientAddress: String
    let serverPublicKey: String
    let serverAddress: String
    let serverPort: String
    static var vpnStatus : VPNStatus = .disconnected
    
    public static func getInstance(name: String,
                                   tunnelIdentifier: String,
                                   appGroup: String,
                                   clientPrivateKey: String,
                                   clientAddress: String,
                                   serverPublicKey: String,
                                   serverAddress: String,
                                   serverPort: String) -> WireGuardConnectionManager {
        if wireguardConnectionManager == nil {
            wireguardConnectionManager = WireGuardConnectionManager(name: name, tunnelIdentifier: tunnelIdentifier, appGroup: appGroup, clientPrivateKey: clientPrivateKey, clientAddress: clientAddress, serverPublicKey: serverPublicKey, serverAddress: serverAddress, serverPort: serverPort)
            
            Task {
                await vpn.prepare()
            }
        }
        
        return wireguardConnectionManager
    }
    
    public static func updateConfig(name: String,
                                    tunnelIdentifier: String,
                                    appGroup: String,
                                    clientPrivateKey: String,
                                    clientAddress: String,
                                    serverPublicKey: String,
                                    serverAddress: String,
                                    serverPort: String) -> WireGuardConnectionManager {
        wireguardConnectionManager = WireGuardConnectionManager(name: name, tunnelIdentifier: tunnelIdentifier, appGroup: appGroup, clientPrivateKey: clientPrivateKey, clientAddress: clientAddress, serverPublicKey: serverPublicKey, serverAddress: serverAddress, serverPort: serverPort)
        
        Task {
            await vpn.prepare()
        }
        
        return wireguardConnectionManager
    }
    
    private init(name: String,
                tunnelIdentifier: String,
                appGroup: String,
                clientPrivateKey: String,
                clientAddress: String,
                serverPublicKey: String,
                serverAddress: String,
                serverPort: String) {
        self.name = name
        self.tunnelIdentifier = tunnelIdentifier
        self.appGroup = appGroup
        self.clientPrivateKey = clientPrivateKey
        self.clientAddress = clientAddress
        self.serverPublicKey = serverPublicKey
        self.serverAddress = serverAddress
        self.serverPort = serverPort
    }
    
    @objc
    private static func VPNStatusDidChange(notification: Notification) {
        vpnStatus = notification.vpnStatus
        print("VPNStatusDidChange: \(vpnStatus)")
    }

    @objc
    private static func VPNDidFail(notification: Notification) {
        print("VPNStatusDidFail: \(notification.vpnError.localizedDescription)")
    }
    
    public func connect() {
        var builder: WireGuard.ConfigurationBuilder
        do {
            builder = try WireGuard.ConfigurationBuilder(clientPrivateKey)
        } catch {
            print(">>> \(error)")
            return
        }
        builder.addresses = [clientAddress]
        builder.dnsServers = ["8.8.8.8"]
        do {
            try builder.addPeer(serverPublicKey, endpoint: "\(serverAddress):\(serverPort)")
        } catch {
            print(">>> \(error)")
            return
        }
        builder.addDefaultGatewayIPv4(toPeer: 0)
        let cfg = builder.build()

        let providerCfg = WireGuard.ProviderConfiguration(name, appGroup: appGroup, configuration: cfg)

        Task {
            let extra = NetworkExtensionExtra()
            try await WireGuardConnectionManager.vpn.reconnect(
                tunnelIdentifier,
                configuration: providerCfg,
                extra: extra,
                after: .seconds(2)
            )
        }
    }

    public func disconnect() {
        Task {
            await WireGuardConnectionManager.vpn.disconnect()
        }
    }
}
