import XCTest
@testable import Rentgen

class Cls { }

final class RentgenTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.

        let cls1 = Cls()
        let cls2 = Cls()

        ObjectHook.addHook(
            for: cls1,
            onRetain: { strong, weak, unowned in
                print("Did retain Strong(\(strong), Weak\(weak), Unowned\(unowned)")
            },
            beforeRelease: { strong, weak, unowned in
                print("Will release Strong(\(strong), Weak\(weak), Unowned\(unowned)")
            }
        )

        let arr = [cls1, cls2]
        let cp = cls1
        weak var kks = cls1;
        let cp3 = cls1
        let cp2 = cls2
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
