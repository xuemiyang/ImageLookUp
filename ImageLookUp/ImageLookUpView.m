//
//  ImageLookUpView.m
//  ImageLookUp
//
//  Created by TCLios2 on 2017/11/27.
//  Copyright © 2017年 TCLios2. All rights reserved.
//

#import "ImageLookUpView.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

NS_ASSUME_NONNULL_BEGIN

static ImageNetworkLoadHandler imageNetworkLoadHandler;

@implementation ImageItem
- (instancetype)initWithImageData:(id)imageData imageView:(UIView *)imageView image:(UIImage * _Nullable)image isSelect:(BOOL)isSelect {
    if (self = [super init]) {
        _imageData = imageData;
        _imageView = imageView;
        _image = image;
        _isSelect = isSelect;
    }
    return self;
}
@end

@interface DownPanGestureRecognizer : UIPanGestureRecognizer
@end

@interface DownPanGestureRecognizer ()
@property (nonatomic, assign) CGPoint beginLocation;
@end

@implementation DownPanGestureRecognizer
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    _beginLocation = [touches.anyObject locationInView:self.view.superview];
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (self.state == UIGestureRecognizerStatePossible) {
        CGPoint location = [touches.anyObject locationInView:self.view.superview];
        if (location.x - _beginLocation.x != 0 && location.y - _beginLocation.y < 0) {
            self.state = UIGestureRecognizerStateFailed;
        }
    }
    [super touchesMoved:touches withEvent:event];
}

- (CGPoint)translationInView:(nullable UIView *)view {
    CGPoint proposedTranslation = [super translationInView: view];
    proposedTranslation.x = 0;
    return proposedTranslation;
}

@end

@interface ImageScrollView: UIScrollView
@property (nonatomic, strong, readonly) ImageItem *item;
@property (nonatomic, weak, readonly) UIImageView *imageView;
@property (nonatomic, copy) void (^dismissHandler)(ImageScrollView *scrollView);
@property (nonatomic, copy) void (^dragingHandler)(CGFloat alpha);
@property (nonatomic, copy) void (^endDragingHandler)(void);
/// defaut 0.3
@property (nonatomic, assign) CGFloat duration;
@end

@interface ImageScrollView () <UIScrollViewDelegate>
@property (nonatomic, assign) CGSize beforeContentSize;
@property (nonatomic, assign) CGRect imageViewEndFrame;
- (instancetype)initWithItem:(ImageItem *)item;
@end

@implementation ImageScrollView
- (instancetype)initWithItem:(ImageItem *)item {
    if (self = [super initWithFrame:UIScreen.mainScreen.bounds]) {
        _item = item;
        self.delegate = self;
        self.maximumZoomScale = 3;
        _duration = 0.3;
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.frame];
        imageView.contentMode = item.imageView.contentMode;
        imageView.clipsToBounds = YES;
        if (item.image) {
            [self setImage:item.image toImageView:imageView];
        }
        _imageView = imageView;
        [self addSubview:imageView];
        if ([item.imageData isKindOfClass:[UIImage class]]) {
            [self setImage:item.imageData toImageView:imageView];
        } else if ([item.imageData isKindOfClass:[NSString class]]) {
            [self setUrl:[NSURL URLWithString:item.imageData] placeholder:item.image toImageView:imageView];
        } else if ([item.imageData isKindOfClass:[NSData class]]) {
            [self setImage:[UIImage imageWithData:item.imageData] toImageView:imageView];
        } else if ([item.imageData isKindOfClass:[NSURL class]]) {
            [self setUrl:item.imageData placeholder:item.image toImageView:imageView];
        }
        
        UITapGestureRecognizer *tap1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap1:)];
        [self addGestureRecognizer:tap1];
        UITapGestureRecognizer *tap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap2:)];
        tap2.numberOfTapsRequired = 2;
        [tap1 requireGestureRecognizerToFail:tap2];
        [self addGestureRecognizer:tap2];
        UIPanGestureRecognizer *pan = [[DownPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
        imageView.userInteractionEnabled = YES;
        [imageView addGestureRecognizer:pan];
    }
    return self;
}

