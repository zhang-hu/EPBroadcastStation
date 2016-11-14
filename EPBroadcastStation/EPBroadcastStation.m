//
//  EPBroadcastStation.m
//  EPBroadcastStation
//
//  Created by 张虎 on 2016/11/11.
//  Copyright © 2016年 ZhangHu. All rights reserved.
//

#import "EPBroadcastStation.h"
#import "EPBroadcaster.h"
#import "EPPlaceholderMessageId.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const EPBroadcasterKey = @"EPBroadcastStation.Internal.EPBroadcasterKey";

@interface EPBroadcastStation ()

@property (nonatomic) NSMapTable<id, NSHashTable<id> *> *msgIdToObserversMap;
@property (nonatomic) NSNotificationCenter *notificationCenter;
@property (nonatomic) NSNotificationQueue *notificationQueue;
@property (nonatomic) NSLock *mapTableOpLock;
@property (nonatomic) NSLock *hashTableOpLock;

@end

@implementation EPBroadcastStation

+ (instancetype)defaultStation
{
    static EPBroadcastStation *_defaultStation;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultStation = [self new];
    });
    return _defaultStation;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.msgIdToObserversMap = [NSMapTable weakToStrongObjectsMapTable];
        self.notificationCenter = [NSNotificationCenter new];
        self.notificationQueue = [[NSNotificationQueue alloc] initWithNotificationCenter:self.notificationCenter];
        [self.notificationCenter addObserver:self selector:@selector(processNotification:) name:nil object:nil];
        self.mapTableOpLock = [NSLock new];
        self.hashTableOpLock = [NSLock new];
    }
    return self;
}

- (void)dealloc
{
    [self.notificationCenter removeObserver:self];
}

- (void)addObserver:(id)observer forMessageId:(nullable id)messageId
{
    NSHashTable<id> *hashTable = [self observersForMessageId:messageId];
    if (hashTable) {
        [self.hashTableOpLock lock];
        [hashTable addObject:observer];
        [self.hashTableOpLock unlock];
    } else {
        hashTable = [NSHashTable weakObjectsHashTable];
        [hashTable addObject:observer];
        
        [self.mapTableOpLock lock];
        [self.msgIdToObserversMap setObject:hashTable forKey:messageId ?: [EPPlaceholderMessageId placeholder]];
        [self.mapTableOpLock unlock];
    }
}

- (void)removeObserver:(id)observer forMessageId:(nullable id)messageId
{
    if (messageId) {
        NSHashTable<id> *hashTable = [self observersForMessageId:messageId];
        if (hashTable) {
            [self.hashTableOpLock lock];
            [hashTable removeObject:observer];
            [self.hashTableOpLock unlock];
        }
    } else {
        [self.mapTableOpLock lock];
        for (id key in self.msgIdToObserversMap) {
            [self.hashTableOpLock lock];
            [[self.msgIdToObserversMap objectForKey:key] removeObject:observer];
            [self.hashTableOpLock unlock];
        }
        [self.mapTableOpLock unlock];
    }
}

- (void)removeObserver:(id)observer
{
    [self removeObserver:observer forMessageId:nil];
}

- (void)broadcastMessageWithBlock:(void(^)(id _Nonnull observer))block
          toObserversForMessageId:(nullable id)messageId
                   broadcastStyle:(EPBroadcastStyle)broadcastStyle
                      coalescMask:(EPMessageCoalescing)coalescMask
{
    [self __broadcastMessageWithBlock:block inQueue:nil toObserversForMessageId:messageId broadcastStyle:broadcastStyle coalescMask:coalescMask];
}

- (void)broadcastMessageWithBlock:(void(^)(id _Nonnull observer))block
                          inQueue:(nullable NSOperationQueue *)queue
          toObserversForMessageId:(nullable id)messageId
                   broadcastStyle:(EPBroadcastStyle)broadcastStyle
                      coalescMask:(EPMessageCoalescing)coalescMask
{
    [self __broadcastMessageWithBlock:block inQueue:queue toObserversForMessageId:messageId broadcastStyle:broadcastStyle coalescMask:coalescMask];
}

