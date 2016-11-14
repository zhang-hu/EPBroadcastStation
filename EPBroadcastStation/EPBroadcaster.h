//
//  EPBroadcaster.h
//  EPBroadcastStation
//
//  Created by 张虎 on 2016/11/11.
//  Copyright © 2016年 ZhangHu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EPBroadcaster : NSObject

@property (nonatomic, nullable, weak, readonly) id messageId;

+ (instancetype)instanceWithMessageId:(id)messageId
                       broadcastBlock:(void(^)(id))broadcastBlock;
+ (instancetype)instanceWithMessageId:(id)messageId
                       broadcastBlock:(void(^)(id))broadcastBlock
                       broadcastQueue:(nullable NSOperationQueue *)broadcastQueue;
+ (instancetype)instanceWithMessageId:(id)messageId
                       broadcastBlock:(void(^)(id))broadcastBlock
               broadcastDispatchQueue:(nullable dispatch_queue_t)broadcastDispatchQueue;

- (void)broadcastToObservers:(NSHashTable<id> *)observers;

@end

NS_ASSUME_NONNULL_END
