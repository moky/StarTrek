//
//  NIOByteBuffer.h
//  StarTrek
//
//  Created by Albert Moky on 2023/3/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NIOBuffer : NSObject

@property(nonatomic, readonly) NSInteger capacity;
@property(nonatomic, readonly) NSInteger position;
@property(nonatomic, readonly) NSInteger limit;

// Creates a new buffer with the given mark, position, limit, and capacity,
// after checking invariants.
- (instancetype)initWithMark:(NSInteger)mark
                    position:(NSInteger)pos
                       limit:(NSInteger)lim
                    capacity:(NSInteger)cap;

/**
 * Sets this buffer's position.  If the mark is defined and larger than the
 * new position then it is discarded.
 *
 * @param  newPosition
 *         The new position value; must be non-negative
 *         and no larger than the current limit
 *
 * @return  This buffer
 *
 * @throws  IllegalArgumentException
 *          If the preconditions on <tt>newPosition</tt> do not hold
 */
- (NIOBuffer *)position:(NSInteger)newPosition;

/**
 * Sets this buffer's limit.  If the position is larger than the new limit
 * then it is set to the new limit.  If the mark is defined and larger than
 * the new limit then it is discarded.
 *
 * @param  newLimit
 *         The new limit value; must be non-negative
 *         and no larger than this buffer's capacity
 *
 * @return  This buffer
 *
 * @throws  IllegalArgumentException
 *          If the preconditions on <tt>newLimit</tt> do not hold
 */
- (NIOBuffer *)limit:(NSInteger)newLimit;

/**
 * Sets this buffer's mark at its position.
 *
 * @return  This buffer
 */
- (NIOBuffer *)mark;

/**
 * Resets this buffer's position to the previously-marked position.
 *
 * <p> Invoking this method neither changes nor discards the mark's
 * value. </p>
 *
 * @return  This buffer
 *
 * @throws  InvalidMarkException
 *          If the mark has not been set
 */
- (NIOBuffer *)reset;

/**
 * Clears this buffer.  The position is set to zero, the limit is set to
 * the capacity, and the mark is discarded.
 *
 * <p> Invoke this method before using a sequence of channel-read or
 * <i>put</i> operations to fill this buffer.  For example:
 *
 * <blockquote><pre>
 * buf.clear();     // Prepare buffer for reading
 * in.read(buf);    // Read data</pre></blockquote>
 *
 * <p> This method does not actually erase the data in the buffer, but it
 * is named as if it did because it will most often be used in situations
 * in which that might as well be the case. </p>
 *
 * @return  This buffer
 */
- (NIOBuffer *)clear;

/**
 * Flips this buffer.  The limit is set to the current position and then
 * the position is set to zero.  If the mark is defined then it is
 * discarded.
 *
 * <p> After a sequence of channel-read or <i>put</i> operations, invoke
 * this method to prepare for a sequence of channel-write or relative
 * <i>get</i> operations.  For example:
 *
 * <blockquote><pre>
 * buf.put(magic);    // Prepend header
 * in.read(buf);      // Read data into rest of buffer
 * buf.flip();        // Flip buffer
 * out.write(buf);    // Write header + data to channel</pre></blockquote>
 *
 * <p> This method is often used in conjunction with the {@link
 * java.nio.ByteBuffer#compact compact} method when transferring data from
 * one place to another.  </p>
 *
 * @return  This buffer
 */
- (NIOBuffer *)flip;

/**
 * Rewinds this buffer.  The position is set to zero and the mark is
 * discarded.
 *
 * <p> Invoke this method before a sequence of channel-write or <i>get</i>
 * operations, assuming that the limit has already been set
 * appropriately.  For example:
 *
 * <blockquote><pre>
 * out.write(buf);    // Write remaining data
 * buf.rewind();      // Rewind buffer
 * buf.get(array);    // Copy data into array</pre></blockquote>
 *
 * @return  This buffer
 */
