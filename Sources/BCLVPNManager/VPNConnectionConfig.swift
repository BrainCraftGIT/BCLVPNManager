//
//  File.swift
//  
//
//  Created by BCL16 on 12/1/25.
//

import Foundation

public protocol VPNConnectionConfig {
    
}

public class IKEv2ConnectionConfig: VPNConnectionConfig {
    var name: String
    var remoteIdentifier: String
    var serverIp: String
    var username: String?
    var password: String?
    var sharedSecretReference: Data?
    
    public init(name: String, remoteIdentifier: String, serverIp: String, username: String?, password: String?, sharedSecretReference: Data? = nil) {
        self.name = name
        self.remoteIdentifier = remoteIdentifier
        self.serverIp = serverIp
        self.username = username
        self.password = password
        self.sharedSecretReference = sharedSecretReference
    }
}

public class WireGuardConnectionConfig: VPNConnectionConfig {
    let name: String
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
}

public class OpenVPNConnectionConfig: VPNConnectionConfig {
    var config: String
    var appGroup: String
    var tunnelIdentifier: String
    var username: String
    var password: String
    var name: String
    
    public init(name: String, username: String, password: String, appGroup: String, tunnelIdentifier: String, config: String) {
        self.name = name
        self.username = username
        self.password = password
        self.appGroup = appGroup
        self.tunnelIdentifier = tunnelIdentifier
        self.config = config
    }
}
