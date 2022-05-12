//===--- ArithmeticTests.swift --------------------------------*- swift -*-===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

@testable import BigIntModule
import XCTest

class ArithmeticTests: XCTestCase {
    
    func testAddition<Base: FixedWidthInteger & UnsignedInteger>(base: Base.Type = Base.self) {
        let result = BigInt<Base>(0) + BigInt<Base>(1)
        XCTAssertEqual(result._limbs, [1])
    }
    
    func testAddition() {
        testAddition(base: UInt8.self)
    }
}
