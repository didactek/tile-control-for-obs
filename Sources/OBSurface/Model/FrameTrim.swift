//
//  TrameTrim.swift
//  
//
//  Created by Kit Transue on 2023-05-17.
//  Copyright © 2023 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct FrameTrim: Codable, Equatable, Hashable {
    var yOffset: Int
    
    init(yOffset: Int) {
        self.yOffset = yOffset
    }
    
    var wellKnown: FrameOffset {
        get {
            FrameOffset(rawValue: yOffset) ?? .custom
        }
        set {
            if case .custom = newValue {
            } else {
                yOffset = newValue.rawValue
            }
        }
    }
}

enum FrameOffset: Int, RawRepresentable, CaseIterable, Identifiable {
    var id: Int {rawValue}
    
    case custom = -1
    case none = 0
    case compact = 50
    case xQuartz = 96
    case toolFrame = 150
    case toolTabFrame = 200
    
    func description() -> String {
        switch self {
        case .custom:
            return "Custom"
        case .none:
            return "None"
        case .compact:
            return "Compact Frame"
        case .xQuartz:
            return "XQuartz window chrome"
        case .toolFrame:
            return "Tool frame (common)"
        case .toolTabFrame:
            return "Tool frame with tabs"
        }
    }
}
