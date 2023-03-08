//
//  NIODatagramChannel.h
//  StarTrek
//
//  Created by Albert Moky on 2023/3/8.
//

#import <StarTrek/NIONetworkChannel.h>
#import <StarTrek/NIOByteChannel.h>
#import <StarTrek/NIOSocketChannel.h>

NS_ASSUME_NONNULL_BEGIN

@protocol NIOMulticastChannel <NIONetworkChannel>

@end

@interface NIODatagramChannel : NIOAbstractSelectableChannel <NIOByteChannel, NIOScatteringByteChannel, NIOGatheringByteChannel, NIOMulticastChannel>

@property(nonatomic, readonly, getter=isBound) BOOL bound;
@property(nonatomic, readonly, getter=isConnected) BOOL connected;

- (nullable id<NIONetworkChannel>)bindLocalAddress:(id<NIOSocketAddress>)local;
- (nullable id<NIONetworkChannel>)connectRemoteAddress:(id<NIOSocketAddress>)remote;

- (nullable id<NIOByteChannel>)disconnect;

@end

NS_ASSUME_NONNULL_END
