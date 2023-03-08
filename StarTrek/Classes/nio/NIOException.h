//
//  NIOException.h
//  StarTrek
//
//  Created by Albert Moky on 2023/3/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NIOException : NSException

@end

@interface NIOSocketException : NIOException

@end

@interface NIOClosedChannelException : NIOException

@end

@interface NIOError : NSError

- (instancetype)initWithException:(NIOException *)e;

@end

NS_ASSUME_NONNULL_END
