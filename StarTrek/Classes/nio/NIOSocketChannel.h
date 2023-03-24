//
//  NIOSocketChannel.h
//  StarTrek
//
//  Created by Albert Moky on 2023/3/8.
//

#import <StarTrek/NIONetworkChannel.h>
#import <StarTrek/NIOSelectableChannel.h>
#import <StarTrek/NIOByteChannel.h>

NS_ASSUME_NONNULL_BEGIN

@interface NIOAbstractSelectableChannel : NIOSelectableChannel

@end

@protocol NIOScatteringByteChannel <NIOReadableByteChannel>

@end

@protocol NIOGatheringByteChannel <NIOWritableByteChannel>

@end

@interface NIOSocketChannel : NIOAbstractSelectableChannel <NIOByteChannel, NIOScatteringByteChannel, NIOGatheringByteChannel, NIONetworkChannel>

@property(nonatomic, readonly, getter=isBound) BOOL bound;
@property(nonatomic, readonly, getter=isConnected) BOOL connected;

- (nullable id<NIONetworkChannel>)bindLocalAddress:(id<NIOSocketAddress>)local throws:(NIOException *_Nullable*_Nullable)error;
- (nullable id<NIONetworkChannel>)connectRemoteAddress:(id<NIOSocketAddress>)remote throws:(NIOException *_Nullable*_Nullable)error;

@end

NS_ASSUME_NONNULL_END
