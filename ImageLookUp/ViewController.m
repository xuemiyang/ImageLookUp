//
//  ViewController.m
//  ImageLookUp
//
//  Created by TCLios2 on 2017/11/27.
//  Copyright © 2017年 TCLios2. All rights reserved.
//

#import "ViewController.h"
#import "ImageLookUpView.h"
#import "UIImageView+WebCache.h"

@interface ViewController ()
@property (nonatomic, strong) NSMutableArray *items;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
   
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _items = [NSMutableArray arrayWithCapacity:5];
    NSString *urlString = @"https://gss0.baidu.com/94o3dSag_xI4khGko9WTAnF6hhy/zhidao/pic/item/b812c8fcc3cec3fd84e2d8d4df88d43f869427b6.jpg";
    for (int i=0; i<5; i++) {
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(60 * i, 100, 50, 50)];
        UIImage *image = [UIImage imageNamed:@"mew_baseline"];
        [button setImage:image forState:UIControlStateNormal];
        [button addTarget:self action:@selector(clickButton:) forControlEvents:UIControlEventTouchUpInside];
        button.tag = i;
        [self.view addSubview:button];
        if (i == 2) {
            [_items addObject:[[ImageItem alloc] initWithImageData:urlString imageView:button image:image isSelect:NO]];
        } else {
            [_items addObject:[[ImageItem alloc] initWithImageData:image imageView:button image:image isSelect:NO]];
        }
    }
    [SDImageCache.sharedImageCache removeImageForKey:urlString withCompletion:nil];
    [ImageLookUpView setImageNetworkLoadHandler:^(UIImageView * _Nonnull imageView, NSURL * _Nonnull url, UIImage * _Nullable placeholder, void (^ _Nonnull completionHandler)(UIImage * _Nullable)) {
        [imageView sd_setImageWithURL:url placeholderImage:placeholder options:SDWebImageRetryFailed completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
            completionHandler(image);
        }];
    }];
}

- (void)clickButton:(UIButton *)btn {
    for (int i=0; i<_items.count; i++) {
        ImageItem *item = _items[i];
        item.isSelect = i == btn.tag;
    }
    [ImageLookUpView presenImageLookUpViewWithItems:_items];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
