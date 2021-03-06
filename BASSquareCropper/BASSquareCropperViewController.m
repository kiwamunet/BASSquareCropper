//
//  BASSquareCropperViewController.m
//  BASSquareCropperExample
//
//  Created by Brandon Stakenborg on 5/14/14.
//  Copyright (c) 2014 Brandon Stakenborg. All rights reserved.
//

#import "BASSquareCropperViewController.h"

@interface BASSquareCropperViewController () <UIScrollViewDelegate>

@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) UIImageView  *imageView;
@property (nonatomic) UIView       *croppingOverlayView;
@property (nonatomic) UIView       *topBorderView;
@property (nonatomic) UIView       *bottomBorderView;
@property (nonatomic) UIView       *hollowView;
@property (nonatomic) UIImage      *imageToCrop;
@property (nonatomic) UIButton     *doneButton;
@property (nonatomic) UIButton     *cancelButton;

@property (nonatomic, assign) CGFloat      zoomScale;
@property (nonatomic, assign) CGFloat      maximumZoomScale;
@property (nonatomic, assign) CGFloat      minimumZoomScale;
@property (nonatomic, assign) CGPoint      contentOffset;
@property (nonatomic, assign) UIEdgeInsets contentInset;
@property (nonatomic, assign) CGFloat      minimumCroppedImageSideLength;

@end

@implementation BASSquareCropperViewController

