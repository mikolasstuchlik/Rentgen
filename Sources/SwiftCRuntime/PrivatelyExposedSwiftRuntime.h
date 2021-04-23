#ifndef PrivatelyExposedSwiftRuntime
#define PrivatelyExposedSwiftRuntime

/*
Some Swift runtime functions are stored in a function pointer and their implementation
can be exchanged.

https://forums.swift.org/t/hacking-swift-runtime/42289/5
 */

/// Storage of `swift_retain` which increase strong retain count.
extern void *(*_swift_retain)(void *);

/// Storage of `swift_release` which decreses strong retain count (and is able to destroy the value).
extern void (*_swift_release)(void *);

/// Function returns the number of strong retains
/// From https://github.com/apple/swift/blob/dc09a66f29e8d785dee911259c6d2551aa782ff4/stdlib/public/core/DebuggerSupport.swift#L268
size_t swift_retainCount(void *);

/// Function returns the number of unowned retains
/// From https://github.com/apple/swift/blob/dc09a66f29e8d785dee911259c6d2551aa782ff4/stdlib/public/core/DebuggerSupport.swift#L270
size_t swift_unownedRetainCount(void *);

/// Function returns the number of weak retains
/// From https://github.com/apple/swift/blob/dc09a66f29e8d785dee911259c6d2551aa782ff4/stdlib/public/core/DebuggerSupport.swift#L272
size_t swift_weakRetainCount(void *);

#endif /* PrivatelyExposedSwiftRuntime */
