#ifndef Utilities_h
#define Utilities_h

/// Rebounds heap object to get isa pointer.
/// @see: https://forums.swift.org/t/object-was-retained-too-many-times/40855/4
/// @see: https://belkadan.com/blog/2020/08/Swift-Runtime-Heap-Objects/
void * _Nonnull heap_object_to_isa_field(const void * _Nonnull objectRef);

#endif /* Utilities_h */
