//
//  RationalLogScale.swift
//  
//
//  Created by Kit Transue on 2023-04-29.
//  Copyright © 2023 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Provide an Int -> Double mapping that is exponential (the Int is the log),
/// and uses ratios of small rational numbers. Useful for scaling.
struct RationalLogScale {
    // FIXME: use formatter in/out pattern?
    
    /// Roughly: 2^(value/modulus).
    public static func pow(for value: Int) -> Double {
        let (exponent, numerator, denominator) = components(for: value)
        let factor = Darwin.pow(2.0, Double(exponent))
        return factor * Double(numerator) / Double(denominator)
    }
    
    private static func components(for value: Int) -> (Int, Int, Int) {
        var (exponent, mantissa) = value.quotientAndRemainder(dividingBy: modulus)
        if mantissa < 0 {
            mantissa += Self.modulus
            exponent -= 1
        }
        let fractional = Self.ratios[mantissa]
        
        return (exponent, fractional.numerator, fractional.denominator)
    }
    
    public static let modulus = ratios.count
    
    public static func pretty(for value: Int) -> String {
        let (exponent, numerator, denominator) = components(for: value)
        let approx = String(format: "%0.2f", pow(for: value))
        return "2^\(exponent) * \(numerator)/\(denominator) (\(approx))"
    }
    
    /// Ten-detent to double
    static let ratios: [(numerator: Int, denominator: Int)] = [
        (numerator: 1, denominator: 1),
        (numerator: 14, denominator: 13),
        (numerator: 8, denominator: 7),
        (numerator: 5, denominator: 4),
        (numerator: 4, denominator: 3),
        (numerator: 7, denominator: 5),
        (numerator: 3, denominator: 2),
        (numerator: 5, denominator: 3),
        (numerator: 7, denominator: 4),
        (numerator: 15, denominator: 8),
        // (numerator: 2, denominator: 1),
    ]
}
