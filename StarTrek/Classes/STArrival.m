// license: https://mit-license.org
//
//  StarTrek : Interstellar Transport
//
//                               Written in 2023 by Moky <albert.moky@gmail.com>
//
// =============================================================================
// The MIT License (MIT)
//
// Copyright (c) 2023 Albert Moky
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// =============================================================================
//
//  STArrival.m
//  StarTrek
//
//  Created by Albert Moky on 2023/3/9.
//

#import <ObjectKey/ObjectKey.h>

#import "OKWeakMap.h"

#import "STArrival.h"

/**
 *  Arrival task will be expired after 5 minutes
 *  if still not completed.
 */
static const NSTimeInterval ARRIVAL_EXPIRES = 300.0;  // seconds

@interface STArrival () {
    
    // expired time (seconds from Jan 1, 1970 UTC)
    NSTimeInterval _expired;
}

@end

@implementation STArrival

- (instancetype)init {
    return [self initWithTime:OKGetCurrentTimeInterval()];
}

/* designated initializer */
- (instancetype)initWithTime:(NSTimeInterval)now {
    if (self = [super init]) {
        _expired = now + ARRIVAL_EXPIRES;
    }
    return self;
}

// Override
- (id<STShipID>)sn {
    NSAssert(false, @"override me!");
    return nil;
}

// Override
- (void)touch:(NSTimeInterval)now {
    // update expired time
    _expired = now + ARRIVAL_EXPIRES;
}

// Override
- (STShipStatus)status:(NSTimeInterval)now {
    if (now > _expired) {
        return STShipStatusExpired;
    } else {
        return STShipStatusAssembling;
    }
}

// Override
- (nullable id<STArrival>)assembleArrivalShip:(id<STArrival>)income {
    NSAssert(false, @"override me!");
    return nil;
}

@end

#pragma mark -

@interface STArrivalHall ()

@property(nonatomic, strong) OKHashSet<id<STArrival>> *arrivals;

// SN => ship
@property(nonatomic, strong) OKWeakMap<id<STShipID>, id<STArrival>> *arrivalMap;

// SN => timestamp
@property(nonatomic, strong) OKHashMap<id<STShipID>, NSNumber *> *arrivalFinished;

@end

@implementation STArrivalHall

- (instancetype)init {
    if (self = [super init]) {
        self.arrivals = [OKHashSet set];
        self.arrivalMap = [OKWeakMap map];
        self.arrivalFinished = [OKHashMap dictionary];
    }
    return self;
}

- (id<STArrival>)assembleArrival:(id<STArrival>)income {
    // 1. check ship ID (SN)
    id<STShipID> sn = [income sn];
    if (!sn) {
        // separated package ship must have SN for assembling
        // we consider it to be a ship carrying a whole package here
        return income;
    }
    // 2. check cached ship
    id<STArrival> completed;
    id<STArrival> cached = [_arrivalMap objectForKey:sn];
    if (!cached) {
        // check whether the task has already finished
        NSNumber *time = [_arrivalFinished objectForKey:sn];
        if ([time doubleValue] > 0) {
            // task already finished
            return nil;
        }
        // 3. new arrival, try assembling to check whether a fragment
        completed = [income assembleArrivalShip:income];
        if (!completed) {
            // it's a fragment, waiting for more fragments
            [_arrivals addObject:income];
            [_arrivalMap setObject:income forKey:sn];
            //[income touch:OKGetCurrentTimeInterval()];
        }
        // else, it's a completed package
    } else {
        // 3. cached ship found, try assembling (insert as fragment)
        //    to check whether all fragments received
        completed = [cached assembleArrivalShip:income];
        if (completed) {
            // all fragments received, remove cached ship
            [_arrivals removeObject:cached];
            [_arrivalMap removeObjectForKey:sn];
            // mark finished time
            [_arrivalFinished setObject:@(OKGetCurrentTimeInterval()) forKey:sn];
        }
    }
    return completed;
}

- (void)purge {
    NSTimeInterval now = OKGetCurrentTimeInterval();
    // 1. seeking expired tasks
    OKHashSet<id<STArrival>> *expired = [[OKHashSet alloc] init];
    [_arrivals enumerateObjectsWithOptions:NSEnumerationConcurrent
                                usingBlock:^(id<STArrival> ship, BOOL *stop) {
        if ([ship status:now] == STShipStatusExpired) {
            // task expired
            [expired addObject:ship];
            // remove mapping with SN
            id<STShipID> sn = [ship sn];
            if (sn) {
                [_arrivalMap removeObjectForKey:sn];
                // TODO: callback?
            }
        }
    }];
    [expired enumerateObjectsWithOptions:NSEnumerationConcurrent
                              usingBlock:^(id<STArrival> ship, BOOL *stop) {
        [_arrivals removeObject:ship];
    }];
    // 2. seeking neglected finished times
    OKArrayList<id<STShipID>> *neglected = [[OKArrayList alloc] init];
    NSTimeInterval ago = now - 3600.0;
    [_arrivalFinished enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent
                                              usingBlock:^(id<STShipID> sn, NSNumber *when, BOOL *stop) {
        if ([when doubleValue] < ago) {
            // long time ago
            [neglected addObject:sn];
        }
    }];
    [neglected enumerateObjectsWithOptions:NSEnumerationConcurrent
                                usingBlock:^(id<STShipID> sn, NSUInteger idx, BOOL *stop) {
        [_arrivalFinished removeObjectForKey:sn];
    }];
}

@end