#pragma mark - private
- (void)setUrl:(NSURL *)url placeholder:(UIImage *)placeholder toImageView:(UIImageView *)imageView {
    if (url && imageNetworkLoadHandler) {
        CALayer *proLayer = [self progressLayer];
        [self.layer addSublayer:proLayer];
        __weak typeof(self) weakSelf = self;
        __weak typeof(imageView) weakImageView = imageView;
        __weak typeof(proLayer) weakProLayer = proLayer;
        imageNetworkLoadHandler(imageView, url, placeholder, ^(UIImage *image) {
            if (image && weakImageView && weakProLayer) {
                [weakSelf setImage:image toImageView:weakImageView];
            }
            [weakProLayer removeFromSuperlayer];
        });
    }
}

- (void)setImage:(UIImage *)image toImageView:(UIImageView *)imageView {
    if (!image) {
        return;
    }
    CGFloat viewW = self.frame.size.width;
    CGFloat viewH = self.frame.size.height;
    CGRect imageViewFrame = imageView.frame;
    if (image.size.height / image.size.width > viewH / viewW) {
        imageViewFrame.size.height = floor(image.size.height / image.size.width * viewW);
    } else {
        CGFloat height = image.size.height / image.size.width * viewW;
        if (height < 1) {
            height = viewH;
        }
        imageViewFrame.size.height = height;
        imageViewFrame.origin.y = viewH / 2 - height / 2;
    }
    if (imageViewFrame.size.height > viewH && imageViewFrame.size.height - viewH <= 1) {
        imageViewFrame.size.height = viewH;
    }
    imageView.frame = imageViewFrame;
    self.contentSize = CGSizeMake(viewW, MAX(viewH, imageViewFrame.size.height));
    _beforeContentSize = self.contentSize;
    [self setContentOffset:CGPointZero animated:NO];
    imageView.image = image;
}

- (CALayer *)progressLayer {
    CGFloat screenW = UIScreen.mainScreen.bounds.size.width;
    CGFloat screenH = UIScreen.mainScreen.bounds.size.height;
    CGFloat w = 30;
    CGFloat lineW = 4;
    CGFloat r = (w - lineW) / 2;
    CAShapeLayer *progressLayer1 = CAShapeLayer.layer;
    progressLayer1.strokeColor = UIColor.blackColor.CGColor;
    progressLayer1.fillColor = UIColor.clearColor.CGColor;
    progressLayer1.lineWidth = lineW;
    progressLayer1.frame = CGRectMake((screenW - w) / 2, (screenH - w) / 2, w, w);
    UIBezierPath *path1 = [UIBezierPath bezierPathWithArcCenter:CGPointMake(w / 2, w / 2) radius:r startAngle:0 endAngle:M_PI * 2 clockwise:YES];
    progressLayer1.path = path1.CGPath;
    
    CAShapeLayer *progressLayer2 = CAShapeLayer.layer;
    progressLayer2.frame = CGRectMake(0, 0, w, w);
    progressLayer2.strokeColor = UIColor.whiteColor.CGColor;
    progressLayer2.fillColor = UIColor.clearColor.CGColor;
    progressLayer2.lineWidth = lineW;
    progressLayer2.lineCap = kCALineCapRound;
    UIBezierPath *path2 = [UIBezierPath bezierPathWithArcCenter:CGPointMake(w / 2, w / 2) radius:r startAngle:0 endAngle:M_PI * 2 clockwise:YES];
    progressLayer2.path = path2.CGPath;
    progressLayer2.strokeEnd = 0.6;
    
    CABasicAnimation *anima = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    anima.toValue = @(M_PI * 2);
    anima.duration = 1.5;
    anima.repeatCount = HUGE;
    [progressLayer2 addAnimation:anima forKey:nil];
    [progressLayer1 addSublayer:progressLayer2];
    return progressLayer1;
}

