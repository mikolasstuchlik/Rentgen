#include <stdio.h>
#include "include/ObjectHookCRuntimeSupport.h"
#include "include/ExposedSwiftRuntimeDeclarations.h"
#include "PrivatelyExposedSwiftRuntime.h"

/// Storage for original implementation of "swizzeled" `swift_retain`.
static void *(*_original_swift_retain)(void *);

/// Storage for original implementation of "swizzeled" `swift_release`.
static void (*_original_swift_release)(void *);

/// Structure associating heap object `object` with data required to execute and dispose of a hook whenever retain
/// or release occurs.
struct ArcRetainReleaseObserver {
    /// Observed `HeapObject`
    void * object;
    /// Callback executed after retain occurs
    swift_object_retain_release_callback didIncRef;
    /// User data passed to retain increase callback.
    void * incRefUserData;
    /// Callback executed when hook is disposed of in order to invalidate user data.
    generic_user_data_destroy _Nullable incRefDataDestroy;
    /// Callback executed before release occurs
    swift_object_retain_release_callback willDecRef;
    /// User data passed to retain decrease callback.
    void * decRefUserData;
    /// Callback executed when hook is disposed of in order to invalidate user data.
    generic_user_data_destroy _Nullable decRefDataDestroy;
};

/// This function sets all fields to NULL
static void clean_arc_retain_observer(struct ArcRetainReleaseObserver * _Nonnull ptr) {
    ptr->object = NULL;
    ptr->didIncRef = NULL;
    ptr->incRefUserData = NULL;
    ptr->incRefDataDestroy = NULL;
    ptr->willDecRef = NULL;
    ptr->decRefUserData = NULL;
    ptr->decRefDataDestroy = NULL;
}

/// Array representing pool of observer of strong retain/release operations. Dynamic data structure might be
/// introduced in future.
static struct ArcRetainReleaseObserver strong_observers[ARC_STRONG_OBSERVERS_MAX_COUNT];

/// MARK: - Functions for manipulating strong retain/release events
bool arc_add_strong_observer_for(
    void * _Nonnull object,
    swift_object_retain_release_callback _Nonnull didIncRef,
    void * _Nullable incRefUserData,
    generic_user_data_destroy _Nullable incRefDataDestroy,
    swift_object_retain_release_callback _Nonnull willDecRef,
    void * _Nullable decRefUserData,
    generic_user_data_destroy _Nullable decRefDataDestroy
) {
    for (int i = 0; i < ARC_STRONG_OBSERVERS_MAX_COUNT; i++) {
        if (strong_observers[i].object == NULL) {
            strong_observers[i].object = object;
            strong_observers[i].didIncRef = didIncRef;
            strong_observers[i].incRefUserData = incRefUserData;
            strong_observers[i].incRefDataDestroy = incRefDataDestroy;
            strong_observers[i].willDecRef = willDecRef;
            strong_observers[i].decRefUserData = decRefUserData;
            strong_observers[i].decRefDataDestroy = decRefDataDestroy;
            return true;
        }
    }

    return false;
}

bool arc_remove_strong_observer_for( void * _Nonnull object) {
    bool found = false;
    for (int i = 0; i < ARC_STRONG_OBSERVERS_MAX_COUNT; i++) {
        if (strong_observers[i].object == object) {
            if (strong_observers[i].incRefDataDestroy != NULL) {
                strong_observers[i].incRefDataDestroy(strong_observers[i].incRefUserData);
            }
            if (strong_observers[i].decRefDataDestroy != NULL) {
                strong_observers[i].decRefDataDestroy(strong_observers[i].decRefUserData);
            }

            clean_arc_retain_observer(&strong_observers[i]);
            found = true;
        }
    }

    return found;
}

int arc_count_strong_hooks() {
    int count = 0;
    for (int i = 0; i < ARC_STRONG_OBSERVERS_MAX_COUNT; i++) {
        if (strong_observers[i].object != NULL) {
            count++;
        }
    }

    return count;
}

// MARK: - Runtime injection
static void *swift_retain_hook(void *object) {
    void * result = _original_swift_retain(object);

    if (object != NULL) {
        for (int i = 0; i < ARC_STRONG_OBSERVERS_MAX_COUNT; i++) {
            if (strong_observers[i].object == object) {
                strong_observers[i].didIncRef(swift_retainCount(object), swift_weakRetainCount(object), swift_unownedRetainCount(object), strong_observers[i].incRefUserData);
            }
        }
    }

    return result;
}

static void swift_release_hook(void *object) {
    if (object != NULL) {
        for (int i = 0; i < ARC_STRONG_OBSERVERS_MAX_COUNT; i++) {
            if (strong_observers[i].object == object) {
                strong_observers[i].willDecRef(swift_retainCount(object), swift_weakRetainCount(object), swift_unownedRetainCount(object), strong_observers[i].decRefUserData);

                if (swift_retainCount(object) == 1) {
                    printf("Retain count 1 for observed object before release, removing observer\n");
                    arc_remove_strong_observer_for(object);
                }
            }
        }
    }

    _original_swift_release(object);
}

/// This function is automaticaly executed when program is started
__attribute__((constructor))
static void hook_rentgen_into_swift() {
    // This initialization is merely for piece of mind
    for (int i = 0; i < ARC_STRONG_OBSERVERS_MAX_COUNT; i++) {
        clean_arc_retain_observer(&strong_observers[i]);
    }

    // Replace original retain with hook
    _original_swift_retain = _swift_retain;
    _swift_retain = swift_retain_hook;

    // Replace original release with hook
    _original_swift_release = _swift_release;
    _swift_release = swift_release_hook;
}

