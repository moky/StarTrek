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
                    capacity:(NSInteger)cap
NS_DESIGNATED_INITIALIZER;

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

/**
 * Checks the current position against the limit, throwing a {@link
 * BufferUnderflowException} if it is not smaller than the limit, and then
 * increments the position.
 *
 * @return  The current position value, before it is incremented
 */
- (NSInteger)nextGetIndex;

- (NSInteger)nextGetIndex:(NSInteger)nb;

/**
 * Checks the current position against the limit, throwing a {@link
 * BufferOverflowException} if it is not smaller than the limit, and then
 * increments the position.
 *
 * @return  The current position value, before it is incremented
 */
- (NSInteger)nextPutIndex;

- (NSInteger)nextPutIndex:(NSInteger)nb;

/**
 * Checks the given index against the limit, throwing an {@link
 * IndexOutOfBoundsException} if it is not smaller than the limit
 * or is smaller than zero.
 */
- (NSInteger)checkIndex:(NSInteger)i;

- (NSInteger)checkIndex:(NSInteger)i newBounds:(NSInteger)nb;

- (NSInteger)markValue;

- (void)truncate;

- (void)discardMark;

+ (void)checkBounds:(NSInteger)offset length:(NSInteger)len size:(NSInteger)size;

@end

#pragma mark -

@interface NIOByteBuffer : NIOBuffer

// Creates a new buffer with the given mark, position, limit, capacity,
// backing array, and array offset
- (instancetype)initWithMark:(NSInteger)mark
                    position:(NSInteger)pos
                       limit:(NSInteger)lim
                    capacity:(NSInteger)cap
                        data:(NSData *)hb
                      offset:(NSInteger)offset
NS_DESIGNATED_INITIALIZER;

/**
 * Relative <i>get</i> method.  Reads the byte at this buffer's
 * current position, and then increments the position.
 *
 * @return  The byte at the buffer's current position
 *
 * @throws  BufferUnderflowException
 *          If the buffer's current position is not smaller than its limit
 */
- (Byte)getByte;

/**
 * Relative <i>put</i> method&nbsp;&nbsp;<i>(optional operation)</i>.
 *
 * <p> Writes the given byte into this buffer at the current
 * position, and then increments the position. </p>
 *
 * @param  b
 *         The byte to be written
 *
 * @return  This buffer
 *
 * @throws  BufferOverflowException
 *          If this buffer's current position is not smaller than its limit
 *
 * @throws  ReadOnlyBufferException
 *          If this buffer is read-only
 */
- (NIOByteBuffer *)putByte:(Byte)b;

/**
 * Absolute <i>get</i> method.  Reads the byte at the given
 * index.
 *
 * @param  index
 *         The index from which the byte will be read
 *
 * @return  The byte at the given index
 *
 * @throws  IndexOutOfBoundsException
 *          If <tt>index</tt> is negative
 *          or not smaller than the buffer's limit
 */
- (Byte)getByteWithIndex:(NSInteger)index;

/**
 * Absolute <i>put</i> method&nbsp;&nbsp;<i>(optional operation)</i>.
 *
 * <p> Writes the given byte into this buffer at the given
 * index. </p>
 *
 * @param  index
 *         The index at which the byte will be written
 *
 * @param  b
 *         The byte value to be written
 *
 * @return  This buffer
 *
 * @throws  IndexOutOfBoundsException
 *          If <tt>index</tt> is negative
 *          or not smaller than the buffer's limit
 *
 * @throws  ReadOnlyBufferException
 *          If this buffer is read-only
 */
- (NIOByteBuffer *)putByte:(Byte)b withIndex:(NSInteger)index;

/**
 * Relative bulk <i>get</i> method.
 *
 * <p> This method transfers bytes from this buffer into the given
 * destination array.  If there are fewer bytes remaining in the
 * buffer than are required to satisfy the request, that is, if
 * <tt>length</tt>&nbsp;<tt>&gt;</tt>&nbsp;<tt>remaining()</tt>, then no
 * bytes are transferred and a {@link BufferUnderflowException} is
 * thrown.
 *
 * <p> Otherwise, this method copies <tt>length</tt> bytes from this
 * buffer into the given array, starting at the current position of this
 * buffer and at the given offset in the array.  The position of this
 * buffer is then incremented by <tt>length</tt>.
 *
 * <p> In other words, an invocation of this method of the form
 * <tt>src.get(dst,&nbsp;off,&nbsp;len)</tt> has exactly the same effect as
 * the loop
 *
 * <pre>{@code
 *     for (int i = off; i < off + len; i++)
 *         dst[i] = src.get():
 * }</pre>
 *
 * except that it first checks that there are sufficient bytes in
 * this buffer and it is potentially much more efficient.
 *
 * @param  dst
 *         The array into which bytes are to be written
 *
 * @param  offset
 *         The offset within the array of the first byte to be
 *         written; must be non-negative and no larger than
 *         <tt>dst.length</tt>
 *
 * @param  length
 *         The maximum number of bytes to be written to the given
 *         array; must be non-negative and no larger than
 *         <tt>dst.length - offset</tt>
 *
 * @return  This buffer
 *
 * @throws  BufferUnderflowException
 *          If there are fewer than <tt>length</tt> bytes
 *          remaining in this buffer
 *
 * @throws  IndexOutOfBoundsException
 *          If the preconditions on the <tt>offset</tt> and <tt>length</tt>
 *          parameters do not hold
 */
