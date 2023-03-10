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
//  STStarDocker.h
//  StarTrek
//
//  Created by Albert Moky on 2023/3/9.
//

#import <StarTrek/STAddressPairObject.h>
#import <StarTrek/STConnection.h>
#import <StarTrek/STDocker.h>
#import <StarTrek/STDock.h>

NS_ASSUME_NONNULL_BEGIN

@interface STDocker : STAddressPairObject <STDocker>

@property(nonatomic, weak) id<STDockerDelegate> delegate;

@property(nonatomic, weak, readonly) id<STConnection> connection;

- (instancetype)initWithConnection:(id<STConnection>)conn
NS_DESIGNATED_INITIALIZER;

// protected
- (STDock *)createDock;

@end

@interface STDocker (Shipping)  // protected

/**
 *  Get income Ship from received data
 *
 * @param data - received data
 * @return income ship carrying data package/fragment
 */
- (id<STArrival>)arrivalWithData:(NSData *)data;

/**
 *  Check income ship for responding
 *
 * @param income - income ship carrying data package/fragment/response
 * @return income ship carrying completed data package
 */
- (id<STArrival>)checkArrival:(id<STArrival>)income;

/**
 * Check received ship for completed package
 *
 * @param income - income ship carrying data package (fragment)
 * @return ship carrying completed data package
 */
- (id<STArrival>)assembleArrival:(id<STArrival>)income;

/**
 *  Check and remove linked departure ship with same SN (and page index for fragment)
 *
 * @param income - income ship with SN
 */
- (void)checkResponseInArrival:(id<STArrival>)income;

/**
 *  Get outgo ship from waiting queue
 *
 * @param now - current time
 * @return next new or timeout task
 */
- (id<STDeparture>)nextDepartureWithTime:(NSTimeInterval)now;

@end

NS_ASSUME_NONNULL_END
