//===--- BigInt.swift -----------------------------------------*- swift -*-===//
//
// This source file is part of the Swift Numerics open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift Numerics project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

public struct BigInt<Base: FixedWidthInteger & UnsignedInteger> {
    var _limbs: ContiguousArray<Base>
    
    /// How many bits in each limb are reserved for storing the magnitude.
    static var magnitudeBitWidth: Int { Base.bitWidth - 2 }
    static var maxLimbMagnitude: Int { 1 &<< (magnitudeBitWidth - 1) }
    
    /// Constructs a `BigInt` from a normal `BinaryInteger`.
    public init<S: BinaryInteger>(_ value: S) {
        if value.magnitude < Self.maxLimbMagnitude {
            _limbs = [Base(value)]
        } else {
            var count: Int = 0
            var remainder = value
            while remainder.magnitude > Self.maxLimbMagnitude {
                precondition(count < Int.max, "Too many limbs required to store this value!")
                count &+= 1
                remainder -= S(Self.maxLimbMagnitude)
            }
            _limbs = .init(repeating: Base(Self.maxLimbMagnitude), count: count)
            if (remainder > 0) {
                precondition(count < Int.max, "Too many limbs required to store this value!")
                _limbs.append(Base(remainder))
            }
        }
    }
    
    /// - Returns: true if overflow, false otherwise
    private mutating func _addDigit(at i: Int, _ otherDigit: Base, carryIn: Bool) -> Bool {
        var digit = _limbs[i]
        let sum = digit.addingReportingOverflow(otherDigit)
        digit = sum.partialValue
        var carryOut = sum.overflow
        if carryIn {
            let sum = digit.addingReportingOverflow(1)
            digit = sum.partialValue
            carryOut = carryOut || sum.overflow
        }
        return carryOut
    }
    
    fileprivate mutating func _addDigits(of other: BigInt) {
        let otherLength = other._limbs.count
        guard otherLength > 0 else { return }
        
        let selfLength = _limbs.count
        guard selfLength > 0 else {
            self = other
            return
        }
        
        let commonLength = min(selfLength, otherLength)
        var i = 0
        var carry = false
        while i < commonLength {
            carry = _addDigit(at: i, other._limbs[i], carryIn: carry)
            i += 1
        }
        
        if selfLength < otherLength {
            _limbs.append(contentsOf: other._limbs[i...])
            while carry && i < otherLength {
                carry = _addDigit(at: i, other._limbs[i], carryIn: carry)
            }
        } else if selfLength > otherLength {
            while carry && i < selfLength {
                carry = _addDigit(at: i, 0, carryIn: carry)
            }
        }
        
        if carry {
            _limbs.append(1)
        }
    }
}

#if true
extension BigInt: CustomDebugStringConvertible {
    public var debugDescription: String { "BigInt<\(Base.self)>(\(_limbs.count) limbs)" }
}
#endif

extension BigInt/*: AdditiveArithmetic*/ {
    public var zero: BigInt { BigInt(0) }
    
    public static func +(lhs: BigInt, rhs: BigInt) -> BigInt {
        var value = lhs
        value += rhs
        return value
    }
    
    public static func +=(lhs: inout BigInt, rhs: BigInt) {
        lhs._addDigits(of: rhs)
    }
    
    /*
    public static func -(lhs: BigInt, rhs: BigInt) -> BigInt {
        var value = lhs
        value -= rhs
        return lhs
    }
    
    public static func -=(lhs: inout BigInt, rhs: BigInt) {
        lhs._subtractDigits(of: rhs)
    }
    
    public static func ==(lhs: BigInt, rhs: BigInt) -> Bool {
        let value = lhs - rhs
        return value._digits.contains { $0 != 0 } == false
    }
    */
}