- (NIOByteBuffer *)getData:(NSMutableData *)dst offset:(NSInteger)offset length:(NSInteger)len;

/**
 * Relative bulk <i>get</i> method.
 *
 * <p> This method transfers bytes from this buffer into the given
 * destination array.  An invocation of this method of the form
 * <tt>src.get(a)</tt> behaves in exactly the same way as the invocation
 *
 * <pre>
 *     src.get(a, 0, a.length) </pre>
 *
 * @param   dst
 *          The destination array
 *
 * @return  This buffer
 *
 * @throws  BufferUnderflowException
 *          If there are fewer than <tt>length</tt> bytes
 *          remaining in this buffer
 */
- (NIOByteBuffer *)getData:(NSMutableData *)dst;

/**
 * Relative bulk <i>put</i> method&nbsp;&nbsp;<i>(optional operation)</i>.
 *
 * <p> This method transfers the bytes remaining in the given source
 * buffer into this buffer.  If there are more bytes remaining in the
 * source buffer than in this buffer, that is, if
 * <tt>src.remaining()</tt>&nbsp;<tt>&gt;</tt>&nbsp;<tt>remaining()</tt>,
 * then no bytes are transferred and a {@link
 * BufferOverflowException} is thrown.
 *
 * <p> Otherwise, this method copies
 * <i>n</i>&nbsp;=&nbsp;<tt>src.remaining()</tt> bytes from the given
 * buffer into this buffer, starting at each buffer's current position.
 * The positions of both buffers are then incremented by <i>n</i>.
 *
 * <p> In other words, an invocation of this method of the form
 * <tt>dst.put(src)</tt> has exactly the same effect as the loop
 *
 * <pre>
 *     while (src.hasRemaining())
 *         dst.put(src.get()); </pre>
 *
 * except that it first checks that there is sufficient space in this
 * buffer and it is potentially much more efficient.
 *
 * @param  src
 *         The source buffer from which bytes are to be read;
 *         must not be this buffer
 *
 * @return  This buffer
 *
 * @throws  BufferOverflowException
 *          If there is insufficient space in this buffer
 *          for the remaining bytes in the source buffer
 *
 * @throws  IllegalArgumentException
 *          If the source buffer is this buffer
 *
 * @throws  ReadOnlyBufferException
 *          If this buffer is read-only
 */
- (NIOByteBuffer *)putBuffer:(NIOByteBuffer *)src;

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

/**
 * Allocates a new byte buffer.
 *
 * <p> The new buffer's position will be zero, its limit will be its
 * capacity, its mark will be undefined, and each of its elements will be
 * initialized to zero.  It will have a {@link #array backing array},
 * and its {@link #arrayOffset array offset} will be zero.
 *
 * @param  capacity
 *         The new buffer's capacity, in bytes
 *
 * @return  The new byte buffer
 *
 * @throws  IllegalArgumentException
 *          If the <tt>capacity</tt> is a negative integer
 */
+ (instancetype)bufferWithCapacity:(NSInteger)capacity;

/**
 * Wraps a byte array into a buffer.
 *
 * <p> The new buffer will be backed by the given byte array;
 * that is, modifications to the buffer will cause the array to be modified
 * and vice versa.  The new buffer's capacity will be
 * <tt>array.length</tt>, its position will be <tt>offset</tt>, its limit
 * will be <tt>offset + length</tt>, and its mark will be undefined.  Its
 * {@link #array backing array} will be the given array, and
 * its {@link #arrayOffset array offset} will be zero.  </p>
 *
 * @param  array
 *         The array that will back the new buffer
 *
 * @param  offset
 *         The offset of the subarray to be used; must be non-negative and
 *         no larger than <tt>array.length</tt>.  The new buffer's position
 *         will be set to this value.
 *
 * @param  length
 *         The length of the subarray to be used;
 *         must be non-negative and no larger than
 *         <tt>array.length - offset</tt>.
 *         The new buffer's limit will be set to <tt>offset + length</tt>.
 *
 * @return  The new byte buffer
 *
 * @throws  IndexOutOfBoundsException
 *          If the preconditions on the <tt>offset</tt> and <tt>length</tt>
 *          parameters do not hold
 */
+ (instancetype)bufferWithData:(NSData *)array offset:(NSInteger)offset length:(NSInteger)len;

/**
 * Wraps a byte array into a buffer.
 *
 * <p> The new buffer will be backed by the given byte array;
 * that is, modifications to the buffer will cause the array to be modified
 * and vice versa.  The new buffer's capacity and limit will be
 * <tt>array.length</tt>, its position will be zero, and its mark will be
 * undefined.  Its {@link #array backing array} will be the
 * given array, and its {@link #arrayOffset array offset>} will
 * be zero.  </p>
 *
 * @param  array
 *         The array that will back this buffer
 *
 * @return  The new byte buffer
 */
