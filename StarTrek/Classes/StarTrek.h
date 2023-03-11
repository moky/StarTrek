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
//  StarTrek.h
//  StarTrek
//
//  Created by Albert Moky on 2023/3/6.
//

#import <Foundation/Foundation.h>

//! Project version number for StarTrek.
FOUNDATION_EXPORT double StarTrekVersionNumber;

//! Project version string for StarTrek.
FOUNDATION_EXPORT const unsigned char StarTrekVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <StarTrek/PublicHeader.h>

#import <StarTrek/OKWeakMap.h>

// nio
#import <StarTrek/NIOException.h>
#import <StarTrek/NIOByteBuffer.h>
#import <StarTrek/NIOSocketAddress.h>
#import <StarTrek/NIOChannel.h>
#import <StarTrek/NIONetworkChannel.h>
#import <StarTrek/NIOSelectableChannel.h>
#import <StarTrek/NIOByteChannel.h>
#import <StarTrek/NIOSocketChannel.h>
#import <StarTrek/NIODatagramChannel.h>

// type
#import <StarTrek/STKeyPairMap.h>
#import <StarTrek/STHashKeyPairMap.h>
#import <StarTrek/STAddressPairMap.h>
#import <StarTrek/STAddressPairObject.h>

// net
#import <StarTrek/STChannel.h>
#import <StarTrek/STConnection.h>
#import <StarTrek/STHub.h>
#import <StarTrek/STConnectionState.h>
#import <StarTrek/STStateMachine.h>

// port
#import <StarTrek/STShip.h>
#import <StarTrek/STDocker.h>
#import <StarTrek/STGate.h>

// socket
#import <StarTrek/STChannelController.h>
#import <StarTrek/STBaseChannel.h>
#import <StarTrek/STBaseConnection.h>
#import <StarTrek/STBaseHub.h>

#import <StarTrek/STArrival.h>
#import <StarTrek/STDeparture.h>
#import <StarTrek/STDock.h>
#import <StarTrek/STStarDocker.h>
#import <StarTrek/STStarGate.h>
