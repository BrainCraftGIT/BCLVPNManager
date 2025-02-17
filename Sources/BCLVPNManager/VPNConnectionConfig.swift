//
//  File.swift
//  
//
//  Created by BCL16 on 12/1/25.
//

import Foundation
import NetworkExtension

public protocol VPNConnectionConfig {
    var onDemandRules: [NEOnDemandRule] { get set }
    var name: String { get set }
}

public class IKEv2ConnectionConfig: VPNConnectionConfig {
    public var name: String
    public var onDemandRules: [NEOnDemandRule]
    
    var remoteIdentifier: String
    var serverIp: String
    var username: String?
    var password: String?
    var sharedSecretReference: Data?
    
    public init(name: String, remoteIdentifier: String, serverIp: String, username: String?, password: String?, sharedSecretReference: Data? = nil, onDemandRules: [NEOnDemandRule] = []) {
        self.name = name
        self.remoteIdentifier = remoteIdentifier
        self.serverIp = serverIp
        self.username = username
        self.password = password
        self.sharedSecretReference = sharedSecretReference
        self.onDemandRules = onDemandRules
    }
}

public class WireGuardConnectionConfig: VPNConnectionConfig {
    public var onDemandRules: [NEOnDemandRule]
    public var name: String
    
    let tunnelIdentifier: String
    let appGroup: String
    let clientPrivateKey: String
    let clientAddress: String
    let serverPublicKey: String
    let serverAddress: String
    let serverPort: String
    let dns: String
    
    public init(name: String,
                tunnelIdentifier: String,
                appGroup: String,
                clientPrivateKey: String,
                clientAddress: String,
                serverPublicKey: String,
                serverAddress: String,
                serverPort: String,
                dns: String,
                onDemandRules: [NEOnDemandRule] = []) {
        self.name = name
        self.tunnelIdentifier = tunnelIdentifier
        self.appGroup = appGroup
        self.clientPrivateKey = clientPrivateKey
        self.clientAddress = clientAddress
        self.serverPublicKey = serverPublicKey
        self.serverAddress = serverAddress
        self.serverPort = serverPort
        self.dns = dns
        self.onDemandRules = onDemandRules
    }
}

public class OpenVPNConnectionConfig: VPNConnectionConfig {
    public var onDemandRules: [NEOnDemandRule]
    public var name: String
    
    var config: String
    var appGroup: String
    var tunnelIdentifier: String
    var username: String
    var password: String
    
    public init(name: String, username: String, password: String, appGroup: String, tunnelIdentifier: String, config: String, onDemandRules: [NEOnDemandRule] = []) {
        self.name = name
        self.username = username
        self.password = password
        self.appGroup = appGroup
        self.tunnelIdentifier = tunnelIdentifier
        self.config = config
        self.onDemandRules = onDemandRules
    }
}
