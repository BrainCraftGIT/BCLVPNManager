//
//  BCLVPNNotification.swift
//  BCLVPNManager
//
//  Created by BCL16 on 30/1/25.
//

import Foundation
import NetworkExtension
import SwiftyBeaver

private let log = SwiftyBeaver.self

public class BCLVPNNotification {
    public static let shared = BCLVPNNotification()
    public static let statusDidChangeNotification = Notification.Name("VPNStatusDidChange")
    
    private init() {
        
    }
    
    public func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(vpnStatusDidChange(_:)), name: .NEVPNStatusDidChange, object: nil)
    }
    
    @objc private func vpnStatusDidChange(_ notification: Notification) {
        guard let connection = notification.object as? NETunnelProviderSession else {
            guard let connection = notification.object as? NEVPNConnection else {
                return
            }
            
            notifyStatus(connection)
            return
        }
        notifyStatus(connection)
    }
    
    private func notifyStatus(_ connection: NEVPNConnection) {
        guard let _ = connection.manager.localizedDescription else {
            log.verbose("Ignoring VPN notification from bogus manager")
            return
        }
        
        log.debug("VPN status did change: isEnabled=\(connection.manager.isEnabled), status=\(connection.status.rawValue)")
        var notification = Notification(name: BCLVPNNotification.statusDidChangeNotification)
        notification.vpnIsEnabled = connection.manager.isEnabled
        notification.vpnStatus = connection.status.wrappedStatus
        notification.connectionDate = connection.connectedDate
        NotificationCenter.default.post(notification)
    }
    
    private func notifyStatus(_ connection: NETunnelProviderSession) {
        guard let _ = connection.manager.localizedDescription else {
            log.verbose("Ignoring VPN notification from bogus manager")
            return
        }
        
        let protocolConfig = connection.manager.protocolConfiguration as? NETunnelProviderProtocol
        guard let bundleId = protocolConfig?.providerBundleIdentifier else {
            return
        }
        log.debug("VPN status did change (\(bundleId)): isEnabled=\(connection.manager.isEnabled), status=\(connection.status.rawValue)")
        var notification = Notification(name: BCLVPNNotification.statusDidChangeNotification)
        notification.vpnBundleIdentifier = bundleId
        notification.vpnIsEnabled = connection.manager.isEnabled
        notification.vpnStatus = connection.status.wrappedStatus
        notification.connectionDate = connection.connectedDate
        NotificationCenter.default.post(notification)
    }
}

extension NEVPNStatus {
    var wrappedStatus: VPNStatus {
        switch self {
        case .connected:
            return .connected

        case .connecting, .reasserting:
            return .connecting

        case .disconnecting:
            return .disconnecting

        case .disconnected, .invalid:
            return .disconnected

        @unknown default:
            return .disconnected
        }
    }
}
