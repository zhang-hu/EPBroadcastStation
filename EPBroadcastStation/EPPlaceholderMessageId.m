//
//  EPPlaceholderMessageId.m
//  EPBroadcastStation
//
//  Created by 张虎 on 2016/11/14.
//  Copyright © 2016年 ZhangHu. All rights reserved.
//

#import "EPPlaceholderMessageId.h"

NS_ASSUME_NONNULL_BEGIN

@implementation EPPlaceholderMessageId

+ (instancetype)placeholder
{
    static EPPlaceholderMessageId *_placeholder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _placeholder = [self new];
    });
    return _placeholder;
}

@end

NS_ASSUME_NONNULL_END
