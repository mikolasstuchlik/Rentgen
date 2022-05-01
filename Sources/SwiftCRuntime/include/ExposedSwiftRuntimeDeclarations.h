#ifndef ExposedSwiftRuntimeDeclarations_h
#define ExposedSwiftRuntimeDeclarations_h

/// Returns numerical value representing the kind of metadata
/// @see: https://github.com/apple/swift/blob/7123d2614b5f222d03b3762cb110d27a9dd98e24/stdlib/public/runtime/ReflectionMirror.cpp#L977
size_t swift_getMetadataKind(const void * _Nonnull);

/// Returns string describing the natrue of the type
/// @see: https://github.com/apple/swift/blob/7123d2614b5f222d03b3762cb110d27a9dd98e24/stdlib/public/runtime/ReflectionMirror.cpp#L1068
const char * _Nullable swift_OpaqueSummary(const void * _Nonnull);

/// Returns type name
const char * _Nullable swift_getTypeName(const void * _Nonnull objectIsa, _Bool qualified);

#endif /* ExposedSwiftRuntimeDeclarations_h */
