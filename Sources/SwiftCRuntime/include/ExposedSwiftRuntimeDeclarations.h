#ifndef Header_h
#define Header_h

/// Returns numerical value representing the kind of metadata
/// @see: https://github.com/apple/swift/blob/7123d2614b5f222d03b3762cb110d27a9dd98e24/stdlib/public/runtime/ReflectionMirror.cpp#L977
size_t swift_getMetadataKind(void * _Nonnull);

/// Returns string describing the natrue of the type
/// @see: https://github.com/apple/swift/blob/7123d2614b5f222d03b3762cb110d27a9dd98e24/stdlib/public/runtime/ReflectionMirror.cpp#L1068
const char * _Nullable swift_OpaqueSummary(void * _Nonnull);

/// Returns type name
const char * _Nullable swift_getTypeName(void * _Nonnull classObject, _Bool qualified);

/// Rebounds heap object to get isa pointer.
/// @see: https://forums.swift.org/t/object-was-retained-too-many-times/40855/4
/// @see: https://belkadan.com/blog/2020/08/Swift-Runtime-Heap-Objects/
void * _Nonnull heap_object_to_isa_field(const void * _Nonnull objectRef) {
    return *(void **)objectRef;
}

#endif /* Header_h */
