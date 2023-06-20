//
//  HostnameFormat.swift
//  
//
//  Created by Kit Transue on 2023-04-28.
//  Copyright © 2023 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct HostnameFormat: ParseableFormatStyle {
    typealias FormatInput = String?
    typealias FormatOutput = String
    
    struct Strategy: ParseStrategy {
        func parse(_ value: String) throws -> String? {
            guard value.count > 0 else {return nil}
            
            if let match = value.matches(of: #/(\S*)/#).first {  // FIXME: better non-space characters
                return String(match.1)
            }
            return nil
        }
    }
    var parseStrategy = Strategy()

    func format(_ value: String?) -> String {
        guard let value else {
            return ""
        }
        return value
    }
}
