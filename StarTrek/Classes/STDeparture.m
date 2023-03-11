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
//  STDeparture.m
//  StarTrek
//
//  Created by Albert Moky on 2023/3/9.
//

#import <ObjectKey/ObjectKey.h>

#import "OKWeakMap.h"

#import "STDeparture.h"

/**
 *  Departure task will be expired after 2 minutes
 *  if no response received.
 */
static const NSTimeInterval DEPARTURE_EXPIRES = 120.0;  // seconds

/**
 *  Important departure task will be retried 2 times
 *  if response timeout.
 */
static const NSInteger DEPARTURE_RETRIES = 2;

@interface STDeparture () {
    
    NSTimeInterval _expired;  // expired time
    NSInteger _tries;         // how many times to try sending
    
    NSInteger _priority;      // task priority, smaller is faster
}

@end

@implementation STDeparture

- (instancetype)init {
    return [self initWithPriority:0 maxTries:(1 + DEPARTURE_RETRIES)];
}

/* designated initializer */
- (instancetype)initWithPriority:(NSInteger)prior maxTries:(NSInteger)count {
    if (self = [super init]) {
        _priority = prior;
        _tries = count;
        _expired = 0;
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
    NSAssert(_tries > 0, @"touch error, tries=%ld", _tries);
    // decrease counter
    --_tries;
    // update retried time
    _expired = now + DEPARTURE_EXPIRES;
}

// Override
- (STShipStatus)status:(NSTimeInterval)now {
    NSArray<NSData *> *fragments = [self fragments];
    if ([fragments count] == 0) {
        return STShipStatusDone;
    } else if (_expired == 0) {
        return STShipStatusNew;
    //} else if (![self isImportant]) {
    //    return STShipStatusDone;
    } else if (now < _expired) {
        return STShipStatusWaiting;
    } else if (_tries > 0) {
        return STShipStatusTimeout;
    } else {
        return STShipStatusFailed;
    }
}

// Override
- (NSArray<NSData *> *)fragments {
    NSAssert(false, @"override me!");
    return nil;
}

// Override
- (BOOL)checkResponseWithinArrivalShip:(id<STArrival>)response {
    NSAssert(false, @"override me!");
    return NO;
}

// Override
- (BOOL)isImportant {
    NSAssert(false, @"override me!");
    return NO;
}

// Override
- (NSInteger)priority {
    return _priority;
}

@end

#pragma mark -

@interface STDepartureHall ()

// all departure ships
@property(nonatomic, strong) OKWeakSet<id<STDeparture>> *allDepartures;

// new ships waiting to send out
@property(nonatomic, strong) OKArrayList<id<STDeparture>> *virginDepartures;

// ships waiting for responses
@property(nonatomic, strong) OKHashMap<NSNumber *, OKArrayList<id<STDeparture>> *> *fleets;
@property(nonatomic, strong) OKArrayList<NSNumber *> *priorities;

// index
@property(nonatomic, strong) OKWeakMap<id<STShipID>, id<STDeparture>> *departureMap;
@property(nonatomic, strong) OKHashMap<id<STShipID>, NSNumber *> *departureFinished;
@property(nonatomic, strong) OKWeakHashMap<id<STShipID>, NSNumber *> *departureLevel;

@end

@implementation STDepartureHall

- (BOOL)addDeparture:(id<STDeparture>)outgo {
    // 1. check duplicated
    if ([_allDepartures containsObject:outgo]) {
        return NO;
    } else {
        [_allDepartures addObject:outgo];
    }
    // 2. insert to the sorted queue
    NSInteger priority = [outgo priority];
    __block NSInteger index = 0;
    [_virginDepartures enumerateObjectsUsingBlock:^(id<STDeparture> ship, NSUInteger idx, BOOL *stop) {
        if ([ship priority] > priority) {
            // take the place before first ship
            // which priority is greater then this one.
            index = idx;
            *stop = YES;
        }
    }];
    [_virginDepartures insertObject:outgo atIndex:index];
    return YES;
}

- (id<STDeparture>)checkResponseInArrival:(id<STArrival>)response {
    id<STShipID> sn = [response sn];
    NSAssert(sn, @"Ship SN not found: %@", response);
    // check whether this task has already finished
    NSNumber *time = [_departureFinished objectForKey:sn];
    if ([time doubleValue] > 0) {
        return nil;
    }
    // check departure
    id<STDeparture> ship = [_departureMap objectForKey:sn];
    if ([ship checkResponseWithinArrivalShip:response]) {
        // all fragments sent, departure task finished
        // remove it and clear mapping when SN exists
        [self removeDepartureShip:ship withID:sn];
        // mark finished time
        [_departureFinished setObject:@(OKGetCurrentTimeInterval()) forKey:sn];
        return ship;
    }
    return nil;
}

// private
- (void)removeDepartureShip:(id<STDeparture>)ship withID:(id<STShipID>)sn {
    NSNumber *priority = [_departureLevel objectForKey:sn];
    OKArrayList<id<STDeparture>> *array = [_fleets objectForKey:priority];
    if (array) {
        [array removeObject:ship];
        // remove array when empty
        if ([array count] == 0) {
            [_fleets removeObjectForKey:priority];
        }
    }
    // remove mapping by SN
    [_departureMap removeObjectForKey:sn];
    [_departureLevel removeObjectForKey:sn];
    [_allDepartures removeObject:ship];
}

- (id<STDeparture>)nextDepartureWithTime:(NSTimeInterval)now {
    // task.expired == 0
    id<STDeparture> next = [self nextNewDepartureWithTime:now];
    return next ? next : [self nextTimeoutDepartureWithTime:now];
}

// private
- (id<STDeparture>)nextNewDepartureWithTime:(NSTimeInterval)now {
    if ([_virginDepartures count] == 0) {
        return nil;
    }
    // get first ship
    id<STDeparture> outgo = [_virginDepartures firstObject];
    [_virginDepartures removeObjectAtIndex:0];
    id<STShipID> sn = [outgo sn];
    if ([outgo isImportant] && sn) {
        // this task needs response
        // choose an array with priority
        NSInteger priority = [outgo priority];
        [self insertDepartureShip:outgo withID:sn priority:priority];
        // build index for it
        [_departureMap setObject:outgo forKey:sn];
    } else {
        // disposable ship needs no response,
        // remove it immediately
        [_allDepartures removeObject:outgo];
    }
    // update expired time
    [outgo touch:now];
    return outgo;
}
// private
- (void)insertDepartureShip:(id<STDeparture>)outgo withID:(id<STShipID>)sn priority:(NSInteger)prior {
    OKArrayList<id<STDeparture>> *array = [_fleets objectForKey:@(prior)];
    if (!array) {
        // create new array for this priority
        array = [[OKArrayList alloc] init];
        [_fleets setObject:array forKey:@(prior)];
        // insert the priority in a sorted list
        [self insertPriority:prior];
    }
    // append to the tail, and build index for it
    [array addObject:outgo];
    [_departureLevel setObject:@(prior) forKey:sn];
}
// private
- (void)insertPriority:(NSInteger)priority {
    __block NSInteger index = 0;
    // seeking position for new priority
    [_priorities enumerateObjectsUsingBlock:^(NSNumber *val, NSUInteger idx, BOOL *stop) {
        NSInteger value = [val integerValue];
        if (value == priority) {
            // duplicated
            index = -1;
            *stop = YES;
        } else if (value > priority) {
            // got it
            index = idx;
            *stop = YES;
        }
        // current value is smaller than the new value,
        // keep going
    }];
    if (index >= 0) {
        // insert new value before the bigger one
        [_priorities insertObject:@(priority) atIndex:index];
    }
}

// private
- (id<STDeparture>)nextTimeoutDepartureWithTime:(NSTimeInterval)now {
    __block id<STDeparture> result = nil;
    [_priorities enumerateObjectsUsingBlock:^(NSNumber *prior, NSUInteger idx, BOOL *stop) {
        NSInteger priority = [prior integerValue];
        // 1. get tasks with priority
        OKArrayList<id<STDeparture>> *array = [_fleets objectForKey:prior];
        if (array) {
            // 2. seeking timeout task in this priority
            [array enumerateObjectsUsingBlock:^(id<STDeparture> ship, NSUInteger idx2, BOOL *stop2) {
                id<STShipID> sn = [ship sn];
                NSAssert(sn, @"Ship ID should not be empty here");
                STShipStatus status = [ship status:now];
                if (status == STShipStatusTimeout) {
                    // response timeout, needs retry now.
                    // move to next priority
                    [array removeObject:ship];
                    [self insertDepartureShip:ship withID:sn priority:(priority + 1)];
                    // update expired time
                    [ship touch:now];
                    result = ship;
                    *stop2 = YES;
                } else if (status == STShipStatusFailed) {
                    // try too many times and still missing response,
                    // task failed, remove this ship.
                    [array removeObject:ship];
                    // remove mapping by SN
                    [_departureMap removeObjectForKey:sn];
                    [_departureLevel removeObjectForKey:sn];
                    [_allDepartures removeObject:ship];
                    result = ship;
                    *stop2 = YES;
                }
            }];
            if (result) {
                // got it
                *stop = YES;
            }
        }
    }];
    return result;
}

- (void)purge {
    NSTimeInterval now = OKGetCurrentTimeInterval();
    // 1. seeking finished tasks
    OKArrayList<NSNumber *> *emptyPositions = [[OKArrayList alloc] init];
    [_priorities enumerateObjectsWithOptions:NSEnumerationConcurrent
                                  usingBlock:^(NSNumber *prior, NSUInteger idx, BOOL *stop) {
        OKArrayList<id<STDeparture>> *array = [_fleets objectForKey:prior];
        if (array) {
            OKArrayList<id<STDeparture>> *finished = [[OKArrayList alloc] init];
            [array enumerateObjectsWithOptions:NSEnumerationConcurrent
                                    usingBlock:^(id<STDeparture> ship, NSUInteger idx2, BOOL *stop2) {
                if ([ship status:now] == STShipStatusDone) {
                    // task done
                    [finished addObject:ship];
                    id<STShipID> sn = [ship sn];
                    NSAssert(sn, @"Ship SN should not be empty here");
                    [_departureMap removeObjectForKey:sn];
                    [_departureLevel removeObjectForKey:sn];
                    // mark finished time
                    [_departureFinished setObject:@(OKGetCurrentTimeInterval()) forKey:sn];
                }
            }];
            // remove finished tasks
            [finished enumerateObjectsWithOptions:NSEnumerationConcurrent
                                       usingBlock:^(id<STDeparture> ship, NSUInteger idx3, BOOL *stop3) {
                [array removeObject:ship];
            }];
            // remove array when empty
            if ([array count] == 0) {
                [_fleets removeObjectForKey:prior];
                [emptyPositions addObject:@(idx)];
            }
        } else {
            // this priority is empty
            [emptyPositions addObject:@(idx)];
        }
    }];
    [emptyPositions enumerateObjectsWithOptions:NSEnumerationReverse
                                     usingBlock:^(NSNumber *pos, NSUInteger idx, BOOL *stop) {
        [_priorities removeObjectAtIndex:[pos integerValue]];
    }];
    // 2. seeking neglected finished times
    OKArrayList<id<STShipID>> *neglected = [[OKArrayList alloc] init];
    NSTimeInterval ago = now - 3600.0;
    [_departureFinished enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent
                                                usingBlock:^(id<STShipID> sn, NSNumber *when, BOOL *stop) {
        if ([when doubleValue] < ago) {
            // long time ago
            [neglected addObject:sn];
        }
    }];
    [neglected enumerateObjectsWithOptions:NSEnumerationConcurrent
                                usingBlock:^(id<STShipID> sn, NSUInteger idx, BOOL *stop) {
        [_departureFinished removeObjectForKey:sn];
    }];
}

@end
