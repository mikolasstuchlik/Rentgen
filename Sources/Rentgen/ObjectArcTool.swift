import SwiftCRuntime

public enum ObjectArcTool {
    public typealias EventHandler = ClosureBox<(Int,Int,Int), Void>

    private static let executor: @convention(c) (Int, Int, Int, UnsafeMutableRawPointer?) -> Void = { arg1, arg2, arg3, data in
        guard let data = data else { return }
        Unmanaged<EventHandler>.fromOpaque(data).takeUnretainedValue().invoke(with: (arg1, arg2, arg3))
    }

    private static let destroyer: @convention(c) (UnsafeMutableRawPointer?) -> Void = { data in
        guard let data = data else { return }
        Unmanaged<EventHandler>.fromOpaque(data).release()
    }

    public enum Strong { }
}

public extension ObjectArcTool.Strong {
    var maxHooks: Int { Int(ARC_STRONG_OBSERVERS_MAX_COUNT) }
    var freeHooks: Int { Int(arcCountStrongHooks()) }

    
    @discardableResult
    static func hookOnStrongRetain<T: AnyObject>(
        for instance: T,
        onRetain: @escaping ObjectArcTool.EventHandler.Closure,
        beforeRelease: @escaping ObjectArcTool.EventHandler.Closure
    ) -> Bool {
        arcAddStrongObserver(
            heapObjectAddress: Unmanaged.passUnretained(instance).toOpaque(),
            didIncrementCallback: ObjectArcTool.executor,
            didIncrementUserData: Unmanaged.passRetained(ClosureBox(onRetain)).toOpaque(),
            destroyDidIncrementUserDataCallback: ObjectArcTool.destroyer,
            willDecrementCallback: ObjectArcTool.executor,
            willDecrementUserData: Unmanaged.passRetained(ClosureBox(beforeRelease)).toOpaque(),
            destroyWillDecrementUserDataCallback: ObjectArcTool.destroyer
        )
    }

    @discardableResult
    static func removeHook<T: AnyObject>(for instance: T) -> Bool {
        arcRemoveStrongObserver(
            heapObjectAddress: Unmanaged.passUnretained(instance).toOpaque()
        )
    }
}
