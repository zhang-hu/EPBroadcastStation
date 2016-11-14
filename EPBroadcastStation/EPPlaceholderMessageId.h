//
//  EPPlaceholderMessageId.h
//  EPBroadcastStation
//
//  Created by 张虎 on 2016/11/14.
//  Copyright © 2016年 ZhangHu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EPPlaceholderMessageId : NSObject

#if FOUNDATION_SWIFT_SDK_EPOCH_AT_LEAST(8)
@property (class, strong, readonly) EPPlaceholderMessageId *placeholder;
#endif

@end

NS_ASSUME_NONNULL_END
