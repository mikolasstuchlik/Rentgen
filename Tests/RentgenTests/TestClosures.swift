import XCTest
@testable import Rentgen

final class FooClass { init() {} }
final class AnotherClass { init() {} }

final class ClosureAcceptingClass {
    let closure: () -> Void
    init(closure: @escaping () -> Void) { self.closure = closure }
}
final class AnyBoxClass {
    let anyInstance: Any
    init(anyInstance: Any) { self.anyInstance = anyInstance }
}

final class TestClosures: XCTestCase {

    // This test checks, whether hooking works or not.
    func testStrongRetain() throws {
        let myClosure: () -> Void = { [foo1 = FooClass(), foo2 = AnotherClass()] in
            print("hello \(foo1) \(foo2)")
        }
        var currentStrong = 0

        try Rentgen.ClosureArcTool.hookOnNonThrowing(for: myClosure) { (strongRefs, unownedRefs, weakRefs) in
            print("Did retain. Strong: \(strongRefs), unowned: \(unownedRefs), weak: \(weakRefs).")
            currentStrong = strongRefs
        }
        beforeRelease: { (strongRefs, unownedRefs, weakRefs) in
            print("will release. Strong: \(strongRefs), unowned: \(unownedRefs), weak: \(weakRefs)")
            currentStrong = strongRefs - 1
        }

        XCTAssertEqual(currentStrong, 1)

        let something: Any = myClosure
        _ = something

        XCTAssertEqual(currentStrong, 2)

        let cls1 = ClosureAcceptingClass(closure: myClosure)
        _ = cls1

        XCTAssertEqual(currentStrong, 3)

        let cls2 = AnyBoxClass(anyInstance: myClosure)
        _ = cls2

        XCTAssertEqual(currentStrong, 4)
    }

    // This test checks, whether hooking fails if only class is stored in capture list.
    func testHookWithOptimizationWillFail() throws {
        let optimizedCapture: () -> Void = { [foo1 = FooClass()] in
            print("hello \(foo1)")
        }

        do {
            try Rentgen.ClosureArcTool.hookOnNonThrowing(for: optimizedCapture, onRetain: { _ in }, beforeRelease: { _ in })
            XCTFail("Should throw error")
        } catch {
            guard case ClosureArcTool.Error.closureContextNotBoxed(_, "RentgenTests.FooClass", _) = error else {
                XCTFail("Threw incorrect exception")
                return
            }
            return
        }
    }

    // This test checks, whether hooking fails no capture list is associated.
    func testHookWithoutCapture() throws {
        let optimizedCapture: () -> Void = {
            print("hello")
        }

        do {
            try Rentgen.ClosureArcTool.hookOnNonThrowing(for: optimizedCapture, onRetain: { _ in }, beforeRelease: { _ in })
            XCTFail("Should throw error")
        } catch {
            guard case ClosureArcTool.Error.closureContextEmpty = error else {
                XCTFail("Threw incorrect exception")
                return
            }
            return
        }
    }
}