- (instancetype)initWithImage:(UIImage *)image minimumCroppedImageSideLength:(CGFloat)minimumCroppedImageSideLength
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _imageToCrop = image;
        _minimumCroppedImageSideLength = minimumCroppedImageSideLength;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.backgroundColor         = (self.backgroundColor)         ?: [UIColor blackColor];
    self.borderColor             = (self.borderColor)             ?: [UIColor clearColor];
    self.excludedBackgroundColor = (self.excludedBackgroundColor) ?: [UIColor blackColor];
    //    self.doneFont                = (self.doneFont)                ?: [UIFont systemFontOfSize:16.0f];
    self.doneFont                = (self.doneFont)                ?: [UIFont fontWithName:@"HiraKakuProN-W6" size:16.0f];
    self.doneColor               = (self.doneColor)               ?: [UIColor whiteColor];
    self.doneText                = (self.doneText)                ?: @"完了";
    self.cancelFont              = (self.cancelFont)              ?: [UIFont systemFontOfSize:16.0f];
    self.cancelColor             = (self.cancelColor)             ?: [UIColor whiteColor];
    self.cancelText              = (self.cancelText)              ?: @"    ";
    
    self.scrollView = [UIScrollView new];
    self.scrollView.delegate = self;
    self.scrollView.backgroundColor = self.backgroundColor;
    self.scrollView.alwaysBounceHorizontal = YES;
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.scrollsToTop = NO;
    self.scrollView.exclusiveTouch = YES;
    
    self.imageView = [[UIImageView alloc] initWithImage:self.imageToCrop];
    self.imageView.hidden = YES;
    [self.imageView sizeToFit];
    self.minimumCroppedImageSideLength = MIN(MIN(CGRectGetHeight(self.imageView.bounds), CGRectGetWidth(self.imageView.bounds)), self.minimumCroppedImageSideLength);
    
    self.croppingOverlayView = [UIView new];
    self.croppingOverlayView.backgroundColor = [UIColor clearColor];
    self.croppingOverlayView.layer.borderColor = self.borderColor.CGColor;
    self.croppingOverlayView.layer.borderWidth = 1.0f/[UIScreen mainScreen].scale;
    self.croppingOverlayView.userInteractionEnabled = NO;
    self.croppingOverlayView.opaque = NO;
    
    self.hollowView = [UIView new];
    self.hollowView.backgroundColor = self.excludedBackgroundColor;
    self.hollowView.alpha = 0.45f;
    self.hollowView.userInteractionEnabled = NO;
    self.hollowView.opaque = NO;
    
    self.topBorderView = [UIView new];
    self.topBorderView.backgroundColor = self.excludedBackgroundColor;
    self.topBorderView.userInteractionEnabled = NO;
    self.topBorderView.alpha = 0.45f;
    self.topBorderView.opaque = NO;
    
    self.bottomBorderView = [UIView new];
    self.bottomBorderView.backgroundColor = self.excludedBackgroundColor;
    self.bottomBorderView.userInteractionEnabled = NO;
    self.bottomBorderView.alpha = 0.45f;
    self.bottomBorderView.opaque = NO;
    
    self.doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.doneButton setTitle:self.doneText forState:UIControlStateNormal];
    [self.doneButton setTitleColor:self.doneColor forState:UIControlStateNormal];
    self.doneButton.titleLabel.font = self.doneFont;
    [self.doneButton addTarget:self action:@selector(cropImage) forControlEvents:UIControlEventTouchUpInside];
    [self.doneButton sizeToFit];
    
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.cancelButton setTitle:self.cancelText forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:self.cancelColor forState:UIControlStateNormal];
    UIImage *imageNo = [UIImage imageNamed:@"IconLeftArrow.png"];
    [self.cancelButton setImage:imageNo forState:UIControlStateNormal];
    self.cancelButton.titleLabel.font = self.cancelFont;
    [self.cancelButton addTarget:self action:@selector(cancelCrop) forControlEvents:UIControlEventTouchUpInside];
    [self.cancelButton sizeToFit];
    
    
    
    
    
    
    
    
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_scrollView, _doneButton, _cancelButton, _croppingOverlayView, _topBorderView, _bottomBorderView, _hollowView );
    [views enumerateKeysAndObjectsUsingBlock:^(id key, UIView *view, BOOL *stop) {
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:view];
    }];
    
    NSDictionary *scrollViews = NSDictionaryOfVariableBindings(_imageView);
    [scrollViews enumerateKeysAndObjectsUsingBlock:^(id key, UIView *view, BOOL *stop) {
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [self.scrollView addSubview:view];
    }];
    
    [self.view sendSubviewToBack:_scrollView];
    [self.view bringSubviewToFront:self.doneButton];
    [self.view bringSubviewToFront:self.cancelButton];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_scrollView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_scrollView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_croppingOverlayView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_topBorderView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_bottomBorderView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_topBorderView][_croppingOverlayView][_bottomBorderView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[_cancelButton]->=0-[_doneButton]-10-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[_doneButton]" options:0 metrics:nil views:views]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_croppingOverlayView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:_croppingOverlayView attribute:NSLayoutAttributeWidth multiplier:1.0f constant:0.0f]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_croppingOverlayView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:0.0f]];
    [self.scrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_imageView]|" options:0 metrics: 0 views:scrollViews]];
    [self.scrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_imageView]|" options:0 metrics: 0 views:scrollViews]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    UIEdgeInsets insets = UIEdgeInsetsZero;
    insets.top = CGRectGetMaxY(self.topBorderView.bounds);
    insets.bottom = CGRectGetMaxY(self.bottomBorderView.bounds);
    self.scrollView.contentInset = insets;
    self.imageView.hidden = NO;
    
    CAShapeLayer *mask = [[CAShapeLayer alloc] init];
    mask.fillRule = kCAFillRuleEvenOdd;
    mask.fillColor = [UIColor blackColor].CGColor;
    
    // 画面全体
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRect:self.hollowView.bounds];
    // 穴を空ける
    [maskPath moveToPoint:CGPointMake(CGRectGetWidth(self.hollowView.bounds) / 2.0, CGRectGetHeight(self.hollowView.bounds) / 2.0)];
    [maskPath addArcWithCenter:CGPointMake(CGRectGetWidth(self.hollowView.bounds) / 2.0, CGRectGetHeight(self.hollowView.bounds) / 2.0) radius:self.hollowView.bounds.size.width / 2 startAngle:0 endAngle:2 * M_PI clockwise:YES];
    
    mask.path = maskPath.CGPath;
    self.hollowView.layer.mask = mask;
    
    [self resetZoomScaleAndContentOffset];
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait + UIInterfaceOrientationMaskPortraitUpsideDown;
}

#pragma mark - Helpers

- (void)updateScrollViewParameters
{
    self.zoomScale = self.scrollView.zoomScale;
    self.maximumZoomScale = self.scrollView.maximumZoomScale;
    self.minimumZoomScale = self.scrollView.minimumZoomScale;
    self.contentOffset = self.scrollView.contentOffset;
    self.contentInset = self.scrollView.contentInset;
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    [self updateScrollViewParameters];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        [self updateScrollViewParameters];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self updateScrollViewParameters];
}