- (void)tap1:(UITapGestureRecognizer *)g {
    if (self.zoomScale > self.minimumZoomScale) {
        [self setZoomScale:self.minimumZoomScale animated:YES];
    }
    if (_dismissHandler) {
        _dismissHandler(self);
    }
}

- (void)tap2:(UITapGestureRecognizer *)g {
    if (self.zoomScale > self.minimumZoomScale) {
        [self setZoomScale:self.minimumZoomScale animated:YES];
    } else {
        [self zoomToRect:[self zoomRectForScale:self.maximumZoomScale withCenter:[g locationInView:_imageView]] animated:YES];
    }
}

- (void)pan:(UIPanGestureRecognizer *)g {
    CGFloat viewH = self.contentSize.height;
    switch (g.state) {
        case UIGestureRecognizerStateBegan:
            _imageViewEndFrame = _imageView.frame;
            break;
        case UIGestureRecognizerStateChanged: {
            CGPoint location = [g locationInView:self];
            CGRect imageFrame = _imageView.frame;
            CGFloat scale = 0;
            if (location.y <= viewH / 2) {
                imageFrame.size.width = _imageViewEndFrame.size.width;
            } else {
                scale = (location.y - viewH / 2) / (viewH / 2);
                imageFrame.size = CGSizeMake(_imageViewEndFrame.size.width - scale * (_imageViewEndFrame.size.width / 2), _imageViewEndFrame.size.height - scale * (_imageViewEndFrame.size.height / 2));
            }
            if (_dragingHandler) {
                _dragingHandler(1 - scale);
            }
            _imageView.frame = imageFrame;
            _imageView.center = location;
        }
            break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded: {
            CGPoint location = [g locationInView:self];
            if (viewH - location.y < 40) {
                if (self.zoomScale > self.minimumZoomScale) {
                    [self setZoomScale:self.minimumZoomScale animated:NO];
                }
                if (_dismissHandler) {
                    _dismissHandler(self);
                }
                return;
            }
            [UIView animateWithDuration:_duration animations:^{
                _imageView.frame = _imageViewEndFrame;
                if (_endDragingHandler) {
                    _endDragingHandler();
                }
            }];
        }
            break;
        default:
            break;
    }
}

- (CGRect)zoomRectForScale:(CGFloat)scale withCenter:(CGPoint)center {
    CGFloat w = UIScreen.mainScreen.bounds.size.width / scale;
    CGFloat h = UIScreen.mainScreen.bounds.size.height / scale;
    return CGRectMake(center.x - w / 2, center.y - h / 2, w, h);
}

#pragma mark UIScrollViewDelegate
- (UIView * _Nullable)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    if (self.zoomScale == self.minimumZoomScale) {
        self.contentSize = _beforeContentSize;
    }
    CGFloat offsetX = scrollView.bounds.size.width > scrollView.contentSize.width ? (scrollView.bounds.size.width - scrollView.contentSize.width) / 2 : 0;
    CGFloat offsetY = scrollView.bounds.size.height > scrollView.contentSize.height ? (scrollView.bounds.size.height - scrollView.contentSize.height) / 2 : 0;
    _imageView.center = CGPointMake(scrollView.contentSize.width / 2 + offsetX, scrollView.contentSize.height / 2 + offsetY);
}

@end

@interface ImageLookUpView () <UIScrollViewDelegate>
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, weak) UIPageControl *pageControl;
@property (nonatomic, assign) CGFloat dx;
@property (nonatomic, assign) CGFloat duration;
@end

