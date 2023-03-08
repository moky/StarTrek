//
//  NIOSelectableChannel.h
//  StarTrek
//
//  Created by Albert Moky on 2023/3/8.
//

#import <StarTrek/NIOChannel.h>

NS_ASSUME_NONNULL_BEGIN

@protocol NIOInterruptibleChannel <NIOChannel>

/**
 * Closes this channel.
 *
 * <p> Any thread currently blocked in an I/O operation upon this channel
 * will receive an {@link AsynchronousCloseException}.
 *
 * <p> This method otherwise behaves exactly as specified by the {@link
 * Channel#close Channel} interface.  </p>
 *
 * @throws  IOException  If an I/O error occurs
 */
- (void)close;

@end

@interface NIOAbstractInterruptibleChannel : NSObject <NIOChannel, NIOInterruptibleChannel>

@end

@interface NIOSelectableChannel : NIOAbstractInterruptibleChannel <NIOChannel>

/**
 * Adjusts this channel's blocking mode.
 *
 * <p> If this channel is registered with one or more selectors then an
 * attempt to place it into blocking mode will cause an {@link
 * IllegalBlockingModeException} to be thrown.
 *
 * <p> This method may be invoked at any time.  The new blocking mode will
 * only affect I/O operations that are initiated after this method returns.
 * For some implementations this may require blocking until all pending I/O
 * operations are complete.
 *
 * <p> If this method is invoked while another invocation of this method or
 * of the {@link #register(Selector, int) register} method is in progress
 * then it will first block until the other operation is complete. </p>
 *
 * @param  block  If <tt>true</tt> then this channel will be placed in
 *                blocking mode; if <tt>false</tt> then it will be placed
 *                non-blocking mode
 *
 * @return  This selectable channel
 *
 * @throws  ClosedChannelException
 *          If this channel is closed
 *
 * @throws  IllegalBlockingModeException
 *          If <tt>block</tt> is <tt>true</tt> and this channel is
 *          registered with one or more selectors
 *
 * @throws IOException
 *         If an I/O error occurs
 */
- (nullable NIOSelectableChannel *)configureBlocking:(BOOL)blocking;

/**
 * Tells whether or not every I/O operation on this channel will block
 * until it completes.  A newly-created channel is always in blocking mode.
 *
 * <p> If this channel is closed then the value returned by this method is
 * not specified. </p>
 *
 * @return <tt>true</tt> if, and only if, this channel is in blocking mode
 */
@property(nonatomic, readonly, getter=isBlocking) BOOL blocking;

@end

NS_ASSUME_NONNULL_END
