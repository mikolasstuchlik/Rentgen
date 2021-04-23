/// Closure box is a wrapper representing and retaining any non-throwing closure. Closure itself in inaccesible.
/// Ivoke the closure by calling `invoke(with:)` function.
public final class ClosureBox<Arguments, Return> {
    public typealias Closure = (Arguments)->Return

    /// The closure
    private let closure: Closure

    public init(_ closure: @escaping Closure) {
        self.closure = closure
    }

    /// Invokes the included closure
    /// - Parameter arguments: Argument (or tuple containing arguments) required by the closure
    /// - Returns: Value returned by the closure
    ///
    /// It may not be immediately obvious why we can use this proxy function to execute the closure.
    /// This is due to fecautre called Implicit Tuple Splat. Splatting was removed from Swift but it was kept for
    /// applying tuples on functions as a convenience.
    /// https://forums.swift.org/t/is-implicit-tuple-splat-behavior-not-fully-removed/43129
    public func invoke(with arguments: Arguments) -> Return {
        closure(arguments)
    }
}
