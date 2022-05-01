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
        case closureContextEmpty
        case notAFunctionType
        case closureContextNotBoxed(RawClosureRebound, typeName: String?, opaqueSummary: String?)
    }
}

public struct RawClosureRebound {
    /// Function pointer (do not attempt to execute)
    public let function: UnsafeRawPointer
    /// Captured context.
    ///
    /// If no variable is captured, context is `nil`
    /// If capture context contains only one strongly captured class instance, the `capture` is in fact that
    /// instance and NOT an instance of box.
    ///
    /// If capture context contains more than one and/or weak/unowned captures of class instances and/or
    /// value type capture, the `capture` contains pointer to he *heap local* instance of a box. Such
    /// box has no associated metadata pointer.
    ///
    /// - Note: https://forums.swift.org/t/how-do-closures-work-memory-management/47512
    public let capture: UnsafeRawPointer?
}

// https://github.com/apple/swift/blob/main/docs/ABI/TypeLayout.rst
public struct RawOpaqueExistentialContainerRebound {
    public let buffer0_function: UnsafeRawPointer
    public let buffer1_capture: UnsafeRawPointer?
    public let buffer2_empty: UnsafeRawPointer?
    public let metadata_pointer: UnsafeRawPointer
}

public struct RawReabstractionThunkCaptureBoxRebound {
    public let metadata_pointer: UnsafeRawPointer
    public let arc_data: UInt64
    public let original_function: UnsafeRawPointer
    public let original_capture: UnsafeRawPointer?
}

public extension ClosureArcTool {
    var maxHooks: Int { Int(ARC_STRONG_OBSERVERS_PER_POOL) }
    var freeHooks: Int { Int(arcCountStrongHooks(at: ClosurePool)) }

    @discardableResult
    static func hookOnNonThrowing(
        for closureInBox: Any,
        onRetain: @escaping ClosureArcTool.EventHandler.Closure,
        beforeRelease: @escaping ClosureArcTool.EventHandler.Closure
    ) throws -> Bool {
        let rebound = try searchForClosure(in: closureInBox)

        guard let capture = rebound.capture else {
            throw ClosureArcTool.Error.closureContextEmpty
        }

        let isa = heap_object_to_isa_field(capture)
        let kind = swift_getMetadataKind(isa)

        // TODO: Create metadata kind enum using https://github.com/apple/swift/blob/7123d2614b5f222d03b3762cb110d27a9dd98e24/docs/ABI/TypeMetadata.rst
        guard kind == 1024 else {
            let typeName = swift_getTypeName(isa, true).flatMap(String.init(cString:))
            let opaqueSummary = swift_OpaqueSummary(isa).flatMap(String.init(cString:))
            throw ClosureArcTool.Error.closureContextNotBoxed(rebound, typeName: typeName, opaqueSummary: opaqueSummary)
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

    @discardableResult
    static func removeHook(
        for closureInBox: Any
    ) throws -> Bool {
        let rebound = try searchForClosure(in: closureInBox)

        guard let capture = rebound.capture else {
            throw ClosureArcTool.Error.closureContextEmpty
        }

        let isa = heap_object_to_isa_field(capture)
        let kind = swift_getMetadataKind(isa)

        // TODO: Create metadata kind enum using https://github.com/apple/swift/blob/7123d2614b5f222d03b3762cb110d27a9dd98e24/docs/ABI/TypeMetadata.rst
        guard kind == 1024 else {
            let typeName = swift_getTypeName(capture, true).flatMap(String.init(cString:))
            let opaqueSummary = swift_OpaqueSummary(isa).flatMap(String.init(cString:))
            throw ClosureArcTool.Error.closureContextNotBoxed(rebound, typeName: typeName, opaqueSummary: opaqueSummary)
        }

        return arcRemoveStrongObserver(
            heapObjectAddress: capture
        )
    }

    static private func searchForClosure(in box: Any) throws -> RawClosureRebound {
        let reboundAnyBox = unsafeBitCast(box, to: RawOpaqueExistentialContainerRebound.self)

        // https://github.com/apple/swift/blob/main/include/swift/ABI/MetadataKind.def
        // Check, whether the opaque existential box contains Function type
        guard swift_getMetadataKind(reboundAnyBox.metadata_pointer) == 770 else {
            throw Error.notAFunctionType
        }

        guard let assumedThunkCapture = reboundAnyBox.buffer1_capture?.assumingMemoryBound(to: RawReabstractionThunkCaptureBoxRebound.self).pointee else {
            throw Error.closureContextEmpty
        }

        // TODO: Check RawReabstractionThunkCaptureBoxRebound for validity (function pointer validity)

        return RawClosureRebound(
            function: assumedThunkCapture.original_function,
            capture: assumedThunkCapture.original_capture
        )
    }
}
