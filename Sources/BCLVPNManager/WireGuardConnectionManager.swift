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
import SwiftyBeaver
import NetworkExtension

private let log = SwiftyBeaver.self

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
    let dns: String
    
    static var vpnStatus : VPNStatus = .disconnected
    
    public static func getInstance(name: String,
                                   tunnelIdentifier: String,
                                   appGroup: String,
                                   clientPrivateKey: String,
                                   clientAddress: String,
                                   serverPublicKey: String,
                                   serverAddress: String,
                                   serverPort: String,
                                   dns: String) -> WireGuardConnectionManager {
        if wireguardConnectionManager == nil {
            wireguardConnectionManager = WireGuardConnectionManager(name: name, tunnelIdentifier: tunnelIdentifier, appGroup: appGroup, clientPrivateKey: clientPrivateKey, clientAddress: clientAddress, serverPublicKey: serverPublicKey, serverAddress: serverAddress, serverPort: serverPort, dns: dns)
            
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
                                    serverPort: String,
                                    dns: String) -> WireGuardConnectionManager {
        wireguardConnectionManager = WireGuardConnectionManager(name: name, tunnelIdentifier: tunnelIdentifier, appGroup: appGroup, clientPrivateKey: clientPrivateKey, clientAddress: clientAddress, serverPublicKey: serverPublicKey, serverAddress: serverAddress, serverPort: serverPort, dns: dns)
        
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
                 serverPort: String,
                 dns: String) {
        self.name = name
        self.tunnelIdentifier = tunnelIdentifier
        self.appGroup = appGroup
        self.clientPrivateKey = clientPrivateKey
        self.clientAddress = clientAddress
        self.serverPublicKey = serverPublicKey
        self.serverAddress = serverAddress
        self.serverPort = serverPort
        self.dns = dns
    }
    
    public func getConnectionDetail() async throws -> (status: NEVPNStatus?, localizedDescription: String?, serverAddress: String?) {
        let result = try await WireGuardConnectionManager.vpn.getConnectionDetails()
        return result
    }
    
    public func connect() {
        var builder: WireGuard.ConfigurationBuilder
        do {
            builder = try WireGuard.ConfigurationBuilder(clientPrivateKey)
        } catch {
            log.verbose(">>> \(error)")
            return
        }
        
        builder.addresses = [clientAddress]
        builder.dnsServers = [dns]
        do {
            try builder.addPeer(serverPublicKey, endpoint: "\(serverAddress):\(serverPort)")
        } catch {
            log.verbose(">>> \(error)")
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
