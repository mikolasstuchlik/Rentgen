# Rentgen

Rentgen is a troubleshooting tool, that allows you to observe `release` and `retain` events on class and closure types. The hooking is allowed by "swizzeling" the Swift Runtime calls.

## Usage

All you need to do in order to use the Rentgen is adding it as dependency to your project and desired target in **Swift Package Manager**:
```swift
.package(url: "https://github.com/mikolasstuchlik/Rentgen.git", from: "0.1.0"),
```

Following example demonstrates how to hook on a closure:
```swift
    let myClosure: () -> Void = { [foo1 = FooClass(), foo2 = AnotherClass()] in
        print("hello \(foo1) \(foo2)")
    }

    try Rentgen.ClosureArcTool.hookOnNonThrowing(for: myClosure) { (strongRefs, unownedRefs, weakRefs) in
        print("Did retain. Strong: \(strongRefs), unowned: \(unownedRefs), weak: \(weakRefs).")
    }
    beforeRelease: { (strongRefs, unownedRefs, weakRefs) in
        print("Will release. Strong: \(strongRefs), unowned: \(unownedRefs), weak: \(weakRefs)")
    }
```

## Resources and notes

This tools is based upon discussion about the [behaviour of closures on the Swift Forum](https://forums.swift.org/t/how-do-closures-work-memory-management/47512) and discussion about [troubleshooting strong retain overflows](https://forums.swift.org/t/object-was-retained-too-many-times/40855). 

The Rentgen package takes ideas discussed in the above mentioned threads and packages them for real-world use and modification.

The whole package is based on various assumptions on how the objects in memory look at runtime. There may be case that I haven't noticed during implementation. One case I have patched is optimization, where no capture list is allocated, if closure captures only one instance of a reference counted type.

