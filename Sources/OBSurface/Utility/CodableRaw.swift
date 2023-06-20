//
//  CodableRaw.swift
//  
//
//  Created by Kit Transue on 2023-05-07.
//  Copyright © 2023 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//



import Foundation

// This solves a familiar problem:
// https://forums.swift.org/t/rawrepresentable-conformance-leads-to-crash/51912
// without requiring explicit implementations of coding or requiring knowledge
// of the mechanisms of wrapping/forwarding.

/// Wrapper that leverages a struct's Codable conformance to make it RawRepresentable.
///
/// - Note: doing the conversion in an extension does not work because the RawRepresentable
///   is leveraged by the coding, and the rawValue accessor infinitely recurses. This implementation
///   provides idiomatic usage with no added boilerplate.
///
///         @AppStorage("abc") @CodableRaw var z = OBSConnectionSetting()
@propertyWrapper
struct CodableRaw<Value: Codable>: RawRepresentable {
    init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let value = try? JSONDecoder().decode(Value.self, from: data) else {return nil}
        self.wrappedValue = value
    }
    
    var rawValue: String {
        guard let data = try? JSONEncoder().encode(wrappedValue),
              let string = String(data: data, encoding: .utf8)
        else { return "{}" }
        
        return string
    }
    
    typealias RawValue = String
    var wrappedValue: Value
}