- (NIOBuffer *)rewind;

/**
 * Returns the number of elements between the current position and the
 * limit.
 *
 * @return  The number of elements remaining in this buffer
 */
@property(nonatomic, readonly) NSInteger remaining;

/**
 * Tells whether there are any elements between the current position and
 * the limit.
 *
 * @return  <tt>true</tt> if, and only if, there is at least one element
 *          remaining in this buffer
 */
- (BOOL)hasRemaining;

@end

@interface NIOByteBuffer : NIOBuffer

// Creates a new buffer with the given mark, position, limit, capacity,
// backing array, and array offset
- (instancetype)initWithMark:(NSInteger)mark
                    position:(NSInteger)pos
                       limit:(NSInteger)lim
                    capacity:(NSInteger)cap
                      buffer:(NSMutableData *)hb
                      offset:(NSInteger)offset;

/**
 * Relative bulk <i>put</i> method&nbsp;&nbsp;<i>(optional operation)</i>.
 *
 * <p> This method transfers bytes into this buffer from the given
 * source array.  If there are more bytes to be copied from the array
 * than remain in this buffer, that is, if
 * <tt>length</tt>&nbsp;<tt>&gt;</tt>&nbsp;<tt>remaining()</tt>, then no
 * bytes are transferred and a {@link BufferOverflowException} is
 * thrown.
 *
 * <p> Otherwise, this method copies <tt>length</tt> bytes from the
 * given array into this buffer, starting at the given offset in the array
 * and at the current position of this buffer.  The position of this buffer
 * is then incremented by <tt>length</tt>.
 *
 * <p> In other words, an invocation of this method of the form
 * <tt>dst.put(src,&nbsp;off,&nbsp;len)</tt> has exactly the same effect as
 * the loop
 *
 * <pre>{@code
 *     for (int i = off; i < off + len; i++)
 *         dst.put(a[i]);
 * }</pre>
 *
 * except that it first checks that there is sufficient space in this
 * buffer and it is potentially much more efficient.
 *
 * @param  src
 *         The array from which bytes are to be read
 *
 * @param  offset
 *         The offset within the array of the first byte to be read;
 *         must be non-negative and no larger than <tt>array.length</tt>
 *
 * @param  length
 *         The number of bytes to be read from the given array;
 *         must be non-negative and no larger than
 *         <tt>array.length - offset</tt>
 *
 * @return  This buffer
 *
 * @throws  BufferOverflowException
 *          If there is insufficient space in this buffer
 *
 * @throws  IndexOutOfBoundsException
 *          If the preconditions on the <tt>offset</tt> and <tt>length</tt>
 *          parameters do not hold
 *
 * @throws  ReadOnlyBufferException
 *          If this buffer is read-only
 */
- (NIOByteBuffer *)putData:(NSData *)src offset:(NSInteger)offset length:(NSInteger)len;

/**
 * Relative bulk <i>put</i> method&nbsp;&nbsp;<i>(optional operation)</i>.
 *
 * <p> This method transfers the entire content of the given source
 * byte array into this buffer.  An invocation of this method of the
 * form <tt>dst.put(a)</tt> behaves in exactly the same way as the
 * invocation
 *
 * <pre>
 *     dst.put(a, 0, a.length) </pre>
 *
 * @param   src
 *          The source array
 *
 * @return  This buffer
 *
 * @throws  BufferOverflowException
 *          If there is insufficient space in this buffer
 *
 * @throws  ReadOnlyBufferException
 *          If this buffer is read-only
 */
- (NIOByteBuffer *)putData:(NSData *)src;

@end

@interface NIOByteBuffer (Creation)

+ (instancetype)bufferWithCapacity:(NSInteger)size;

@end

@interface NIOHeapByteBuffer : NIOByteBuffer

- (instancetype)initWithCapacity:(NSInteger)cap limit:(NSInteger)lim;

@end

NS_ASSUME_NONNULL_END
