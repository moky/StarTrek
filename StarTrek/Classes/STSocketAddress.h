//
//  STSocketAddress.h
//  StarTrek
//
//  Created by Albert Moky on 2023/3/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface STSocketAddress : NSObject

@property(nonatomic, readonly) NSString *host;
@property(nonatomic, readonly) UInt16 port;

- (instancetype)initWithHost:(NSString *)ip
                        port:(UInt16)port
NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
