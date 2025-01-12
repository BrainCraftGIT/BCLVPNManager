//
//  File.swift
//  
//
//  Created by BCL16 on 12/1/25.
//

import Foundation

enum VPNConnectionType: Int {
    case ikev2
    case wireguard
    case openVpn
}

class BCVPNConnectionConfig {
    var name: String
    var remoteIdentifier: String?
    var serverIp: String?
    var username: String?
    var passwordReference: Data?
    var sharedSecretReference: Data?
    
    var config: String?
    var tunnelIdentifier: String?
    var appGroup: String?
    var password: String?
    
    var wg_privateKey: String?
    var wg_addresses: String?
    var wg_dns: String?
    var wg_publicKey: String?
    var wg_allowedIPs: String?
    var wg_endPoint: String?
    var wg_port: String?

    init(name: String, remoteIdentifier: String, serverIp: String, username: String? = nil, passwordReference: Data? = nil, sharedSecretReference: Data? = nil) {
        self.name = name
        self.remoteIdentifier = remoteIdentifier
        self.serverIp = serverIp
        self.username = username
        self.passwordReference = passwordReference
        self.sharedSecretReference = sharedSecretReference
    }
    
    init(name: String, wg_privateKey: String, wg_addresses: String, wg_dns: String, wg_publicKey: String, wg_allowedIPs: String, wg_endPoint: String, wg_port: String) {
        self.name = name
        self.wg_privateKey = wg_privateKey
        self.wg_addresses = wg_addresses
        self.wg_dns = wg_dns
        self.wg_publicKey = wg_publicKey
        self.wg_allowedIPs = wg_allowedIPs
        self.wg_endPoint = wg_endPoint
        self.wg_port = wg_port
    }
    
    init(name: String, username: String? = nil, password: String? = nil, appGroup: String? = nil, tunnelIdentifier: String? = nil, config: String? = nil) {
        self.name = name
        self.username = username
        self.password = password
        self.appGroup = appGroup
        self.tunnelIdentifier = tunnelIdentifier
        self.config = config
    }
}
