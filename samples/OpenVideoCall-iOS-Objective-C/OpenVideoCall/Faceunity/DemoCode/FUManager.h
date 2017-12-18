//
//  FUManager.h
//  FULiveDemo
//
//  Created by 刘洋 on 2017/8/18.
//  Copyright © 2017年 刘洋. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface FUManager : NSObject

@property (nonatomic, assign)               NSInteger selectedBlur;     /**磨皮(0、1、2、3、4、5、6)*/
@property (nonatomic, assign)               double redLevel;            /**红润 (0~1)*/
@property (nonatomic, assign)               double faceShapeLevel;      /**美型等级 (0~1)*/
@property (nonatomic, assign)               NSInteger faceShape;        /**美型类型 (0、1、2、3) 默认：3，女神：0，网红：1，自然：2*/
@property (nonatomic, assign)               double beautyLevel;         /**美白 (0~1)*/
@property (nonatomic, assign)               double thinningLevel;       /**瘦脸 (0~1)*/
@property (nonatomic, assign)               double enlargingLevel;      /**大眼 (0~1)*/
@property (nonatomic, strong)               NSString *selectedFilter;   /**选中的滤镜名称*/
@property (nonatomic, strong)               NSString *selectedItem;     /**选中的道具名称*/
@property (nonatomic, strong)               NSArray<NSString *> *itemsDataSource;       /**道具名称数组*/
@property (nonatomic, strong)               NSArray<NSString *> *filtersDataSource;     /**滤镜名称数组*/

+ (FUManager *)shareManager;

/**加载多个道具*/
- (void)loadItems;

/**销毁全部道具*/
- (void)destoryItems;

/**加载普通道具*/
- (void)loadItem:(NSString *)itemName;

/**将道具绘制到YUVFrame*/
- (void)renderItemsToYUVFrame:(void*)y u:(void*)u v:(void*)v ystride:(int)ystride ustride:(int)ustride vstride:(int)vstride width:(int)width height:(int)height;

@end
