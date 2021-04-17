import Foundation

final class ClosureBox<T, U> {
    private let closure: (T)->U
    init (closure: @escaping (T)->U) { self.closure = closure }
    func invoke(arg: T) -> U { closure(arg) }
}
