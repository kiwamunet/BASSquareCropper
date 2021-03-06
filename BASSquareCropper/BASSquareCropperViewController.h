//
//  BASSquareCropperViewController.h
//  BASSquareCropperExample
//
//  Created by Brandon Stakenborg on 5/14/14.
//  Copyright (c) 2014 Brandon Stakenborg. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BASSquareCropperViewController;

@protocol BASSquareCropperDelegate <NSObject>

- (void)squareCropperDidCropImage:(UIImage *)croppedImage inCropper:(BASSquareCropperViewController *)cropper;
- (void)squareCropperDidCancelCropInCropper:(BASSquareCropperViewController *)cropper;

@end

@interface BASSquareCropperViewController : UIViewController

@property (nonatomic) UIColor  *backgroundColor;
@property (nonatomic) UIColor  *borderColor;
@property (nonatomic) UIColor  *excludedBackgroundColor;
@property (nonatomic) UIFont   *doneFont;
@property (nonatomic) UIColor  *doneColor;
@property (nonatomic, copy)   NSString *doneText;
@property (nonatomic) UIFont   *cancelFont;
@property (nonatomic) UIColor  *cancelColor;
@property (nonatomic, copy)   NSString *cancelText;
@property (nonatomic, assign) id<BASSquareCropperDelegate>squareCropperDelegate;

@property (nonatomic, assign, readonly) CGRect cropRect;

/**
 *  Standard initializer
 *
 *  @param image                         Image to be cropped
 *  @param minimumCroppedImageSideLength This determines the minimum resolution (length x length) the resulting cropped image can be after scaling. 0 means no limit. NOTE: This will default to the original image's minimum side length if that length is smaller than the provided minimum side length. This will also disable scaling.
 *
 *  @return BASSquareCropperViewController
 */
- (instancetype)initWithImage:(UIImage *)image minimumCroppedImageSideLength:(CGFloat)minimumCroppedImageSideLength;

@end
