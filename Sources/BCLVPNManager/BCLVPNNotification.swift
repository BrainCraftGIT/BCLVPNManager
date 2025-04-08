//
//  BCLVPNNotification.swift
//  BCLVPNManager
//
//  Created by BCL16 on 30/1/25.
//

import Foundation
import NetworkExtension
import SwiftyBeaver
import TunnelKitManager

private let log = SwiftyBeaver.self

public class BCLVPNNotification {
    public static let shared = BCLVPNNotification()
    public static let statusDidChangeNotification = Notification.Name("VPNStatusDidChange")
    public static let didFailNotification = Notification.Name("VPNDidFail")
    
    private init() {
        
    }
    
    public func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(vpnStatusDidChange(_:)), name: .NEVPNStatusDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(vpnDidFailed(_:)), name: VPNNotification.didFail, object: nil)
    }
    
    @objc private func vpnDidFailed(_ notification: Notification) {
        BCLVPNNotification.postDidFailNotification(with: notification.vpnError!)
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
        //NotificationCenter.default.post(notification)
    }
    
    private func notifyStatus(_ connection: NEVPNConnection) {
        guard let _ = connection.manager.localizedDescription else {
            log.verbose("Ignoring VPN notification from invalid manager")
            return
        }
        
        log.debug("VPN status did change: isEnabled=\(connection.manager.isEnabled), status=\(connection.status.rawValue)")
        var notification = Notification(name: BCLVPNNotification.statusDidChangeNotification)
        notification.vpnStatus = connection.status.wrappedStatus
        notification.localizedDescription = connection.manager.localizedDescription!
        notification.serverIp = connection.manager.protocolConfiguration!.serverAddress!
        notification.vpnIsEnabled = connection.manager.isEnabled
        
        if currentVPNRequest == .disconnect && notification.vpnStatus == .connected {
            log.verbose("current request is disconnect and vpn status is connected, ignore this notification")
            return
        }
        
        print("Posted notification: \(notification)")
        NotificationCenter.default.post(notification)
    }
    
    private func notifyStatus(_ connection: NETunnelProviderSession) {
        guard let _ = connection.manager.localizedDescription else {
            log.verbose("Ignoring VPN notification from invalid manager")
            return
        }
        
        let protocolConfig = connection.manager.protocolConfiguration as? NETunnelProviderProtocol
        guard let bundleId = protocolConfig?.providerBundleIdentifier else {
            return
        }
        log.debug("VPN status did change (\(bundleId)): isEnabled=\(connection.manager.isEnabled), status=\(connection.status.rawValue)")
        var notification = Notification(name: BCLVPNNotification.statusDidChangeNotification)
        notification.vpnBundleIdentifier = bundleId
        notification.vpnStatus = connection.status.wrappedStatus
        notification.localizedDescription = connection.manager.localizedDescription!
        notification.serverIp = protocolConfig!.serverAddress!
        notification.vpnIsEnabled = connection.manager.isEnabled
        
        if currentVPNRequest == .disconnect && notification.vpnStatus == .connected {
            log.verbose("current request is disconnect and vpn status is connected, ignore this notification")
            return
        }
        
        print("Posted notification: \(notification)")
        NotificationCenter.default.post(notification)
    }
    
    static public func postDidFailNotification(with error: Error) {
        var notification = Notification(name: didFailNotification)
        notification.vpnDidFailError = error
        NotificationCenter.default.post(notification)
    }
}

extension Notification {
    public var vpnDidFailError: Error? {
        get {
            guard let vpnDidFailError = userInfo?["vpnDidFailError"] as? Error else {
                print("Notification has no vpnDidFailError")
                return nil
            }
            return vpnDidFailError
        }
        set {
            var newInfo = userInfo ?? [:]
            newInfo["vpnDidFailError"] = newValue
            userInfo = newInfo
        }
    }
    
    public var vpnBundleIdentifier: String? {
        get {
            guard let vpnBundleIdentifier = userInfo?["BundleIdentifier"] as? String else {
                fatalError("Notification has no vpnBundleIdentifier")
            }
            return vpnBundleIdentifier
        }
        set {
            var newInfo = userInfo ?? [:]
            newInfo["BundleIdentifier"] = newValue
            userInfo = newInfo
        }
    }
    
    public var vpnStatus: VPNStatus {
        get {
            guard let vpnStatus = userInfo?["Status"] as? VPNStatus else {
                fatalError("Notification has no vpnStatus")
            }
            return vpnStatus
        }
        set {
            var newInfo = userInfo ?? [:]
            newInfo["Status"] = newValue
            userInfo = newInfo
        }
    }
    
    public var localizedDescription: String {
        get {
            guard let localizedDescription = userInfo?["localizedDescription"] as? String else {
                fatalError("Notification has no localizedDescription")
            }
            return localizedDescription
        }
        set {
            var newInfo = userInfo ?? [:]
            newInfo["localizedDescription"] = newValue
            userInfo = newInfo
        }
    }
    
    public var serverIp: String {
        get {
            guard let serverIp = userInfo?["ServerIp"] as? String else {
                fatalError("Notification has no serverIp")
            }
            return serverIp
        }
        set {
            var newInfo = userInfo ?? [:]
            newInfo["ServerIp"] = newValue
            userInfo = newInfo
        }
    }
    
    public var vpnIsEnabled: Bool {
        get {
            guard let vpnIsEnabled = userInfo?["IsEnabled"] as? Bool else {
                fatalError("Notification has no vpnIsEnabled")
            }
            return vpnIsEnabled
        }
        set {
            var newInfo = userInfo ?? [:]
            newInfo["IsEnabled"] = newValue
            userInfo = newInfo
        }
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
