//
//  BASSquareCropperViewController.m
//  BASSquareCropperExample
//
//  Created by Brandon Stakenborg on 5/14/14.
//  Copyright (c) 2014 Brandon Stakenborg. All rights reserved.
//

#import "BASSquareCropperViewController.h"

@interface BASSquareCropperViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView  *imageView;
@property (nonatomic, strong) UIView       *croppingOverlayView;
@property (nonatomic, strong) UIView       *topBorderView;
@property (nonatomic, strong) UIView       *bottomBorderView;
@property (nonatomic, strong) UIImage      *imageToCrop;
@property (nonatomic, strong) UIButton     *doneButton;
@property (nonatomic, strong) UIButton     *cancelButton;

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
    self.borderColor             = (self.borderColor)             ?: [UIColor lightGrayColor];
    self.excludedBackgroundColor = (self.excludedBackgroundColor) ?: [UIColor darkGrayColor];
    self.doneFont                = (self.doneFont)                ?: [UIFont systemFontOfSize:16.0f];
    self.doneColor               = (self.doneColor)               ?: [UIColor whiteColor];
    self.doneText                = (self.doneText)                ?: @"Done";
    self.cancelFont              = (self.cancelFont)              ?: [UIFont systemFontOfSize:14.0f];
    self.cancelColor             = (self.cancelColor)             ?: [UIColor whiteColor];
    self.cancelText              = (self.cancelText)              ?: @"Cancel";
    
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
    
    self.topBorderView = [UIView new];
    self.topBorderView.backgroundColor = self.excludedBackgroundColor;
    self.topBorderView.userInteractionEnabled = NO;
    self.topBorderView.alpha = 0.85f;
    self.topBorderView.opaque = NO;
    
    self.bottomBorderView = [UIView new];
    self.bottomBorderView.backgroundColor = self.excludedBackgroundColor;
    self.bottomBorderView.userInteractionEnabled = NO;
    self.bottomBorderView.alpha = 0.85f;
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
    self.cancelButton.titleLabel.font = self.cancelFont;
    [self.cancelButton addTarget:self action:@selector(cancelCrop) forControlEvents:UIControlEventTouchUpInside];
    [self.cancelButton sizeToFit];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_scrollView, _doneButton, _cancelButton, _croppingOverlayView, _topBorderView, _bottomBorderView);
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
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_doneButton]-10-|" options:0 metrics:nil views:views]];
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
    
    [self resetZoomScaleAndContentOffset];
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
    UIGraphicsBeginImageContextWithOptions(croppedImageRect.size, YES, [[UIScreen mainScreen] scale]);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextScaleCTM(ctx, 1.0f, 1.0f);
    
    // Translate to the selected offset
    CGPoint translation = CGPointZero;
    translation.x = -1.0f * (self.contentOffset.x + self.contentInset.left) / self.zoomScale;
    translation.y = -1.0f * (self.contentOffset.y + self.contentInset.top) / self.zoomScale;
    
    // clamp translation to avoid dark rows on edges of cropped image due to numerical error
    translation.x = MIN(0.0f, translation.x);
    translation.y = MIN(0.0f, translation.y);
    
    translation.x = MAX(-(self.imageToCrop.size.width - CGRectGetWidth(croppedImageRect)), translation.x);
    translation.y = MAX(-(self.imageToCrop.size.height - CGRectGetHeight(croppedImageRect)), translation.y);
    
    CGContextTranslateCTM(ctx, translation.x, translation.y);
    
    // Render the image at full size at (0, 0)
    // Only the parts we want will be drawn in the context due to translation and scaling
    // using the UIImage drawing method (rather than the core graphics method) makes it
    // so that we don't have to flip the coordinate space to put the origin in the bottom
    // right. It is also great because UIImage takes the imageOrientation into account
    // when it draws so that we don't have to.
    [self.imageToCrop drawAtPoint:CGPointZero];
    
    croppedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self.squareCropperDelegate squareCropperDidCropImage:croppedImage];
}

- (void)cancelCrop
{
    [self.squareCropperDelegate squareCropperDidCancelCrop];
}

@end
