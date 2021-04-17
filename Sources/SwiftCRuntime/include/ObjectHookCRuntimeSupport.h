#ifndef swiftcruntime_h
#define swiftcruntime_h

#include <stdlib.h>
#include <stdbool.h>
#include "CommonDeclarations.h"

typedef void (*swift_object_observer_callback)(size_t, size_t, size_t, void * _Nullable);

#define ARC_OBSERVERS_MAX_COUNT 100

bool add_arc_observer_for(
    void * _Nonnull object,
    swift_object_observer_callback _Nonnull didIncRef,
    void * _Nullable incRefUserData,
    generic_user_data_destroy _Nullable incRefDataDestroy,
    swift_object_observer_callback _Nonnull willDecRef,
    void * _Nullable decRefUserData,
    generic_user_data_destroy _Nullable decRefDataDestroy
);

bool remove_arc_observer_for(void * _Nonnull object);

#endif
