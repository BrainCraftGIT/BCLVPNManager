//
//  VPNConnectionManager.swift
//  VPN Pro
//
//  Created by BCL16 on 15/12/24.
//

import UIKit
import Combine
import TunnelKitManager
import TunnelKitOpenVPN
import TunnelKitOpenVPNAppExtension
import NetworkExtension

public typealias OpenVPNTunnelProvider = TunnelKitOpenVPNAppExtension.OpenVPNTunnelProvider

public class OpenVPNConnectionManager {
    private static var openVpnConnectionManager: OpenVPNConnectionManager!
    
    var config: String
    var appGroup: String
    var tunnelIdentifier: String
    var user: String
    var pass: String
    var name: String
    
    private static let vpn = NetworkExtensionVPN()
    private static var cfg: OpenVPN.ProviderConfiguration?
    
    static var vpnStatus : VPNStatus = .disconnected
    
    public static func getInstance(config: String, appGroup: String, tunnelIdentifier: String, user: String, pass: String, name: String) -> OpenVPNConnectionManager {
        if openVpnConnectionManager == nil {
            openVpnConnectionManager = OpenVPNConnectionManager(config: config, appGroup: appGroup, tunnelIdentifier: tunnelIdentifier, user: user, pass: pass, name: name)
            
            Task {
                await vpn.prepare()
            }
        }
        
        return openVpnConnectionManager
    }
    
    public static func updateConfig(config: String, appGroup: String, tunnelIdentifier: String, user: String, pass: String, name: String) -> OpenVPNConnectionManager {
        openVpnConnectionManager = OpenVPNConnectionManager(config: config, appGroup: appGroup, tunnelIdentifier: tunnelIdentifier, user: user, pass: pass, name: name)
        
        Task {
            await vpn.prepare()
        }
        
        return openVpnConnectionManager
    }
    
    private init(config: String, appGroup: String, tunnelIdentifier: String, user: String, pass: String, name: String) {
        self.config = config
        self.appGroup = appGroup
        self.tunnelIdentifier = tunnelIdentifier
        self.user = user
        self.pass = pass
        self.name = name
    }
    
    public func getConnectionDetail() async throws -> (status: NEVPNStatus?, localizedDescription: String?, serverAddress: String?) {
        let result = try await OpenVPNConnectionManager.vpn.getConnectionDetails()
        return result
    }
}

extension OpenVPNConnectionManager: VPNConnectionManager {
    public static func setup(with config: any VPNConnectionConfig) -> (any VPNConnectionManager)? {
        guard let config = config as? OpenVPNConnectionConfig else {
            print("config isn't valid!")
            return nil
        }
        
        return OpenVPNConnectionManager.getInstance(config: config.config, appGroup: config.appGroup, tunnelIdentifier: config.tunnelIdentifier, user: config.username, pass: config.password, name: config.name)
    }
    
    public func connect() {
        if OpenVPNConnectionManager.vpnStatus == .connected || OpenVPNConnectionManager.vpnStatus == .connecting {
            disconnect()
        }
        
        let builder : OpenVPN.ConfigurationParser.Result
        do {
            builder = try OpenVPN.ConfigurationParser.parsed(fromContents: self.config)
        } catch {
            debugPrint(error.localizedDescription)
            return
        }
        
        OpenVPNConnectionManager.cfg = OpenVPN.ProviderConfiguration.init(self.name, appGroup: appGroup, configuration: builder.configuration)
        OpenVPNConnectionManager.cfg?.username = self.user
        OpenVPNConnectionManager.cfg?.shouldDebug = true
        
        let keychain = Keychain(group: appGroup)
        let passwordRef : Data
        do {
            passwordRef = try keychain.set(password: self.pass, for: self.user, context: tunnelIdentifier)
        } catch {
            debugPrint(error.localizedDescription)
            return
        }
        
        
        guard let cfg = OpenVPNConnectionManager.cfg else { return }
        
        Task {
            var extra = NetworkExtensionExtra()
            extra.passwordReference = passwordRef
            try await OpenVPNConnectionManager.vpn.reconnect(tunnelIdentifier, configuration:cfg ,extra: extra, after: .seconds(2))
        }
    }
    
    public func disconnect() {
        Task {
            await OpenVPNConnectionManager.vpn.disconnect()
        }
    }
}
