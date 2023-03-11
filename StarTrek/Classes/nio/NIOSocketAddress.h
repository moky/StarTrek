//
//  NIOSocketAddress.h
//  StarTrek
//
//  Created by Albert Moky on 2023/3/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

//
//  Socket Channel
//

@protocol NIOSocketAddress <NSObject>

@property(nonatomic, readonly) NSString *host;
@property(nonatomic, readonly) UInt16 port;

@end

@interface NIOInetSocketAddress : NSObject <NIOSocketAddress>

- (instancetype)initWithHost:(NSString *)ip
                        port:(UInt16)port
NS_DESIGNATED_INITIALIZER;

@end

@interface NIOInetSocketAddress (Creation)

+ (instancetype)addressWithHost:(NSString *)ip port:(UInt16)port;

@end


NS_ASSUME_NONNULL_END
