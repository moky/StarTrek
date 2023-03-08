//
//  NIOChannel.h
//  StarTrek
//
//  Created by Albert Moky on 2023/3/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol NIOChannel <NSObject>

/**
 * Tells whether or not this channel is open.
 *
 * @return <tt>true</tt> if, and only if, this channel is open
 */
@property(nonatomic, readonly, getter=isOpen) BOOL opened;

/**
 * Closes this channel.
 *
 * <p> After a channel is closed, any further attempt to invoke I/O
 * operations upon it will cause a {@link ClosedChannelException} to be
 * thrown.
 *
 * <p> If this channel is already closed then invoking this method has no
 * effect.
 *
 * <p> This method may be invoked at any time.  If some other thread has
 * already invoked it, however, then another invocation will block until
 * the first invocation is complete, after which it will return without
 * effect. </p>
 *
 * @throws  IOException  If an I/O error occurs
 */
- (void)close;

@end

NS_ASSUME_NONNULL_END
