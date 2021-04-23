/// Utility used to rebound closure and extract it's internal variables
public struct AnyNonThrowing<Argument, Return> {
    /// Raw expression of structure
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

    /// The closure
    public let closure: (Argument)->Return

    /// Rebounds the closure to raw representation for the duration of the scope
    /// - Parameter validityScope: Block, in which the `reboundSelf` is valud
    /// - Parameter reboundSelf: Structure, allowing raw access to data of closure variable
    public func reboundToRaw(_ validityScope: (_ reboundSelf: RawClosureRebound)->()) {
        validityScope(unsafeBitCast(self.closure, to: RawClosureRebound.self))
    }
}
