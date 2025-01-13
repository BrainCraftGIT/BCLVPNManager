//
//  File.swift
//  
//
//  Created by BCL16 on 13/1/25.
//

import Foundation

public protocol VPNConnectionManager {
    func connect()
    func disconnect()
    static func setup(with config: VPNConnectionConfig) -> VPNConnectionManager?
}
