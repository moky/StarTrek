//
//  NIOByteBuffer.m
//  StarTrek
//
//  Created by Albert Moky on 2023/3/8.
//

#import "NIOException.h"

#import "NIOByteBuffer.h"

@interface NIOBuffer () {
    
    // Invariants: mark <= position <= limit <= capacity
    NSInteger _mark;
    NSInteger _position;
    NSInteger _limit;
    NSInteger _capacity;
}

@end

@implementation NIOBuffer

- (instancetype)init {
    NSAssert(false, @"DON'T call me");
    return [self initWithMark:-1 position:0 limit:0 capacity:0];
}

/* designated initializer */
- (instancetype)initWithMark:(NSInteger)mark
                    position:(NSInteger)pos
                       limit:(NSInteger)lim
                    capacity:(NSInteger)cap {
    NSAssert(cap >= 0, @"Negative capacity: %ld", cap);
    if (self = [super init]) {
        _mark = -1;
        _position = 0;
        _capacity = cap;
        [self limit:lim];
        [self position:pos];
        if (mark >= 0) {
            if (mark > pos) {
                NSAssert(false, @"mark > position: (%ld > %ld)", mark, pos);
            } else {
                _mark = mark;
            }
        }
    }
    return self;
}

// Override
- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ capacity=%ld position=%ld limit=%ld mark=%ld />", [self class], _capacity, _position, _limit, _mark];
}

// Override
- (NSString *)debugDescription {
    return [self description];
}

- (NSInteger)capacity {
    return _capacity;
}

- (NSInteger)position {
    return _position;
}

- (NIOBuffer *)position:(NSInteger)newPosition {
    if ((newPosition > _limit) || (newPosition < 0)) {
        NSAssert(false, @"new position error: %ld, limit: %ld", newPosition, _limit);
        return nil;
    } else {
        _position = newPosition;
        if (_mark > _position) {
            _mark = -1;
        }
        return self;
    }
}

- (NSInteger)limit {
    return _limit;
}

- (NIOBuffer *)limit:(NSInteger)newLimit {
    if ((newLimit > _capacity) || (newLimit < 0)) {
        NSAssert(false, @"new limit error: %ld, capacity: %ld", newLimit, _capacity);
        return nil;
    } else {
        _limit = newLimit;
        if (_position > _limit) {
            _position = _limit;
        }
        if (_mark > _limit) {
            _mark = -1;
        }
        return self;
    }
}

- (NIOBuffer *)mark {
    _mark = _position;
    return self;
}

- (NIOBuffer *)reset {
    NSInteger m = _mark;
    if (m < 0) {
        NSAssert(false, @"invalid mark: %ld", m);
        return nil;
    } else {
        _position = m;
        return self;
    }
}

- (NIOBuffer *)clear {
    _position = 0;
    _limit = _capacity;
    _mark = -1;
    return self;
}

- (NIOBuffer *)flip {
    _limit = _position;
    _position = 0;
    _mark = -1;
    return self;
}

- (NIOBuffer *)rewind {
    _position = 0;
    _mark = -1;
    return self;
}

- (NSInteger)remaining {
    return _limit - _position;
}

- (BOOL)hasRemaining {
    return _position < _limit;
}

- (NSInteger)nextGetIndex {
    if (_position >= _limit) {
        @throw [[NIOBufferUnderflowException alloc] init];
    }
    return _position++;
}

- (NSInteger)nextGetIndex:(NSInteger)nb {
    if (_limit - _position < nb) {
        @throw [[NIOBufferUnderflowException alloc] init];
    }
    NSInteger p = _position;
    _position += nb;
    return p;
}

- (NSInteger)nextPutIndex {
    if (_position >= _limit) {
        @throw [[NIOBufferUnderflowException alloc] init];
    }
    return _position++;
}

- (NSInteger)nextPutIndex:(NSInteger)nb {
    if (_limit - _position < nb) {
        @throw [[NIOBufferUnderflowException alloc] init];
    }
    NSInteger p = _position;
    _position += nb;
    return p;
}

- (NSInteger)checkIndex:(NSInteger)i {
    if ((i < 0) || (i >= _limit)) {
        @throw [[NIOIndexOutOfBoundsException alloc] init];
    }
    return i;
}

- (NSInteger)checkIndex:(NSInteger)i newBounds:(NSInteger)nb {
    if ((i < 0) || (nb > _limit - i)) {
        @throw [[NIOIndexOutOfBoundsException alloc] init];
    }
    return i;
}

- (NSInteger)markValue {
    return _mark;
}

- (void)truncate {
    _mark = -1;
    _position = 0;
    _limit = 0;
    _capacity = 0;
}

- (void)discardMark {
    _mark = -1;
}

