#ifndef commondeclarations_h
#define commondeclarations_h

/// Callback which should be called before a any hook user data is disposed of.
/// @param user_data: Pointer to user data
typedef void (*generic_user_data_destroy)(void * _Nullable);

/// Callback which is called whenever an retain/release event occurs.
/// @param arg_1: Number of strong retains.
/// @param arg_2: Number of weak retains.
/// @param arg_3: Number of unowned retains.
/// @param arg_4: Pointer to the user data associated with this callback execution.
/// @see: https://github.com/apple/swift/blob/7123d2614b5f222d03b3762cb110d27a9dd98e24/stdlib/public/SwiftShims/RefCount.h#L43
typedef void (*swift_object_retain_release_callback)(size_t, size_t, size_t, void * _Nullable);

/// From CoreFoundation/CFBase.h
/// @see: https://developer.apple.com/documentation/swift/objective-c_and_c_code_customization/customizing_your_c_code_for_swift
#if __has_attribute(swift_name)
# define SWIFT_NAME(_name) __attribute__((swift_name(#_name)))
#else
# define SWIFT_NAME(_name)
#endif

#endif
