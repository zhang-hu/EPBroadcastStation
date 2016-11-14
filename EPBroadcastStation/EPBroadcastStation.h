//
//  EPBroadcastStation.h
//  EPBroadcastStation
//
//  Created by 张虎 on 2016/11/11.
//  Copyright © 2016年 ZhangHu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, EPBroadcastStyle) {
    EPBroadcastStyleWhenIdle = 1,
    EPBroadcastStyleASAP,
    EPBroadcastStyleNow
};

typedef NS_OPTIONS(NSUInteger, EPMessageCoalescing) {
    EPMessageNoCoalescing = 0,
    EPMessageCoalescingOnMessageId = 1 << 0
    //TODO: v0.2.0
};


/**
 * (The 'EP' is the abb. of 'Empty Prefix' :))
 * @author  张虎
 * @version  0.1.0
 */
@interface EPBroadcastStation : NSObject

#if FOUNDATION_SWIFT_SDK_EPOCH_AT_LEAST(8)
@property (class, strong, readonly) EPBroadcastStation *defaultStation;
#endif

- (void)addObserver:(id)observer forMessageId:(nullable id)messageId;
- (void)removeObserver:(id)observer forMessageId:(nullable id)messageId;
- (void)removeObserver:(id)observer;

- (void)broadcastMessageWithBlock:(void(^)(id _Nonnull observer))block
          toObserversForMessageId:(nullable id)messageId
                   broadcastStyle:(EPBroadcastStyle)broadcastStyle
                      coalescMask:(EPMessageCoalescing)coalescMask;

- (void)broadcastMessageWithBlock:(void(^)(id _Nonnull observer))block
                          inQueue:(nullable NSOperationQueue *)queue
          toObserversForMessageId:(nullable id)messageId
                   broadcastStyle:(EPBroadcastStyle)broadcastStyle
                      coalescMask:(EPMessageCoalescing)coalescMask;

- (void)broadcastMessageWithBlock:(void(^)(id _Nonnull observer))block
                  inDispatchQueue:(nullable dispatch_queue_t)dispatchQueue
          toObserversForMessageId:(nullable id)messageId
                   broadcastStyle:(EPBroadcastStyle)broadcastStyle
                      coalescMask:(EPMessageCoalescing)coalescMask;

@end

NS_ASSUME_NONNULL_END
