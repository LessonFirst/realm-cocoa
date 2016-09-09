//
//  RLMThreadSafeReference.m
//  Realm
//
//  Created by Realm on 9/7/16.
//  Copyright © 2016 Realm. All rights reserved.
//

#import "RLMThreadSafeReference_Private.hpp"
#import "RLMRealm_Private.hpp"
#import "RLMUtil.hpp"
#import "shared_realm.hpp"

@implementation RLMThreadSafeReference {
@private
    std::unique_ptr<realm::ThreadSafeReferenceBase> _reference;
    id _metadata;
    Class _type;
}

- (instancetype)initWithThreadConfined:(id<RLMThreadConfined>)threadConfined {
    if (!(self = [super init])) {
        return nil;
    }

    REALM_ASSERT_DEBUG([threadConfined conformsToProtocol: @protocol(RLMThreadConfined)]);
    if (![threadConfined conformsToProtocol: @protocol(RLMThreadConfined_Private)]) {
        @throw RLMException(@"Illegal custom conformance to `RLMThreadConfined` by `%@`", threadConfined.class);
    }
    if (threadConfined.invalidated) {
        @throw RLMException(@"Cannot construct reference to invalidated object");
    }
    if (!threadConfined.realm) {
        @throw RLMException(@"Cannot construct reference to unmanaged object,"
                            "which can be passed across threads directly");
    }

    _reference = [(id<RLMThreadConfined_Private>)threadConfined rlm_newThreadSafeReference];
    _metadata = ((id<RLMThreadConfined_Private>)threadConfined).rlm_objectiveCMetadata;
    _type = threadConfined.class;

    return self;
}

+ (instancetype)referenceWithThreadConfined:(id<RLMThreadConfined>)threadConfined {
    return [[self alloc] initWithThreadConfined:threadConfined];
}

- (id<RLMThreadConfined>)resolveReferenceInRealm:(RLMRealm *)realm {
    if (!_reference) {
        @throw RLMException(@"Can only resolve a thread safe reference once.");
    }
    return [_type rlm_objectWithThreadSafeReference:std::move(_reference) metadata:_metadata realm:realm];
}

- (BOOL)isInvalidated {
    return (bool)_reference;
}

@end
