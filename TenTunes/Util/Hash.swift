//
//  Hash.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 05.06.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class Hash {    
    static func md5(of pointer: UnsafeRawPointer, length: Int) -> Data {
        // Create and initialize MD5 context:
        var context = CC_MD5_CTX()
        CC_MD5_Init(&context)
        
        _ = CC_MD5_Update(&context, pointer, numericCast(length))

        // Compute the MD5 digest:
        var digest = Data(count: Int(CC_MD5_DIGEST_LENGTH))
        digest.withUnsafeMutableBytes {
            _ = CC_MD5_Final($0, &context)
        }
        return digest
    }
    
    static func md5(of data: Data) -> Data {
        // Create and initialize MD5 context:
        var context = CC_MD5_CTX()
        CC_MD5_Init(&context)
        
        _ =  data.withUnsafeBytes {
            _ = CC_MD5_Update(&context, $0, numericCast(data.count))
        }
        
        // Compute the MD5 digest:
        var digest = Data(count: Int(CC_MD5_DIGEST_LENGTH))
        digest.withUnsafeMutableBytes {
            _ = CC_MD5_Final($0, &context)
        }
        return digest
    }
    
    // From https://stackoverflow.com/questions/42935148/swift-calculate-md5-checksum-for-large-files
    static func md5(url: URL) -> Data? {
        
        let bufferSize = 1024 * 1024
        
        do {
            // Open file for reading:
            let file = try FileHandle(forReadingFrom: url)
            defer {
                file.closeFile()
            }
            
            // Create and initialize MD5 context:
            var context = CC_MD5_CTX()
            CC_MD5_Init(&context)
            
            // Read up to `bufferSize` bytes, until EOF is reached, and update MD5 context:
            while autoreleasepool(invoking: {
                let data = file.readData(ofLength: bufferSize)
                if data.count > 0 {
                    data.withUnsafeBytes {
                        _ = CC_MD5_Update(&context, $0, numericCast(data.count))
                    }
                    return true // Continue
                } else {
                    return false // End of file
                }
            }) { }
            
            // Compute the MD5 digest:
            var digest = Data(count: Int(CC_MD5_DIGEST_LENGTH))
            digest.withUnsafeMutableBytes {
                _ = CC_MD5_Final($0, &context)
            }
            
            return digest
            
        } catch {
            print("Cannot open file:", error.localizedDescription)
            return nil
        }
    }
}