- (void)resetZoomScaleAndContentOffset
{
    CGFloat minZoomScaleX = CGRectGetWidth(self.croppingOverlayView.bounds) / self.imageToCrop.size.width;
    CGFloat minZoomScaleY = CGRectGetHeight(self.croppingOverlayView.bounds) / self.imageToCrop.size.height;
    
    CGFloat maxZoomScaleX = CGRectGetWidth(self.croppingOverlayView.bounds) / self.minimumCroppedImageSideLength;
    CGFloat maxZoomScaleY = CGRectGetHeight(self.croppingOverlayView.bounds) / self.minimumCroppedImageSideLength;
    
    self.scrollView.minimumZoomScale = MAX(minZoomScaleX, minZoomScaleY);
    self.scrollView.maximumZoomScale = MIN(maxZoomScaleX, maxZoomScaleY);
    
    [self.scrollView setZoomScale:self.scrollView.minimumZoomScale animated:NO];
    
    CGPoint contentOffset = CGPointZero;
    contentOffset.x = (self.scrollView.contentSize.width - (CGRectGetWidth(self.scrollView.bounds) - self.scrollView.contentInset.left - self.scrollView.contentInset.right)) / 2.0f;
    contentOffset.y = (self.scrollView.contentSize.height - (CGRectGetHeight(self.scrollView.bounds) - self.scrollView.contentInset.top - self.scrollView.contentInset.bottom)) / 2.0f;
    contentOffset.x -= self.scrollView.contentInset.left;
    contentOffset.y -= self.scrollView.contentInset.top;
    [self.scrollView setContentOffset:contentOffset animated:NO];
    
    [self updateScrollViewParameters];
}

#pragma mark - Delegate Methods

- (void)cropImage
{
    UIImage *croppedImage = nil;
    
    CGRect croppedImageRect = CGRectZero;
    
    croppedImageRect.size = (CGSize){(CGFloat)round(CGRectGetWidth(self.croppingOverlayView.bounds)/self.zoomScale), (CGFloat)round(CGRectGetHeight(self.croppingOverlayView.bounds)/self.zoomScale)};
    
    UIGraphicsBeginImageContextWithOptions(croppedImageRect.size, NO, 1.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(ctx, 1.0f, 1.0f);
    // Translate to the selected offsetz
    CGPoint translation = CGPointZero;
    translation.x = -1.0f * (self.contentOffset.x + self.contentInset.left) / self.zoomScale;
    translation.y = -1.0f * (self.contentOffset.y + self.contentInset.top) / self.zoomScale;
    
    // clamp translation to avoid dark rows on edges of cropped image due to numerical error
    translation.x = MIN(0.0f, translation.x);
    translation.y = MIN(0.0f, translation.y);
    
    translation.x = MAX(-(self.imageToCrop.size.width - CGRectGetWidth(croppedImageRect)), translation.x);
    translation.y = MAX(-(self.imageToCrop.size.height - CGRectGetHeight(croppedImageRect)), translation.y);
    
    CGContextTranslateCTM(ctx, translation.x, translation.y);
    ctx = nil;
    
    // Render the image at full size at (0, 0)
    // Only the parts we want will be drawn in the context due to translation and scaling
    // using the UIImage drawing method (rather than the core graphics method) makes it
    // so that we don't have to flip the coordinate space to put the origin in the bottom
    // right. It is also great because UIImage takes the imageOrientation into account
    // when it draws so that we don't have to.
    [self.imageToCrop drawAtPoint:CGPointZero];
    
    croppedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    CGContextRelease(ctx);
    
    _cropRect = (CGRect){.origin.x = -translation.x, .origin.y = -translation.y, .size.width = croppedImageRect.size.width, .size.height = croppedImageRect.size.height};
    
    [self.squareCropperDelegate squareCropperDidCropImage:croppedImage inCropper:self];
    croppedImage = nil;
}

- (void)cancelCrop
{
    [self.squareCropperDelegate squareCropperDidCancelCropInCropper:self];
}



- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    _hollowView.frame = _croppingOverlayView.frame;
    [self.view bringSubviewToFront: _hollowView];
}

- (void)dealloc {
    
    self.imageView = nil;
    self.imageToCrop = nil;
    NSLog(@"BASSquareCropperViewController dealloc");
}

@end

