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

- (void)broadcastToObservers:(NSHashTable<id> *)observers
{
    typeof(self) __weak weakSelf = self;
    for (id obj in observers) {
        typeof(weakSelf) __strong strongSelf = weakSelf;
        id __weak weakObj = obj;
        if (weakSelf.queue) {
            [weakSelf.queue addOperationWithBlock:^{
                [strongSelf __broadcastToObserver:weakObj];
            }];
        } else if (weakSelf.dispatchQueue) {
            dispatch_async(weakSelf.dispatchQueue, ^{
                [strongSelf __broadcastToObserver:weakObj];
            });
        } else {
            [weakSelf __broadcastToObserver:obj];
        }
    }
}

- (void)__broadcastToObserver:(id)observer
{
    if (observer && self.broadcastBlock) {
        self.broadcastBlock(observer);
    }
}

@end

NS_ASSUME_NONNULL_END
