//
//  RSAUtil.swift
//  VPN
//
//  Created by BCL16 on 19/1/25.
//

import Foundation

public class CRSA: NSObject {
    public enum KeyType: Int {
        case publicKey = 0
        case privateKey = 1
    }
    
    public func decrypt(encryptedMessage: String, withKeyType keyType: KeyType) -> String {
        guard
            let encryptedData = Data(base64Encoded: encryptedMessage),
            encryptedData.count != 0
        else {
            print("can't get data from base 64 encoded message")
            return ""
        }
        var key = publicKey
        if (keyType == .privateKey) {
            key = privateKey
        }
        
        guard let decryptedData = decryptWithKey(data: encryptedData, key: key!) else {
            print("can't decrypt data")
            return ""
        }
        let decryptedMessage = String(data: decryptedData, encoding: .utf8)
        return decryptedMessage!
    }
    
    public func encrypt(message: String, withKeyType keyType: KeyType) -> String {
        let messageData = Data(base64Encoded: message)
        var key = publicKey
        if (keyType == .privateKey) {
            key = privateKey
        }
        
        let encryptedData = encryptWithKey(data: messageData!, key: key!)
        let encryptedMessage = String(data: encryptedData!, encoding: .utf8)
        return encryptedMessage!
    }
    
    var privateKey: SecKey?
    var publicKey: SecKey?
    
    private override init() {
        super.init()
        
        let pemString = loadPEMFile(named: "rsa_public_key")
        let publicKeyData = getKeyData(fromPEM: pemString!)
        publicKey = createPublicKey(from: publicKeyData!)
        
        let privatePemString = loadPEMFile(named: "rsa_private_key")
        let privateKeyData = getKeyData(fromPEM: privatePemString!)
        privateKey = createPrivateKey(from: privateKeyData!)
    }
    public static let shared = CRSA()
    
    func loadPEMFile(named filename: String) -> String? {
        guard let path = Bundle.main.path(forResource: filename, ofType: "pem"),
              let pemString = try? String(contentsOfFile: path) else {
            return nil
        }
        return pemString
    }
    
    func getKeyData(fromPEM pemString: String) -> Data? {
        let lines = pemString.components(separatedBy: "\n")
            .filter { !$0.hasPrefix("-----") && !$0.isEmpty }
        let base64String = lines.joined()
        return Data(base64Encoded: base64String)
    }
    
    func createPublicKey(from data: Data) -> SecKey? {
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic
        ]
        
        return SecKeyCreateWithData(data as CFData, attributes as CFDictionary, nil)
    }
    
    func createPrivateKey(from data: Data) -> SecKey? {
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate
        ]
        
        return SecKeyCreateWithData(data as CFData, attributes as CFDictionary, nil)
    }
    
    func encryptWithKey(data: Data, key: SecKey) -> Data? {
        var error: Unmanaged<CFError>?
        return SecKeyCreateEncryptedData(
            key,
            SecKeyAlgorithm.rsaEncryptionPKCS1,
            data as CFData,
            &error
        ) as Data?
    }
    
    func decryptWithKey(data: Data, key: SecKey) -> Data? {
        var error: Unmanaged<CFError>?
        return SecKeyCreateDecryptedData(
            key,
            SecKeyAlgorithm.rsaEncryptionPKCS1,
            data as CFData,
            &error
        ) as Data?
    }
}
