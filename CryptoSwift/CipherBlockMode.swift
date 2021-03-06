//
//  CipherBlockMode.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 27/12/14.
//  Copyright (c) 2014 Marcin Krzyzanowski. All rights reserved.
//

import Foundation

public enum CipherBlockMode {
    case Plain, CBC, CFB
    
    /**
    Process input blocks with given block cipher mode. With fallback to plain mode.
    
    :param: blocks cipher block size blocks
    :param: iv     IV
    :param: cipher single block encryption closure
    
    :returns: encrypted bytes
    */
    func encryptBlocks(blocks:[[Byte]], iv:[Byte]?, cipher:(block:[Byte]) -> [Byte]?) -> [Byte]? {
        
        // if IV is not available, fallback to plain
        var finalBlockMode:CipherBlockMode = self
        if (iv == nil) {
            finalBlockMode = .Plain
        }
        
        switch (finalBlockMode) {
        case CBC:
            return CBCMode.encryptBlocks(blocks, iv: iv, cipher: cipher)
        case CFB:
            return CFBMode.encryptBlocks(blocks, iv: iv, cipher: cipher)
        case Plain:
            return PlainMode.encryptBlocks(blocks, cipher: cipher)
        }
    }
    
    func decryptBlocks(blocks:[[Byte]], iv:[Byte]?, cipher:(block:[Byte]) -> [Byte]?) -> [Byte]? {
        // if IV is not available, fallback to plain
        var finalBlockMode:CipherBlockMode = self
        if (iv == nil) {
            finalBlockMode = .Plain
        }
        
        switch (finalBlockMode) {
        case CBC:
            return CBCMode.decryptBlocks(blocks, iv: iv, cipher: cipher)
        case CFB:
            return CFBMode.decryptBlocks(blocks, iv: iv, cipher: cipher)
        case Plain:
            return PlainMode.decryptBlocks(blocks, cipher: cipher)
        }
    }
}

/**
*  Cipher-block chaining (CBC)
*/
private struct CBCMode {
    static func encryptBlocks(blocks:[[Byte]], iv:[Byte]?, cipher:(block:[Byte]) -> [Byte]?) -> [Byte]? {
        
        if (iv == nil) {
            assertionFailure("CBC require IV")
            return nil
        }
        
        var out:[Byte]?
        var lastCiphertext:[Byte] = iv!
        for (idx,plaintext) in enumerate(blocks) {
            // for the first time ciphertext = iv
            // ciphertext = plaintext (+) ciphertext
            var xoredPlaintext:[Byte] = plaintext
            for i in 0..<plaintext.count {
                xoredPlaintext[i] = lastCiphertext[i] ^ plaintext[i]
            }
            
            // encrypt with cipher
            if let encrypted = cipher(block: xoredPlaintext) {
                lastCiphertext = encrypted
                
                if (out == nil) {
                    out = [Byte]()
                }
                
                out = out! + encrypted
            }
        }
        return out;
    }
    
    static func decryptBlocks(blocks:[[Byte]], iv:[Byte]?, cipher:(block:[Byte]) -> [Byte]?) -> [Byte]? {
        if (iv == nil) {
            assertionFailure("CBC require IV")
            return nil
        }

        var out:[Byte]?
        var lastCiphertext:[Byte] = iv!
        for (idx,ciphertext) in enumerate(blocks) {
            if let decrypted = cipher(block: ciphertext) { // decrypt
                
                var xored:[Byte] = [Byte](count: lastCiphertext.count, repeatedValue: 0)
                for i in 0..<ciphertext.count {
                    xored[i] = lastCiphertext[i] ^ decrypted[i]
                }

                if (out == nil) {
                    out = [Byte]()
                }
                out = out! + xored
            }
            lastCiphertext = ciphertext
        }
        
        return out
    }
}

/**
*  Cipher feedback (CFB)
*/
private struct CFBMode {
    static func encryptBlocks(blocks:[[Byte]], iv:[Byte]?, cipher:(block:[Byte]) -> [Byte]?) -> [Byte]? {
        
        if (iv == nil) {
            assertionFailure("CFB require IV")
            return nil
        }
        
        var out:[Byte]?
        var lastCiphertext:[Byte] = iv!
        for (idx,plaintext) in enumerate(blocks) {
            if let encrypted = cipher(block: lastCiphertext) {
                var xoredPlaintext:[Byte] = [Byte](count: plaintext.count, repeatedValue: 0)
                for i in 0..<plaintext.count {
                    xoredPlaintext[i] = plaintext[i] ^ encrypted[i]
                }
                lastCiphertext = xoredPlaintext

                
                if (out == nil) {
                    out = [Byte]()
                }
                
                out = out! + xoredPlaintext
            }
        }
        return out;
    }
    
    static func decryptBlocks(blocks:[[Byte]], iv:[Byte]?, cipher:(block:[Byte]) -> [Byte]?) -> [Byte]? {
        if (iv == nil) {
            assertionFailure("CFB require IV")
            return nil
        }
        
        var out:[Byte]?
        var lastCiphertext:[Byte] = iv!
        for (idx,ciphertext) in enumerate(blocks) {
            if let decrypted = cipher(block: lastCiphertext) {
                var xored:[Byte] = [Byte](count: ciphertext.count, repeatedValue: 0)
                for i in 0..<ciphertext.count {
                    xored[i] = ciphertext[i] ^ decrypted[i]
                }
                lastCiphertext = xored
                
                
                if (out == nil) {
                    out = [Byte]()
                }
                
                out = out! + xored
            }
        }
        return out;
    }

}


/**
*  Plain mode, don't use it. For debuging purposes only
*/
private struct PlainMode {
    static func encryptBlocks(blocks:[[Byte]], cipher:(block:[Byte]) -> [Byte]?) -> [Byte]? {
        var out:[Byte]?
        for (idx,plaintext) in enumerate(blocks) {
            if let encrypted = cipher(block: plaintext) {
                
                if (out == nil) {
                    out = [Byte]()
                }

                out = out! + encrypted
            }
        }
        return out
    }
    
    static func decryptBlocks(blocks:[[Byte]], cipher:(block:[Byte]) -> [Byte]?) -> [Byte]? {
        return encryptBlocks(blocks, cipher: cipher)
    }
}