@implementation ImageLookUpView
+ (void)presenImageLookUpViewWithItems:(NSArray<ImageItem *> *)items {
    ImageLookUpView *imageLookUpView = [[ImageLookUpView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    [imageLookUpView setupWithItems:items];
}

+ (void)setImageNetworkLoadHandler:(ImageNetworkLoadHandler)handler {
    imageNetworkLoadHandler = handler;
}

#pragma mark - private
- (void)setupWithItems:(NSArray<ImageItem *> *)items {
    if (items.count == 0) {
        return;
    }
    _dx = 10;
    _duration = 0.3;
    CGFloat screenW = UIScreen.mainScreen.bounds.size.width;
    CGFloat screenH = UIScreen.mainScreen.bounds.size.height;
    self.backgroundColor = UIColor.blackColor;
    [UIApplication.sharedApplication.keyWindow addSubview:self];
    ImageItem *item = items.firstObject;
    NSInteger index = 0;
    for (int i=0; i<items.count; i++) {
        if (items[i].isSelect) {
            item = items[i];
            index = i;
            break;
        }
    }
    CGRect rect = [item.imageView.superview convertRect:item.imageView.frame toView:self];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:rect];
    imageView.image = item.image;
    [self addSubview:imageView];
    
    [UIView animateWithDuration:_duration animations:^{
        if (imageView.image) {
            imageView.frame = CGRectMake(0, 0, screenW, screenW / imageView.image.size.width * imageView.image.size.height);
        } else {
            imageView.frame = CGRectMake(0, 0, screenW, screenW / imageView.frame.size.width * imageView.frame.size.height);
        }
        if (imageView.frame.size.height < screenH) {
            imageView.center = CGPointMake(imageView.center.x, screenH / 2);
        }
    } completion:^(BOOL finished) {
        [imageView removeFromSuperview];
        [self presentWithIndex:index items:items];
    }];
}

- (void)presentWithIndex:(NSInteger)index items:(NSArray<ImageItem *> *)items {
    CGFloat screenW = UIScreen.mainScreen.bounds.size.width;
    CGFloat screenH = UIScreen.mainScreen.bounds.size.height;
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, screenW + _dx, screenH)];
    _scrollView = scrollView;
    scrollView.pagingEnabled = YES;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.delegate = self;
    scrollView.contentSize = CGSizeMake((screenW + _dx) * items.count, screenH);
    [UIApplication.sharedApplication.keyWindow addSubview:scrollView];
    
    __weak typeof(self) weakSelf = self;
    for (int i=0; i<items.count; i++) {
        ImageScrollView *scrollView = [[ImageScrollView alloc] initWithItem:items[i]];
        CGRect frame = scrollView.frame;
        frame.origin.x = (screenW + _dx) * i;
        scrollView.frame = frame;
        scrollView.dismissHandler = ^(ImageScrollView *scrollView) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            CGRect rect = [scrollView.item.imageView.superview convertRect:scrollView.item.imageView.frame toView:strongSelf];
            [UIView animateWithDuration:strongSelf.duration animations:^{
                strongSelf.pageControl.alpha = 0;
                strongSelf.alpha = 0;
                scrollView.imageView.frame = rect;
            } completion:^(BOOL finished) {
                [strongSelf.pageControl removeFromSuperview];
                [strongSelf removeFromSuperview];
                [strongSelf.scrollView removeFromSuperview];
            }];
        };
        scrollView.dragingHandler = ^(CGFloat alpha) {
            weakSelf.alpha = alpha;
        };
        scrollView.endDragingHandler = ^{
            weakSelf.alpha = 1;
        };
        [_scrollView addSubview:scrollView];
    }
    
    UIPageControl *pageControl = [[UIPageControl alloc] init];
    _pageControl = pageControl;
    pageControl.numberOfPages = items.count;
    CGRect pageControlFrame = pageControl.frame;
    pageControlFrame.origin = CGPointMake(screenW / 2, screenH - 40);
    pageControl.frame = pageControlFrame;
    pageControl.hidden = items.count <= 1;
    [UIApplication.sharedApplication.keyWindow addSubview:pageControl];
    
    [scrollView setContentOffset:CGPointMake((screenW + _dx) * index, 0) animated:NO];
    pageControl.currentPage = index;
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    _pageControl.currentPage = scrollView.contentOffset.x / scrollView.bounds.size.width;
}

@end


NS_ASSUME_NONNULL_END
