#include "include/Utilities.h"

void * _Nonnull heap_object_to_isa_field(const void * _Nonnull objectRef) {
    return *(void **)objectRef;
}
