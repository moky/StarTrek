//
//  NIOByteBuffer.m
//  StarTrek
//
//  Created by Albert Moky on 2023/3/8.
//

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

@end

#pragma mark -

@interface NIOByteBuffer () {
    
    NSInteger _offset;
}

@property(nonatomic, strong) NSMutableData *hb;

@end

@implementation NIOByteBuffer

- (instancetype)initWithMark:(NSInteger)mark
                    position:(NSInteger)pos
                       limit:(NSInteger)lim
                    capacity:(NSInteger)cap
                      buffer:(NSMutableData *)hb
                      offset:(NSInteger)offset {
    if (self = [super initWithMark:mark position:pos limit:lim capacity:cap]) {
        self.hb = hb;
        _offset = offset;
    }
    return self;
}

@end

@implementation NIOByteBuffer (Creation)

+ (instancetype)bufferWithCapacity:(NSInteger)size {
    NSAssert(size >= 0, @"capacity error: %ld", (long)size);
    return [[NIOHeapByteBuffer alloc] initWithCapacity:size limit:size];
}

@end

@implementation NIOHeapByteBuffer

- (instancetype)initWithCapacity:(NSInteger)cap limit:(NSInteger)lim {
    NSMutableData *hb = [[NSMutableData alloc] initWithCapacity:cap];
    if (self = [super initWithMark:-1
                          position:0
                             limit:lim
                          capacity:cap
                            buffer:hb
                            offset:0]) {
        //
    }
    return self;
}

@end
