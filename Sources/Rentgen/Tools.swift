public struct AnyNonThrowing<Argument, Return> {
    public struct RawClosureRebound {
        public let function: UnsafeRawPointer
        public let capture: UnsafeRawPointer
    }

    public let closure: (Argument)->Return

    public func reboundToRaw(_ validityScope: (RawClosureRebound)->()) {
        withUnsafePointer(to: self) { ptr -> Void in
            ptr.withMemoryRebound(to: RawClosureRebound.self, capacity: 1) { rawPtr -> Void in
                validityScope(rawPtr.pointee)
            }
        }
    }
}