+ (instancetype)bufferWithData:(NSData *)array;

@end

#pragma mark -



@interface NIOHeapByteBuffer : NIOByteBuffer

- (instancetype)initWithCapacity:(NSInteger)cap
                           limit:(NSInteger)lim;

- (instancetype)initWithData:(NSData *)buf
                      offset:(NSInteger)offset
                      length:(NSInteger)len;

- (instancetype)initWithData:(NSData *)buf
                        mark:(NSInteger)mark
                    position:(NSInteger)pos
                       limit:(NSInteger)lim
                    capacity:(NSInteger)cap
                      offset:(NSInteger)offset;

// protected
- (NSInteger)ix:(NSInteger)i;

@end

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Copies an array from the specified source array, beginning at the
 * specified position, to the specified position of the destination array.
 * A subsequence of array components are copied from the source
 * array referenced by <code>src</code> to the destination array
 * referenced by <code>dest</code>. The number of components copied is
 * equal to the <code>length</code> argument. The components at
 * positions <code>srcPos</code> through
 * <code>srcPos+length-1</code> in the source array are copied into
 * positions <code>destPos</code> through
 * <code>destPos+length-1</code>, respectively, of the destination
 * array.
 * <p>
 * If the <code>src</code> and <code>dest</code> arguments refer to the
 * same array object, then the copying is performed as if the
 * components at positions <code>srcPos</code> through
 * <code>srcPos+length-1</code> were first copied to a temporary
 * array with <code>length</code> components and then the contents of
 * the temporary array were copied into positions
 * <code>destPos</code> through <code>destPos+length-1</code> of the
 * destination array.
 * <p>
 * If <code>dest</code> is <code>null</code>, then a
 * <code>NullPointerException</code> is thrown.
 * <p>
 * If <code>src</code> is <code>null</code>, then a
 * <code>NullPointerException</code> is thrown and the destination
 * array is not modified.
 * <p>
 * Otherwise, if any of the following is true, an
 * <code>ArrayStoreException</code> is thrown and the destination is
 * not modified:
 * <ul>
 * <li>The <code>src</code> argument refers to an object that is not an
 *     array.
 * <li>The <code>dest</code> argument refers to an object that is not an
 *     array.
 * <li>The <code>src</code> argument and <code>dest</code> argument refer
 *     to arrays whose component types are different primitive types.
 * <li>The <code>src</code> argument refers to an array with a primitive
 *    component type and the <code>dest</code> argument refers to an array
 *     with a reference component type.
 * <li>The <code>src</code> argument refers to an array with a reference
 *    component type and the <code>dest</code> argument refers to an array
 *     with a primitive component type.
 * </ul>
 * <p>
 * Otherwise, if any of the following is true, an
 * <code>IndexOutOfBoundsException</code> is
 * thrown and the destination is not modified:
 * <ul>
 * <li>The <code>srcPos</code> argument is negative.
 * <li>The <code>destPos</code> argument is negative.
 * <li>The <code>length</code> argument is negative.
 * <li><code>srcPos+length</code> is greater than
 *     <code>src.length</code>, the length of the source array.
 * <li><code>destPos+length</code> is greater than
 *     <code>dest.length</code>, the length of the destination array.
 * </ul>
 * <p>
 * Otherwise, if any actual component of the source array from
 * position <code>srcPos</code> through
 * <code>srcPos+length-1</code> cannot be converted to the component
 * type of the destination array by assignment conversion, an
 * <code>ArrayStoreException</code> is thrown. In this case, let
 * <b><i>k</i></b> be the smallest nonnegative integer less than
 * length such that <code>src[srcPos+</code><i>k</i><code>]</code>
 * cannot be converted to the component type of the destination
 * array; when the exception is thrown, source array components from
 * positions <code>srcPos</code> through
 * <code>srcPos+</code><i>k</i><code>-1</code>
 * will already have been copied to destination array positions
 * <code>destPos</code> through
 * <code>destPos+</code><I>k</I><code>-1</code> and no other
 * positions of the destination array will have been modified.
 * (Because of the restrictions already itemized, this
 * paragraph effectively applies only to the situation where both
 * arrays have component types that are reference types.)
 *
 * @param      src      the source array.
 * @param      srcPos   starting position in the source array.
 * @param      dest     the destination array.
 * @param      destPos  starting position in the destination data.
 * @param      length   the number of array elements to be copied.
 * @exception  IndexOutOfBoundsException  if copying would cause
 *               access of data outside array bounds.
 * @exception  ArrayStoreException  if an element in the <code>src</code>
 *               array could not be stored into the <code>dest</code> array
 *               because of a type mismatch.
 * @exception  NullPointerException if either <code>src</code> or
 *               <code>dest</code> is <code>null</code>.
 */
void NIOSystemArrayCopy(const unsigned char *src, NSInteger srcPos, unsigned char *dest, NSInteger destPos, NSInteger length);

#ifdef __cplusplus
} /* end of extern "C" */
#endif

NS_ASSUME_NONNULL_END
