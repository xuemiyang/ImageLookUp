//
//  ImageLookUpView.h
//  ImageLookUp
//
//  Created by TCLios2 on 2017/11/27.
//  Copyright © 2017年 TCLios2. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^ImageNetworkLoadHandler)(UIImageView *imageView, NSURL *url, UIImage * _Nullable placeholder, void(^completionHandler)(UIImage * _Nullable image));


@interface ImageItem : NSObject
@property (nonatomic, strong, readonly) id imageData;
@property (nonatomic, weak, readonly) UIView *imageView;
@property (nonatomic, strong, readonly, nullable) UIImage *image;
@property (nonatomic, assign) BOOL isSelect;
- (instancetype)initWithImageData:(id)imageData imageView:(UIView *)imageView image:(UIImage * _Nullable)image isSelect:(BOOL)isSelect;
@end

@interface ImageLookUpView : UIView
+ (void)presenImageLookUpViewWithItems:(NSArray<ImageItem *> *)items;
+ (void)setImageNetworkLoadHandler:(ImageNetworkLoadHandler)handler;
@end

NS_ASSUME_NONNULL_END
