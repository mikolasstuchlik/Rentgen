import Rentgen

final class Empty { func foo() { } }
final class Number {
    var number: Int
    init (number: Int) { self.number = number }
}
final class Closure {
    var closure: (()->Void)
    init (_ block: @escaping ()->Void) { closure = block }
}


let defaultHandler: (String)->(Int, Int, Int)->Void = { name in
    return { strong, weak, unowned in
        print("Name: \(name); Strong: (\(strong)); Weak: (\(weak)); Unowned(\(unowned))")
    }
}

let empty = Empty()
let classInstance = Number(number: 0)
print("===== Did init")

ObjectHook.addHook(for: empty, onRetain: defaultHandler("empty inc"), beforeRelease: defaultHandler("empty dec"))
ObjectHook.addHook(for: classInstance, onRetain: defaultHandler("number inc"), beforeRelease: defaultHandler("number dec"))

print("===== Did hook")


func getClosures() -> (
    ()->Void,
    ()->Void,
    ()->Void,
    ()->Void
) {
    var value: Int = 0
    var value2: Int = 0

    let closureRet1: ()->Void = { [classInstance] in classInstance.number += 1 }
    let closureRet1_1: ()->Void = { [classInstance] in classInstance.number += 1; value += 1; print("v: \(value)") }
    let captureRet2: ()->Void = { [classInstance, empty] in classInstance.number += 1; empty.foo() }
    let closureRet2_1: ()->Void = { [classInstance, empty] in classInstance.number += 1; empty.foo(); print("v: \(value)") }
    return (closureRet1, closureRet1_1, captureRet2, closureRet2_1)
}

var value: Int = 0

let closureRet1: ()->Void = { [unowned classInstance] in classInstance.number += 1 }
let closureRet1_1: ()->Void = { [classInstance] in classInstance.number += 1; value += 1; print("v: \(value)") }
let captureRet2: ()->Void = { [classInstance, empty] in classInstance.number += 1; empty.foo() }
let closureRet2_1: ()->Void = { [classInstance, empty] in classInstance.number += 1; empty.foo(); print("v: \(value)") }

let (c_closureRet1, c_closureRet1_1, c_captureRet2, c_closureRet2_1) = getClosures()

print("===== Did init closures")

var storage: [Closure] = [Closure]()
storage.reserveCapacity(100)

print("===== Did init array")


var run = true
while run {
    print("===== Ask")
    let line = readLine()

    switch line {
    case "push1":
        storage.append(Closure(closureRet1))
    case "push1_1":
        storage.append(Closure(closureRet1_1))
    case "push2":
        storage.append(Closure(captureRet2))
    case "push2_1":
        storage.append(Closure(closureRet2_1))
    case "c_push1":
        storage.append(Closure(c_closureRet1))
    case "c_push1_1":
        storage.append(Closure(c_closureRet1_1))
    case "c_push2":
        storage.append(Closure(c_captureRet2))
    case "c_push2_1":
        storage.append(Closure(c_closureRet2_1))
    case "pop" where !storage.isEmpty:
        storage.removeLast()
    case "inc":
        value += 1
    case "exec":
        storage.last?.closure()
    case "exit":
        run = false
    default:
        print("Mé možnosti jsou omezené, zeptej se jinak")
    }

}
print("===== will end")
/*
 I would like to summarize what I learned so far.

 Any Swift closure is two pointers wide type which represents two pointer. The first pointer is the function pointer to the function body, the second is pointer to the context. The closure can be bitwise casted to:
 ```swift
 struct RawClosureRebound {
   let function: UnsafeRawPointer
   let context: UnsafeRawPointer
 }
 ```

 The contents of the closure variable and it's behaviour then can be determined based on the following criteria: *The function pointer is always a pointer to an existing function.*

 The closure is **escaping** and **does not capture** any value nor class instance)
 > The context pointer is nil. Nevertheless, `swift_retain` and `swift_release` is performed on the `context` before and after each call.

 The closure is **escaping** and **captures exactly **)
 > The context pointer is nil. Nevertheless, `swift_retain` and `swift_release` is performed on the `context` before and after each call.

 Closure is **non-escaping**)
 > The context pointer is not initialized.



 */
