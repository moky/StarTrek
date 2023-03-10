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
//  STShip.h
//  StarTrek
//
//  Created by Albert Moky on 2023/3/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(UInt8, STShipStatus) {
    //
    //  Arrival Status
    //
    STShipStatusAssembling = 0x00,  // waiting for more fragments
    STShipStatusExpired    = 0x01,  // failed to received all fragments
    
    //
    //  Departure Status
    //
    STShipStatusNew        = 0x10,  // not try yet
    STShipStatusWaiting    = 0x11,  // sent, waiting for responses
    STShipStatusTimeout    = 0x12,  // waiting to send again
    STShipStatusDone       = 0x13,  // all fragments responded (or no need respond)
    STShipStatusFailed     = 0x14,  // tried 3 times and missed response(s)
};

#define STShipID NSCopying

/**
 *  Star Ship
 *  ~~~~~~~~~
 *
 *  Container carrying data package
 */
@protocol STShip <NSObject>

/**
 *  Get ID for this Ship
 *
 * @return SN
 */
@property(nonatomic, readonly) id<STShipID> sn;

/**
 *  Update sent time
 *
 * @param now - current time
 */
- (void)touch:(NSTimeInterval)now;

/**
 *  Check ship state
 *
 * @param now - current time
 * @return current status
 */
- (STShipStatus)status:(NSTimeInterval)now;

@end

/**
 *  Incoming Ship
 *  ~~~~~~~~~~~~~
 */
@protocol STArrival <STShip>

/**
 *  Data package can be sent as separated batches
 *
 * @param income - income ship carried with message fragment
 * @return new ship carried the whole data package
 */
- (nullable id<STArrival>)assembleArrivalShip:(id<STArrival>)income;

@end

/**
 *  Outgoing Ship
 *  ~~~~~~~~~~~~~
 */
@protocol STDeparture <STShip>

/**
 *  Get fragments to sent
 *
 * @return remaining separated data packages
 */
@property(nonatomic, readonly) NSArray<NSData *> *fragments;

/**
 *  The arrival ship may carried response(s) for the departure.
 *  if all fragments responded, means this task is finished.
 *
 * @param response - income ship carried with response
 * @return true on task finished
 */
- (BOOL)checkResponseWithinArrivalShip:(id<STArrival>)response;

/**
 *  Whether needs to wait for responses
 *
 * @return false for disposable
 */
@property(nonatomic, readonly, getter=isImportant) BOOL important;

/**
 *  Task priority
 *
 * @return default is 0, smaller is faster
 */
@property(nonatomic, readonly) NSInteger priority;

@end

typedef NS_ENUM(NSInteger, STDeparturePriority) {
    STDeparturePriorityUrgent = -1,
    STDeparturePriorityNormal =  0,
    STDeparturePrioritySlower =  1,
};

NS_ASSUME_NONNULL_END