+ (void)checkBounds:(NSInteger)off length:(NSInteger)len size:(NSInteger)size {
    if ((off | len | (off + len) | (size - (off + len))) < 0) {
        @throw [[NIOIndexOutOfBoundsException alloc] init];
    }
}

@end

#pragma mark -

@interface NIOByteBuffer ()

@property(nonatomic, strong) NSMutableData *hb;

@property(nonatomic, assign) NSInteger offset;

@end

@implementation NIOByteBuffer

- (instancetype)initWithMark:(NSInteger)mark
                    position:(NSInteger)pos
                       limit:(NSInteger)lim
                    capacity:(NSInteger)cap {
    NSAssert(false, @"DON'T call me");
    NSMutableData *hb = nil;//[[NSMutableData alloc] initWithCapacity:cap];
    return [self initWithMark:mark position:pos limit:lim capacity:cap data:hb offset:0];
}

/* designated initializer */
- (instancetype)initWithMark:(NSInteger)mark
                    position:(NSInteger)pos
                       limit:(NSInteger)lim
                    capacity:(NSInteger)cap
                        data:(NSMutableData *)hb
                      offset:(NSInteger)offset {
    if (self = [super initWithMark:mark position:pos limit:lim capacity:cap]) {
        if ([hb isKindOfClass:[NSMutableData class]]) {
            self.hb = hb;
        } else if ([hb isKindOfClass:[NSData class]]) {
            self.hb = [hb mutableCopy];
        } else {
            NSAssert(hb == nil, @"data error: %@", hb);
            self.hb = nil;
        }
        self.hb = hb;
        self.offset = offset;
    }
    return self;
}

- (Byte)getByte {
    NSAssert(false, @"override me!");
    return 0;
}

- (NIOByteBuffer *)putByte:(Byte)b {
    NSAssert(false, @"override me!");
    return nil;
}

- (Byte)getByteWithIndex:(NSInteger)index {
    NSAssert(false, @"override me!");
    return 0;
}

- (NIOByteBuffer *)putByte:(Byte)b withIndex:(NSInteger)index {
    NSAssert(false, @"override me!");
    return nil;
}

- (NIOByteBuffer *)getData:(NSMutableData *)dst offset:(NSInteger)offset length:(NSInteger)len {
    [NIOBuffer checkBounds:offset length:len size:dst.length];
    if (len > [self remaining]) {
        @throw [[NIOBufferUnderflowException alloc] init];
    }
    unsigned char *bytes = dst.mutableBytes;
    NSInteger end = offset + len;
    for (NSInteger i = offset; i < end; ++i) {
        bytes[i] = [self getByte];
    }
    return self;
}

- (NIOByteBuffer *)getData:(NSMutableData *)dst {
    return [self getData:dst offset:0 length:dst.length];
}

- (NIOByteBuffer *)putBuffer:(NIOByteBuffer *)src {
    if (src == self) {
        @throw [[NIOIllegalArgumentException alloc] init];
    }
    NSInteger n = [src remaining];
    if (n > [self remaining]) {
        @throw [[NIOBufferOverflowException alloc] init];
    }
    for (NSInteger i = 0; i < n; ++i) {
        [self putByte:[src getByte]];
    }
    return self;
}

- (NIOByteBuffer *)putData:(NSData *)src offset:(NSInteger)offset length:(NSInteger)len {
    [NIOBuffer checkBounds:offset length:len size:src.length];
    if (len > [self remaining]) {
        @throw [[NIOBufferOverflowException alloc] init];
    }
    const unsigned char *bytes = src.bytes;
    NSInteger end = offset + len;
    for (NSInteger i = offset; i < end; ++i) {
        [self putByte:bytes[i]];
    }
    return self;
}

- (NIOByteBuffer *)putData:(NSData *)src {
    return [self putData:src offset:0 length:src.length];
}

@end

@implementation NIOByteBuffer (Creation)

+ (instancetype)bufferWithCapacity:(NSInteger)size {
    if (size < 0) {
        @throw [[NIOIllegalArgumentException alloc] init];
    }
    NSAssert(size >= 0, @"capacity error: %ld", (long)size);
    return [[NIOHeapByteBuffer alloc] initWithCapacity:size limit:size];
}

+ (instancetype)bufferWithData:(NSData *)array
                        offset:(NSInteger)offset
                        length:(NSInteger)len {
    @try {
        return [[NIOHeapByteBuffer alloc] initWithData:array offset:offset length:len];
    } @catch (NIOIllegalArgumentException *e) {
        @throw [[NIOIndexOutOfBoundsException alloc] init];
    } @finally {
    }
}

+ (instancetype)bufferWithData:(NSData *)array {
    return [self bufferWithData:array offset:0 length:array.length];
}