- (void)broadcastMessageWithBlock:(void(^)(id _Nonnull observer))block
                  inDispatchQueue:(nullable dispatch_queue_t)dispatchQueue
          toObserversForMessageId:(nullable id)messageId
                   broadcastStyle:(EPBroadcastStyle)broadcastStyle
                      coalescMask:(EPMessageCoalescing)coalescMask
{
    [self __broadcastMessageWithBlock:block inQueue:dispatchQueue toObserversForMessageId:messageId broadcastStyle:broadcastStyle coalescMask:coalescMask];
}


#pragma mark - Private

- (void)__broadcastMessageWithBlock:(void(^)(id _Nonnull observer))block
                            inQueue:(nullable id)queue
            toObserversForMessageId:(nullable id)messageId
                     broadcastStyle:(EPBroadcastStyle)broadcastStyle
                        coalescMask:(EPMessageCoalescing)coalescMask
{
    EPBroadcaster *broadcaster;
    id realMsgId = messageId ?: [EPPlaceholderMessageId placeholder];
    
    if (queue) {
        if ([queue isKindOfClass:[NSOperationQueue class]]) {
            broadcaster = [EPBroadcaster instanceWithMessageId:realMsgId broadcastBlock:block broadcastQueue:queue];
        } else {
            broadcaster = [EPBroadcaster instanceWithMessageId:realMsgId broadcastBlock:block broadcastDispatchQueue:queue];
        }
    } else {
        broadcaster = [EPBroadcaster instanceWithMessageId:realMsgId broadcastBlock:block];
    }
    
    NSNotification *notification = [NSNotification notificationWithName:[NSString stringWithFormat:@"%p", realMsgId] object:nil userInfo:@{ EPBroadcasterKey : broadcaster }];
    
    NSNotificationCoalescing coalesc = [self.class notificaitonCoalescingFromMask:coalescMask];
    if (realMsgId == [EPPlaceholderMessageId placeholder]) {
        coalesc = NSNotificationNoCoalescing;
    } else {
        if (coalesc & NSNotificationCoalescingOnName) {
            [self.notificationQueue dequeueNotificationsMatching:notification coalesceMask:NSNotificationCoalescingOnName];
        }
    }
    [self.notificationQueue enqueueNotification:notification postingStyle:[self.class postingStyleFromBroadcastStyle:broadcastStyle] coalesceMask:coalesc forModes:@[ NSRunLoopCommonModes ]];
}

+ (NSPostingStyle)postingStyleFromBroadcastStyle:(EPBroadcastStyle)broadcastStyle
{
    NSDictionary *dict = @{ @(EPBroadcastStyleWhenIdle) : @(NSPostWhenIdle),
                            @(EPBroadcastStyleASAP) : @(NSPostASAP),
                            @(EPBroadcastStyleNow) : @(NSPostNow) };
    return [dict[@(broadcastStyle)] integerValue];
}

+ (NSNotificationCoalescing)notificaitonCoalescingFromMask:(EPMessageCoalescing)mask
{
    NSNotificationCoalescing coalescing = NSNotificationNoCoalescing;
    if (mask == EPMessageCoalescingOnMessageId) {
        coalescing = NSNotificationCoalescingOnName;
    } 
    return coalescing;
}

- (void)processNotification:(NSNotification *)notification
{
    EPBroadcaster *broadcaster = notification.userInfo[EPBroadcasterKey];
    NSArray<id> *arr;
    if (broadcaster.messageId == [EPPlaceholderMessageId placeholder]) {
        arr = [self allObservers];
    } else {
        NSMutableArray<id> *tmp = [NSMutableArray arrayWithArray:[self observersForMessageId:broadcaster.messageId].allObjects];
        [tmp addObjectsFromArray:[self observersForMessageId:nil].allObjects];
        arr = tmp.copy;
    }
    [broadcaster broadcastToObservers:arr];
}

- (nullable NSArray<id> *)allObservers
{
    NSMutableArray *arr = [NSMutableArray array];
    
    [self.mapTableOpLock lock];
    for (id key in self.msgIdToObserversMap) {
        [self.hashTableOpLock lock];
        [arr addObjectsFromArray:[self.msgIdToObserversMap objectForKey:key].allObjects];
        [self.hashTableOpLock unlock];
    }
    [self.mapTableOpLock unlock];
    
    return arr.copy;
}

- (nullable NSHashTable<id> *)observersForMessageId:(nullable id)msgId
{
    return [self.msgIdToObserversMap objectForKey:msgId ?: [EPPlaceholderMessageId placeholder]];
}

@end

NS_ASSUME_NONNULL_END
