//
//  EPBroadcaster.m
//  EPBroadcastStation
//
//  Created by 张虎 on 2016/11/11.
//  Copyright © 2016年 ZhangHu. All rights reserved.
//

#import "EPBroadcaster.h"

NS_ASSUME_NONNULL_BEGIN

@interface EPBroadcaster ()

@property (nonatomic, nullable, weak) id messageId;
@property (nonatomic, copy) void(^broadcastBlock)(id observer);
@property (nonatomic, nullable) NSOperationQueue *queue;
@property (nonatomic, nullable) dispatch_queue_t dispatchQueue;

@end

@implementation EPBroadcaster

+ (instancetype)instanceWithMessageId:(id)messageId
                       broadcastBlock:(void(^)(id))broadcastBlock
{
    EPBroadcaster *instance = [self new];
    instance.messageId = messageId;
    instance.broadcastBlock = broadcastBlock;
    return instance;
}

+ (instancetype)instanceWithMessageId:(id)messageId
                       broadcastBlock:(void(^)(id))broadcastBlock
                       broadcastQueue:(nullable NSOperationQueue *)broadcastQueue
{
    EPBroadcaster *instance = [self new];
    instance.messageId = messageId;
    instance.broadcastBlock = broadcastBlock;
    instance.queue = broadcastQueue;
    return instance;
}

+ (instancetype)instanceWithMessageId:(id)messageId
                       broadcastBlock:(void(^)(id))broadcastBlock
               broadcastDispatchQueue:(nullable dispatch_queue_t)broadcastDispatchQueue
{
    EPBroadcaster *instance = [self new];
    instance.messageId = messageId;
    instance.broadcastBlock = broadcastBlock;
    instance.dispatchQueue = broadcastDispatchQueue;
    return instance;
}

- (void)broadcastToObservers:(NSArray<id> *)observers
{
    typeof(self) __weak weakSelf = self;
    [observers.copy enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        typeof(weakSelf) __strong strongSelf = weakSelf;
        if (weakSelf.queue) {
            [weakSelf.queue addOperationWithBlock:^{
                strongSelf.broadcastBlock(obj);
            }];
        } else if (weakSelf.dispatchQueue) {
            dispatch_async(weakSelf.dispatchQueue, ^{
                strongSelf.broadcastBlock(obj);
            });
        } else {
            weakSelf.broadcastBlock(obj);
        }
    }];
}

@end

NS_ASSUME_NONNULL_END
