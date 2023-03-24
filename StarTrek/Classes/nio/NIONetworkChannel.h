//
//  NIONetworkChannel.h
//  StarTrek
//
//  Created by Albert Moky on 2023/3/8.
//

#import <StarTrek/NIOException.h>
#import <StarTrek/NIOSocketAddress.h>
#import <StarTrek/NIOChannel.h>

NS_ASSUME_NONNULL_BEGIN

@protocol NIONetworkChannel <NIOChannel>

- (nullable id<NIONetworkChannel>)bindLocalAddress:(id<NIOSocketAddress>)local throws:(NIOException *_Nullable*_Nullable)error;

@property(nonatomic, readonly) id<NIOSocketAddress> localAddress;

@end

NS_ASSUME_NONNULL_END
