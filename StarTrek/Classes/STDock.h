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
//  STDock.h
//  StarTrek
//
//  Created by Albert Moky on 2023/3/9.
//

#import <StarTrek/STArrival.h>
#import <StarTrek/STDeparture.h>

NS_ASSUME_NONNULL_BEGIN

@interface STDock : NSObject

// protected
- (STArrivalHall *)createArrivalHall;

// protected
- (STDepartureHall *)createDepartureHall;

/**
 * Check received ship for completed package
 *
 * @param income - received ship carrying data package (fragment)
 * @return ship carrying completed data package
 */
- (id<STArrival>)assembleArrival:(id<STArrival>)income;

/**
 *  Add outgoing ship to the waiting queue
 *
 * @param outgo - departure task
 * @return false on duplicated
 */
- (BOOL)addDeparture:(id<STDeparture>)outgo;

/**
 *  Check response from incoming ship
 *
 * @param response - incoming ship with SN
 * @return finished task
 */
- (id<STDeparture>)checkResponseInArrival:(id<STArrival>)response;

/**
 *  Get next new/timeout task
 *
 * @param now - current time
 * @return departure task
 */
- (id<STDeparture>)nextDepartureWithTime:(NSTimeInterval)now;

/**
 * Clear all expired tasks
 */
- (void)purge;

@end

@interface STLockedDock : STDock

@end

NS_ASSUME_NONNULL_END
