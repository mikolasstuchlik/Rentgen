import SwiftCRuntime

public enum ClosureArcTool {
    public typealias EventHandler = ClosureBox<(Int,Int,Int), Void>

    private static let executor: @convention(c) (Int, Int, Int, UnsafeMutableRawPointer?) -> Void = { arg1, arg2, arg3, data in
        guard let data = data else { return }
        Unmanaged<EventHandler>.fromOpaque(data).takeUnretainedValue().invoke(with: (arg1, arg2, arg3))
    }

    private static let destroyer: @convention(c) (UnsafeMutableRawPointer?) -> Void = { data in
        guard let data = data else { return }
        Unmanaged<EventHandler>.fromOpaque(data).release()
    }

    public enum Error: Swift.Error {
        case closureContextEmpty, closureContextNotBoxed(UnsafeRawPointer, typeName: String?, opaqueSummary: String?)
    }
}

public extension ClosureArcTool {
    var maxHooks: Int { Int(ARC_STRONG_OBSERVERS_PER_POOL) }
    var freeHooks: Int { Int(arcCountStrongHooks(at: ClosurePool)) }

    @discardableResult
    static func hookOnNonThrowing<Arguments, Return>(
        for closure: @escaping (Arguments)->Return,
        onRetain: @escaping ClosureArcTool.EventHandler.Closure,
        beforeRelease: @escaping ClosureArcTool.EventHandler.Closure
    ) throws -> Bool {
        try AnyNonThrowing(closure: closure).reboundToRaw { rebound in
            guard let capture = rebound.capture else {
                throw ClosureArcTool.Error.closureContextEmpty
            }

            let isa = heap_object_to_isa_field(capture)
            let kind = swift_getMetadataKind(isa)

            // TODO: Create metadata kind enum using https://github.com/apple/swift/blob/7123d2614b5f222d03b3762cb110d27a9dd98e24/docs/ABI/TypeMetadata.rst
            guard kind == 1024 else {
                let typeName = swift_getTypeName(capture, true).flatMap(String.init(cString:))
                let opaqueSummary = swift_OpaqueSummary(isa).flatMap(String.init(cString:))
                throw ClosureArcTool.Error.closureContextNotBoxed(capture, typeName: typeName, opaqueSummary: opaqueSummary)
            }

            return arcAddStrongObserver(
                heapObjectAddress: capture,
                at: ClosurePool,
                didIncrementCallback: ClosureArcTool.executor,
                didIncrementUserData: Unmanaged.passRetained(ClosureBox(onRetain)).toOpaque(),
                destroyDidIncrementUserDataCallback: ClosureArcTool.destroyer,
                willDecrementCallback: ClosureArcTool.executor,
                willDecrementUserData: Unmanaged.passRetained(ClosureBox(beforeRelease)).toOpaque(),
                destroyWillDecrementUserDataCallback: ClosureArcTool.destroyer
            )
        }
    }

    @discardableResult
    static func removeHook<Arguments, Return>(
        for closure: @escaping (Arguments)->Return
    ) throws -> Bool {
        try AnyNonThrowing(closure: closure).reboundToRaw { rebound in
            guard let capture = rebound.capture else {
                throw ClosureArcTool.Error.closureContextEmpty
            }

            let isa = heap_object_to_isa_field(capture)
            let kind = swift_getMetadataKind(isa)

            // TODO: Create metadata kind enum using https://github.com/apple/swift/blob/7123d2614b5f222d03b3762cb110d27a9dd98e24/docs/ABI/TypeMetadata.rst
            guard kind == 1024 else {
                let typeName = swift_getTypeName(capture, true).flatMap(String.init(cString:))
                let opaqueSummary = swift_OpaqueSummary(isa).flatMap(String.init(cString:))
                throw ClosureArcTool.Error.closureContextNotBoxed(capture, typeName: typeName, opaqueSummary: opaqueSummary)
            }

            return arcRemoveStrongObserver(
                heapObjectAddress: capture
            )
        }
    }
}
