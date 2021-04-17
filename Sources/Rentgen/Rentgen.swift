import SwiftCRuntime

private final class ClosureBox<T, U> {
    private let closure: (T)->U
    init (closure: @escaping (T)->U) { self.closure = closure }
    func invoke(arg: T) -> U { closure(arg) }
}

public enum ObjectHook {
    @discardableResult
    public static func addHook<T: AnyObject>(
        for instance: T,
        onRetain: @escaping (_ strong: Int, _ weak: Int, _ unowned: Int)->(),
        beforeRelease: @escaping (_ strong: Int, _ weak: Int, _ unowned: Int)->()
    ) -> Bool {
        typealias Callback = ClosureBox<(Int, Int, Int), Void>

        let opaque = Unmanaged.passUnretained(instance).toOpaque()

        let retainBox: Callback = ClosureBox(closure: onRetain)
        let releaseBox: Callback = ClosureBox(closure: beforeRelease)

        let opaqueRetain = Unmanaged.passRetained(retainBox).toOpaque()
        let opaqueRelease = Unmanaged.passRetained(releaseBox).toOpaque()

        let executor: @convention(c) (Int, Int, Int, UnsafeMutableRawPointer?) -> Void = { arg1, arg2, arg3, data in
            guard let data = data else { return }
            Unmanaged<Callback>.fromOpaque(data).takeUnretainedValue().invoke(arg: (arg1, arg2, arg3))
        }

        let destroyer: @convention(c) (UnsafeMutableRawPointer?) -> Void = { data in
            guard let data = data else { return }
            Unmanaged<Callback>.fromOpaque(data).release()
        }

        return add_arc_observer_for(
            opaque,
            executor,
            opaqueRetain,
            destroyer,
            executor,
            opaqueRelease,
            destroyer
        )
        
    }

    @discardableResult
    public static func removeHook<T: AnyObject>(for instance: T) -> Bool {
        let opaque = Unmanaged.passUnretained(instance).toOpaque()
        return remove_arc_observer_for(opaque)
    }
}
