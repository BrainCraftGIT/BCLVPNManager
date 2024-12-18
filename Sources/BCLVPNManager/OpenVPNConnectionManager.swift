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

public typealias OpenVPNTunnelProvider = TunnelKitOpenVPNAppExtension.OpenVPNTunnelProvider
public typealias VPNStatus = TunnelKitManager.VPNStatus
public typealias VPNNotification = TunnelKitManager.VPNNotification

public class OpenVPNConnectionManager: ObservableObject {
    private static var openVpnConnectionManager: OpenVPNConnectionManager!
    
    var config: String
    var appGroup: String
    var tunnelIdentifier: String
    var user: String
    var pass: String
    var name: String
    private static let vpn = NetworkExtensionVPN()
    private let keychain : Keychain
    private static var cfg: OpenVPN.ProviderConfiguration?
    
    static var vpnStatus : VPNStatus = .disconnected
//    private var credential : VPNCredentials? = AppData.default.vpnServerList?.data?.vpnCredentials
//    private var connectedServer : CountryVPNServer? = AppData.default.vpnServerList?.data?.vpnServers?.first?.countries?.first?.vpnServers?.first
    
    public static func getInstance(config: String, appGroup: String, tunnelIdentifier: String, user: String, pass: String, name: String) -> OpenVPNConnectionManager {
        if openVpnConnectionManager == nil {
            openVpnConnectionManager = OpenVPNConnectionManager(config: config, appGroup: appGroup, tunnelIdentifier: tunnelIdentifier, user: user, pass: pass, name: name)
            
            Task {
                await vpn.prepare()
            }
        }
        
        return openVpnConnectionManager
    }
    
    private init(config: String, appGroup: String, tunnelIdentifier: String, user: String, pass: String, name: String){
        self.config = config
        self.appGroup = appGroup
        self.tunnelIdentifier = tunnelIdentifier
        self.user = user
        self.pass = pass
        self.name = name
        
        keychain = Keychain(group: appGroup)
    }
    
//    func setServer(server : CountryVPNServer?){
//        self.connectedServer = server
//    }
    
    
    @objc
    private static func VPNStatusDidChange(notification: Notification) {
        vpnStatus = notification.vpnStatus
        if vpnStatus == .connected{
            //save connect time
            //AppData.default.startConnectionTime = .now
        }
        if vpnStatus == .disconnected{
            //end conncect and sent data to server
            if let cfg = cfg, let url = cfg.urlForDebugLog, let str = try? String(contentsOf: url){
                debugPrint(str)
            }
            if let cfg = cfg{
                debugPrint(cfg.lastError.debugDescription)
            }
        }
        print("VPNStatusDidChange: \(vpnStatus)")
    }

    @objc
    private static func VPNDidFail(notification: Notification) {
        print("VPNStatusDidFail: \(notification.vpnError.localizedDescription)")
    }
    
    public func disconnect() {
        Task{
            await OpenVPNConnectionManager.vpn.disconnect()
        }
        
    }
    
    public func connect(){
        if OpenVPNConnectionManager.vpnStatus == .connected || OpenVPNConnectionManager.vpnStatus == .connecting{
            disconnect()
        }
        
        let builder : OpenVPN.ConfigurationParser.Result
        do{
            builder = try OpenVPN.ConfigurationParser.parsed(fromContents: self.config)
        }catch{
            debugPrint(error.localizedDescription)
            return
        }
        OpenVPNConnectionManager.cfg = OpenVPN.ProviderConfiguration.init(self.name, appGroup: appGroup, configuration: builder.configuration)
        OpenVPNConnectionManager.cfg?.username = self.user
        OpenVPNConnectionManager.cfg?.shouldDebug = true
        let passwordRef : Data
        do{
            passwordRef = try keychain.set(password: self.pass, for: self.user, context: tunnelIdentifier)
        }catch{
            debugPrint(error.localizedDescription)
            return
        }
        
        
        guard let cfg = OpenVPNConnectionManager.cfg else {return}
        
        Task{
            var extra = NetworkExtensionExtra()
            extra.passwordReference = passwordRef
            try await OpenVPNConnectionManager.vpn.reconnect(tunnelIdentifier, configuration:cfg ,extra: extra, after: .seconds(2))
        }
    }
    
}
