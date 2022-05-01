#ifndef swiftcruntime_h
#define swiftcruntime_h

#include <stdlib.h>
#include <stdbool.h>
#include "CommonDeclarations.h"

/// Enum expressing what pool should be used.
enum StrongHookPool {
    /// Pool for instances of class.
    ObjectPool = 0,
    /// Pool for closure contexts.
    ClosurePool,
    /// Since enum is tagged from 0, keep this case last to express number of pools
    NUMBER_OF_STRONG_POOLS
};

/// Hard limit for number of strong retain observers per pool.
#define ARC_STRONG_OBSERVERS_PER_POOL 50

/// Total size of hook register.
#define ARC_STRONG_OBSERVERS_TOTAL ARC_STRONG_OBSERVERS_PER_POOL * NUMBER_OF_STRONG_POOLS

/// This will hook callbacks whenever retain/release is executed.
/// @discussion While it is safe to pass arbitrary address as a heap object, it could lead to unexpected behavior. The developer is responsible for correct rebound.
/// @param heapObjectAddress: instance of heap object that should be observed
/// @param at: pool which should be used for this hook
/// @param didIncrementCallback: callback executed after retain count is incremented
/// @param didIncrementUserData: user data passed to retain callback
/// @param destroyDidIncrementUserDataCallback: callback called before user data if increase callback are removed in order to dispose of them
/// @param willDecrementCallback: callback executed before retain count is decreased
/// @param willDecrementUserData: user data passed to release callback
/// @param destroyWillDecrementUserDataCallback: callback called before user data of decrease callback are removed in order to dispose of them
/// @return: `true` if successful, `false` if there was no room for additional hook
bool arc_add_strong_observer_for(
    const void * _Nonnull object,
    enum StrongHookPool pool,
    swift_object_retain_release_callback _Nonnull didIncRef,
    void * _Nullable incRefUserData,
    generic_user_data_destroy _Nullable incRefDataDestroy,
    swift_object_retain_release_callback _Nonnull willDecRef,
    void * _Nullable decRefUserData,
    generic_user_data_destroy _Nullable decRefDataDestroy
)
SWIFT_NAME(arcAddStrongObserver(heapObjectAddress:at:didIncrementCallback:didIncrementUserData:destroyDidIncrementUserDataCallback:willDecrementCallback:willDecrementUserData:destroyWillDecrementUserDataCallback:));

/// This method will remove hook for given heap object. It does not matter which pool contains the hook.
/// @return: `true` if at least one hook was found and removed
bool arc_remove_strong_observer_for(const void * _Nonnull object)
SWIFT_NAME(arcRemoveStrongObserver(heapObjectAddress:));

/// Number of non-null hook slots
/// @param at: pool which should be counted
int arc_count_strong_hooks(enum StrongHookPool pool)
SWIFT_NAME(arcCountStrongHooks(at:));

#endif
