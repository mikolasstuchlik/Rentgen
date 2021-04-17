#include "include/SwiftCRuntime.h"

extern void *(*_swift_retain)(void *);
extern void (*_swift_release)(void *);

/// From https://github.com/apple/swift/blob/dc09a66f29e8d785dee911259c6d2551aa782ff4/stdlib/public/core/DebuggerSupport.swift#L268
size_t swift_retainCount(void *);

/// From https://github.com/apple/swift/blob/dc09a66f29e8d785dee911259c6d2551aa782ff4/stdlib/public/core/DebuggerSupport.swift#L270
size_t swift_unownedRetainCount(void *);

/// From https://github.com/apple/swift/blob/dc09a66f29e8d785dee911259c6d2551aa782ff4/stdlib/public/core/DebuggerSupport.swift#L272
size_t swift_weakRetainCount(void *);

static void *(*_original_swift_retain)(void *);
static void (*_original_swift_release)(void *);


struct ArcObserver {
    void * object;
    swift_object_observer_callback didIncRef;
    void * incRefUserData;
    generic_user_data_destroy _Nullable incRefDataDestroy;
    swift_object_observer_callback willDecRef;
    void * decRefUserData;
    generic_user_data_destroy _Nullable decRefDataDestroy;
};

static struct ArcObserver observers[ARC_OBSERVERS_MAX_COUNT];

bool add_arc_observer_for(
    void * _Nonnull object,
    swift_object_observer_callback _Nonnull didIncRef,
    void * _Nullable incRefUserData,
    generic_user_data_destroy _Nullable incRefDataDestroy,
    swift_object_observer_callback _Nonnull willDecRef,
    void * _Nullable decRefUserData,
    generic_user_data_destroy _Nullable decRefDataDestroy
) {
    for (int i = 0; i < ARC_OBSERVERS_MAX_COUNT; i++) {
        if (observers[i].object == NULL) {
            observers[i].object = object;
            observers[i].didIncRef = didIncRef;
            observers[i].incRefUserData = incRefUserData;
            observers[i].incRefDataDestroy = incRefDataDestroy;
            observers[i].willDecRef = willDecRef;
            observers[i].decRefUserData = decRefUserData;
            observers[i].decRefDataDestroy = decRefDataDestroy;
            return true;
        }
    }

    return false;
}

bool remove_arc_observer_for( void * _Nonnull object) {
    bool found = false;
    for (int i = 0; i < ARC_OBSERVERS_MAX_COUNT; i++) {
        if (observers[i].object == object) {
            if (observers[i].incRefDataDestroy != NULL) {
                observers[i].incRefDataDestroy(observers[i].incRefUserData);
            }
            if (observers[i].decRefDataDestroy != NULL) {
                observers[i].decRefDataDestroy(observers[i].decRefUserData);
            }

            observers[i].object = NULL;
            observers[i].didIncRef = NULL;
            observers[i].incRefUserData = NULL;
            observers[i].incRefDataDestroy = NULL;
            observers[i].willDecRef = NULL;
            observers[i].decRefUserData = NULL;
            observers[i].decRefDataDestroy = NULL;
            found = true;
        }
    }

    return found;
}



static void *swift_retain_hook(void *object) {
    void * result = _original_swift_retain(object);

    if (object != NULL) {
        for (int i = 0; i < ARC_OBSERVERS_MAX_COUNT; i++) {
            if (observers[i].object == object) {
                observers[i].didIncRef(swift_retainCount(object), swift_weakRetainCount(object), swift_unownedRetainCount(object), observers[i].incRefUserData);
            }
        }
    }

    return result;
}

static void swift_release_hook(void *object) {
    if (object != NULL) {
        for (int i = 0; i < ARC_OBSERVERS_MAX_COUNT; i++) {
            if (observers[i].object == object) {
                observers[i].willDecRef(swift_retainCount(object), swift_weakRetainCount(object), swift_unownedRetainCount(object), observers[i].decRefUserData);

                if (swift_retainCount(object) == 1) {
                    printf("Retain count 1 for observed object before release, removing observer");
                    remove_arc_observer_for(object);
                }
            }
        }
    }

    _original_swift_release(object);
}

__attribute__((constructor))
static void hook_rentgen_into_swift() {
    for (int i = 0; i < ARC_OBSERVERS_MAX_COUNT; i++) {
        observers[i].object = NULL;
        observers[i].didIncRef = NULL;
        observers[i].incRefUserData = NULL;
        observers[i].incRefDataDestroy = NULL;
        observers[i].willDecRef = NULL;
        observers[i].decRefUserData = NULL;
        observers[i].decRefDataDestroy = NULL;
    }


    _original_swift_retain = _swift_retain;
    _swift_retain = swift_retain_hook;


    _original_swift_release = _swift_release;
    _swift_release = swift_release_hook;
}
