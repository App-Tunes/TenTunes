//
//  TestEnumerations.swift
//  Tests
//
//  Created by Lukas Tenbrink on 02.05.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import XCTest

@testable import TenTunes

class TestEnumerations: XCTestCase {
    enum Labeled {
        case a(aval: Any)
        case b(bval: Any)
    }
    
    enum Crossing {
        case a(aval: Any)
        case b(bval: Any)
    }

    enum Unlabeled {
        case a(_ aval: Any)
        case b(_ bval: Any)
    }
    
    func testAssociatedValues() {
        let va = "A", vb = "B"
        
        let a = Labeled.a(aval: va)
        let b = Labeled.b(bval: vb)
        
        XCTAssertEqual(va, Enumerations.associatedValue(of: a, as: Labeled.a))
        XCTAssertEqual(vb, Enumerations.associatedValue(of: b, as: Labeled.b))

        
        let ca = Crossing.a(aval: va)
        let cb = Crossing.b(bval: vb)
        
        XCTAssertEqual(va, Enumerations.associatedValue(of: ca, as: Crossing.a))
        XCTAssertEqual(vb, Enumerations.associatedValue(of: cb, as: Crossing.b))

        
        let ua = Unlabeled.a(va)
        let ub = Unlabeled.b(vb)
        
        XCTAssertEqual(va, Enumerations.associatedValue(of: ua, as: Unlabeled.a))
        XCTAssertEqual(vb, Enumerations.associatedValue(of: ub, as: Unlabeled.b))
    }

    func testCaseLet() {
        let impure: [Labeled] = [
            .a(aval: "A"), .a(aval: "B"), .b(bval: "D"), .a(aval: "C")
        ]
        let pure: [Labeled] = [
            .a(aval: "A"), .a(aval: "B"), .a(aval: "C")
        ]

        XCTAssertEqual(["A", "B", "C"], impure.caseLet(Labeled.a))
        XCTAssertEqual(["A", "B", "C"], pure.caseLet(Labeled.a))

        let impureResult: [String]? = impure.caseAs(Labeled.a)
        XCTAssertEqual(nil, impureResult)
        XCTAssertEqual(["A", "B", "C"], pure.caseAs(Labeled.a))
    }
}