@end

#pragma mark -

@implementation NIOHeapByteBuffer

- (instancetype)initWithCapacity:(NSInteger)cap
                           limit:(NSInteger)lim {
    NSMutableData *hb = [[NSMutableData alloc] initWithCapacity:cap];
    if (self = [super initWithMark:-1
                          position:0
                             limit:lim
                          capacity:cap
                              data:hb
                            offset:0]) {
        //
    }
    return self;
}

- (instancetype)initWithData:(NSData *)buf
                      offset:(NSInteger)offset
                      length:(NSInteger)len {
    if (self = [super initWithMark:-1
                          position:offset
                             limit:offset+len
                          capacity:buf.length
                              data:buf
                            offset:0]) {
        //
    }
    return self;
}

- (instancetype)initWithData:(NSData *)buf
                        mark:(NSInteger)mark
                    position:(NSInteger)pos
                       limit:(NSInteger)lim
                    capacity:(NSInteger)cap
                      offset:(NSInteger)offset {
    if (self = [super initWithMark:mark
                          position:pos
                             limit:lim
                          capacity:cap
                              data:buf
                            offset:offset]) {
        //
    }
    return self;
}

- (NSInteger)ix:(NSInteger)i {
    return i + self.offset;
}

- (Byte)getByte {
    const unsigned char *bytes = self.hb.bytes;
    NSInteger idx = [self ix:[self nextGetIndex]];
    return bytes[idx];
}

- (Byte)getByteWithIndex:(NSInteger)index {
    const unsigned char *bytes = self.hb.bytes;
    NSInteger idx = [self ix:[self checkIndex:index]];
    return bytes[idx];
}

// Override
- (NIOByteBuffer *)getData:(NSMutableData *)dst
                    offset:(NSInteger)offset
                    length:(NSInteger)len {
    [NIOBuffer checkBounds:offset length:len size:dst.length];
    if (len > [self remaining]) {
        @throw [[NIOBufferUnderflowException alloc] init];
    }
    const unsigned char *source = self.hb.bytes;
    unsigned char *destination = dst.mutableBytes;
    NSInteger idx = [self ix:[self position]];
    NIOSystemArrayCopy(source, idx, destination, offset, len);
    NSInteger pos = [self position] + len;
    [self position:pos];
    return self;
}

- (NIOByteBuffer *)putByte:(Byte)x {
    unsigned char *destination = self.hb.mutableBytes;
    NSInteger idx = [self ix:[self nextPutIndex]];
    destination[idx] = x;
    return self;
}

- (NIOByteBuffer *)putByte:(Byte)x withIndex:(NSInteger)index {
    unsigned char *destination = self.hb.mutableBytes;
    NSInteger idx = [self ix:[self checkIndex:index]];
    destination[idx] = x;
    return self;
}

// Override
- (NIOByteBuffer *)putData:(NSData *)src offset:(NSInteger)offset length:(NSInteger)len {
    [NIOBuffer checkBounds:offset length:len size:src.length];
    if (len > [self remaining]) {
        @throw [[NIOBufferOverflowException alloc] init];
    }
    const unsigned char *source = src.bytes;
    unsigned char *destination = self.hb.mutableBytes;
    NSInteger idx = [self ix:[self position]];
    NIOSystemArrayCopy(source, offset, destination, idx, len);
    NSInteger pos = [self position] + len;
    [self position:pos];
    return self;
}

// Override
- (NIOByteBuffer *)putBuffer:(NIOByteBuffer *)src {
    if ([src isKindOfClass:[NIOHeapByteBuffer class]]) {
        if (src == self) {
            @throw [[NIOIllegalArgumentException alloc] init];
        }
        NIOHeapByteBuffer *sb = (NIOHeapByteBuffer *)src;
        NSInteger n = [sb remaining];
        if (n > [self remaining]) {
            @throw [[NIOBufferOverflowException alloc] init];
        }
        const unsigned char *source = sb.hb.bytes;
        unsigned char *destination = self.hb.mutableBytes;
        NSInteger srcPos = [sb ix:[sb position]];
        NSInteger destPos = [self ix:[self position]];
        NIOSystemArrayCopy(source, srcPos, destination, destPos, n);
        [sb position:(sb.position + n)];
        [self position:(self.position + n)];
    } else {
        [super putBuffer:src];
    }
    return self;
}

@end

void NIOSystemArrayCopy(const unsigned char *src,
                        NSInteger srcPos,
                        unsigned char *dest,
                        NSInteger destPos,
                        NSInteger length) {
    for (NSInteger i = 0; i < length; ++i) {
        dest[destPos + i] = src[srcPos + i];
    }
}
