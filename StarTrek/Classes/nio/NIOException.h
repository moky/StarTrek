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

#pragma mark Runtime

@interface NIORuntimeException : NIOException

@end

@interface NIOIllegalArgumentException : NIORuntimeException

@end

@interface NIOBufferOverflowException : NIORuntimeException

@end

@interface NIOBufferUnderflowException : NIORuntimeException

@end

@interface NIOIndexOutOfBoundsException : NIORuntimeException

@end

#pragma mark Socket

@interface NIOSocketException : NIOException

@end

@interface NIOClosedChannelException : NIOException

@end

#pragma mark -

@interface NIOError : NSError

@property(nonatomic, strong) NIOException *exception;

- (instancetype)initWithException:(NIOException *)e;

@end

NS_ASSUME_NONNULL_END
