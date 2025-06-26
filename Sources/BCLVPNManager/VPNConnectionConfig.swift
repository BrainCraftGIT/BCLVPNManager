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
    let allowedIPs: String
    let dns: String
    
    public init(name: String,
                tunnelIdentifier: String,
                appGroup: String,
                clientPrivateKey: String,
                clientAddress: String,
                serverPublicKey: String,
                serverAddress: String,
                serverPort: String,
                allowedIPs: String,
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
        self.allowedIPs = allowedIPs
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

struct IKEv2CodableConfig: Codable {
    let name: String
    let remoteIdentifier: String
    let serverIp: String
    let username: String?
    let password: String?
    let sharedSecretReference: Data?

    init(from config: IKEv2ConnectionConfig) {
        self.name = config.name
        self.remoteIdentifier = config.remoteIdentifier
        self.serverIp = config.serverIp
        self.username = config.username
        self.password = config.password
        self.sharedSecretReference = config.sharedSecretReference
    }

    func toOriginal() -> IKEv2ConnectionConfig {
        return IKEv2ConnectionConfig(
            name: name,
            remoteIdentifier: remoteIdentifier,
            serverIp: serverIp,
            username: username,
            password: password,
            sharedSecretReference: sharedSecretReference
        )
    }
}


struct WireGuardCodableConfig: Codable {
    let name: String
    let tunnelIdentifier: String
    let appGroup: String
    let clientPrivateKey: String
    let clientAddress: String
    let serverPublicKey: String
    let serverAddress: String
    let serverPort: String
    let allowedIPs: String
    let dns: String

    init(from config: WireGuardConnectionConfig) {
        self.name = config.name
        self.tunnelIdentifier = config.tunnelIdentifier
        self.appGroup = config.appGroup
        self.clientPrivateKey = config.clientPrivateKey
        self.clientAddress = config.clientAddress
        self.serverPublicKey = config.serverPublicKey
        self.serverAddress = config.serverAddress
        self.serverPort = config.serverPort
        self.allowedIPs = config.allowedIPs
        self.dns = config.dns
    }

    func toOriginal() -> WireGuardConnectionConfig {
        return WireGuardConnectionConfig(
            name: name,
            tunnelIdentifier: tunnelIdentifier,
            appGroup: appGroup,
            clientPrivateKey: clientPrivateKey,
            clientAddress: clientAddress,
            serverPublicKey: serverPublicKey,
            serverAddress: serverAddress,
            serverPort: serverPort,
            allowedIPs: allowedIPs,
            dns: dns
        )
    }
}

struct OpenVPNCodableConfig: Codable {
    let name: String
    let username: String
    let password: String
    let appGroup: String
    let tunnelIdentifier: String
    let config: String

    init(from config: OpenVPNConnectionConfig) {
        self.name = config.name
        self.username = config.username
        self.password = config.password
        self.appGroup = config.appGroup
        self.tunnelIdentifier = config.tunnelIdentifier
        self.config = config.config
    }

    func toOriginal() -> OpenVPNConnectionConfig {
        return OpenVPNConnectionConfig(
            name: name,
            username: username,
            password: password,
            appGroup: appGroup,
            tunnelIdentifier: tunnelIdentifier,
            config: config
        )
    }
}

extension Encodable {
    func toJSONString(pretty: Bool = false) -> String? {
        let encoder = JSONEncoder()
        if pretty { encoder.outputFormatting = .prettyPrinted }
        guard let data = try? encoder.encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

extension Decodable {
    static func fromJSONString(_ jsonString: String) -> Self? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(Self.self, from: data)
    }
}
