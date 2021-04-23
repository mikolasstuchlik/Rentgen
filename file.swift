
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
let number = Number(number: 0)
print("===== Did init")

//ObjectHook.addHook(for: empty, onRetain: defaultHandler("empty inc"), beforeRelease: defaultHandler("empty dec"))
//ObjectHook.addHook(for: number, onRetain: defaultHandler("number inc"), beforeRelease: defaultHandler("number dec"))

print("===== Did hook")

var value: Int = 0

let closureRet1: ()->Void = { [number] in number.number += 1 }
let closureRet1_1: ()->Void = { [number] in number.number += 1; print("v: \(value)") }
let captureRet2: ()->Void = { [number, empty] in number.number += 1; empty.foo() }
let closureRet2_1: ()->Void = { [number, empty] in number.number += 1; empty.foo(); print("v: \(value)") }


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
