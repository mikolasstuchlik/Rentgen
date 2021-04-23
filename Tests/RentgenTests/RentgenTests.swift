import XCTest
@testable import Rentgen

final class Cls {}

final class RentgenTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.

        let cls = Cls()

        let inst2 = Cls()
        let inst3 = Cls()
        let inst4 = "Some string"
        var inst5 = 1224

        ObjectHook.addHook(
            for: cls,
            onRetain: { strong, weak, unowned in
                print("Did retain Strong(\(strong)), Weak(\(weak)), Unowned(\(unowned))")
            },
            beforeRelease: { strong, weak, unowned in
                print("Will release Strong(\(strong)), Weak(\(weak)), Unowned(\(unowned))")
            }
        )

        let clos = { cls }
        let clos2 = clos
        let clos3 = clos2

        let clos21 = {
            var abc = inst2
            abc = inst3
            _ = inst4
            inst5 += 1
        }

        AnyNonThrowing(closure: clos3).reboundToRaw { raw in
            _ = raw
        }

        AnyNonThrowing(closure: clos21).reboundToRaw { raw in
            _ = raw
        }

        
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
