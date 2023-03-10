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
//  STDock.m
//  StarTrek
//
//  Created by Albert Moky on 2023/3/9.
//

#import "STDock.h"

@interface STDock ()

@property(nonatomic, strong) STArrivalHall *arrivalHall;
@property(nonatomic, strong) STDepartureHall *departureHall;

@end

@implementation STDock

- (instancetype)init {
    if (self = [super init]) {
        self.arrivalHall = [self createArrivalHall];
        self.departureHall = [self createDepartureHall];
    }
    return self;
}

// override for user-customized hall
- (STArrivalHall *)createArrivalHall {
    return [[STArrivalHall alloc] init];
}

// override for user-customized hall
- (STDepartureHall *)createDepartureHall {
    return [[STDepartureHall alloc] init];
}

- (id<STArrival>)assembleArrival:(id<STArrival>)income {
    // check fragment from income ship,
    // return a ship with completed package if all fragments received
    return [_arrivalHall assembleArrival:income];
}

- (BOOL)addDeparture:(id<STDeparture>)outgo {
    return [_departureHall addDeparture:outgo];
}

- (id<STDeparture>)checkResponseInArrival:(id<STArrival>)response {
    // check departure tasks with SN
    // remove package/fragment if matched (check page index for fragments too)
    return [_departureHall checkResponseInArrival:response];
}

- (id<STDeparture>)nextDepartureWithTime:(NSTimeInterval)now {
    // this will be remove from the queue,
    // if needs retry, the caller should append it back
    return [_departureHall nextDepartureWithTime:now];
}

- (void)purge {
    [_arrivalHall purge];
    [_departureHall purge];
}

@end

#pragma mark -

@implementation STLockedDock

- (id<STArrival>)assembleArrival:(id<STArrival>)income {
    @synchronized (self) {
        return [super assembleArrival:income];
    }
}

- (BOOL)addDeparture:(id<STDeparture>)outgo {
    @synchronized (self) {
        return [super addDeparture:outgo];
    }
}

- (id<STDeparture>)checkResponseInArrival:(id<STArrival>)response {
    @synchronized (self) {
        return [super checkResponseInArrival:response];
    }
}

- (id<STDeparture>)nextDepartureWithTime:(NSTimeInterval)now {
    @synchronized (self) {
        return [super nextDepartureWithTime:now];
    }
}

- (void)purge {
    @synchronized (self) {
        [super purge];
    }
}

@end
