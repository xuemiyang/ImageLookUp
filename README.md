# ImageLookUp

一个仿照微信朋友圈的图片浏览工具类。

怎么使用
1.创建ImageItem数组。

1.1 使用UIImage创建。\<br>
  [_items addObject:[[ImageItem alloc] initWithImageData:image imageView:imageView image:imageView.image isSelect:NO]];\<br>
  imageData可为UIImage、NSString的NSURL字符串。imageView为需要放大浏览的image视图(UIImage、UIButton)，image为放大浏览的image视图的image
  数据。 isSelect表明是否是选择该视图为显示视图。
1.2 使用NSString创建。
  [_items addObject:[[ImageItem alloc] initWithImageData:urlString imageView:imageView image:imageView.image isSelect:NO]];\<br>
  imageData可为UIImage、NSString的NSURL字符串。imageView为需要放大浏览的image视图(UIImage、UIButton)，image为放大浏览的image视图的image
  数据。 isSelect表明是否是选择该视图为显示视图。

2.设置图片下载的handler.\<br>
  [ImageLookUpView setImageNetworkLoadHandler:^(UIImageView * _Nonnull imageView, NSURL * _Nonnull url, UIImage * _Nullable placeholder, void (^ _Nonnull completionHandler)(UIImage * _Nullable)) {
  [imageView sd_setImageWithURL:url placeholderImage:placeholder options:SDWebImageRetryFailed completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
            completionHandler(image);
      }];
 }];\<br>
  此处为SDWebImage的图片下载，也可改为其他图片下载框架。

3.浏览图片。\<br>
  [ImageLookUpView presenImageLookUpViewWithItems:_items];

扩展。\<br>
你可以在源代码添加各种类型的ImageData处理。这里支持UIImage、NSString、NSData、NSURL。
