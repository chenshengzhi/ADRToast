//
//  UIView+ADRToast.m
//  ADRToast
//
//  Copyright 2014 Charles Scalesse.
//

#import "UIView+ADRToast.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

// general appearance
static const CGFloat ADRToastMaxWidth            = 0.8;      // 80% of parent view width
static const CGFloat ADRToastMaxHeight           = 0.8;      // 80% of parent view height
static const CGFloat ADRToastHorizontalPadding   = 10.0;
static const CGFloat ADRToastVerticalPadding     = 10.0;
static const CGFloat ADRToastCornerRadius        = 10.0;
static const CGFloat ADRToastOpacity             = 0.8;
static const CGFloat ADRToastFontSize            = 16.0;
static const CGFloat ADRToastMaxTitleLines       = 0;
static const CGFloat ADRToastMaxMessageLines     = 0;
static const NSTimeInterval ADRToastFadeDuration = 0.2;

// shadow appearance
static const CGFloat ADRToastShadowOpacity       = 0.8;
static const CGFloat ADRToastShadowRadius        = 6.0;
static const CGSize  ADRToastShadowOffset        = { 4.0, 4.0 };
static const BOOL    ADRToastDisplayShadow       = YES;

// display duration
static const NSTimeInterval ADRToastDefaultDuration  = 3.0;

// image view size
static const CGFloat ADRToastImageViewWidth      = 80.0;
static const CGFloat ADRToastImageViewHeight     = 80.0;

// activity
static const CGFloat ADRToastActivityWidth       = 100.0;
static const CGFloat ADRToastActivityHeight      = 100.0;
static const NSString * ADRToastActivityDefaultPosition = @"center";

// interaction
static const BOOL ADRToastHidesOnTap             = YES;     // excludes activity views

// associative reference keys
static const NSString * ADRToastTimerKey         = @"ADRToastTimerKey";
static const NSString * ADRToastActivityViewKey  = @"ADRToastActivityViewKey";
static const NSString * ADRToastTapCallbackKey   = @"ADRToastTapCallbackKey";

// positions
NSString * const ADRToastPositionTop             = @"top";
NSString * const ADRToastPositionCenter          = @"center";
NSString * const ADRToastPositionBottom          = @"bottom";

@interface UIView (ToastPrivate)

- (void)hideToast:(UIView *)toast;
- (void)toastTimerDidFinish:(NSTimer *)timer;
- (void)handleToastTapped:(UITapGestureRecognizer *)recognizer;
- (CGPoint)centerPointForPosition:(id)position withToast:(UIView *)toast;
- (UIView *)viewForMessage:(NSString *)message title:(NSString *)title image:(UIImage *)image;
- (CGSize)sizeForString:(NSString *)string font:(UIFont *)font constrainedToSize:(CGSize)constrainedSize lineBreakMode:(NSLineBreakMode)lineBreakMode;

@end


@implementation UIView (ADRToast)

#pragma mark - Toast Methods

+ (void)makeToast:(NSString *)message {
    NSArray *sortedWindows = [[UIApplication sharedApplication].windows sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"windowLevel" ascending:NO]]];
    [sortedWindows.firstObject makeToast:message];
}

- (void)makeToast:(NSString *)message {
    CGFloat duration = MIN((float)message.length*0.06 + 0.5, 5.0);
    [self makeToast:message duration:duration position:ADRToastActivityDefaultPosition];
}

- (void)makeToast:(NSString *)message position:(id)position {
    CGFloat duration = MIN((float)message.length*0.06 + 0.5, 5.0);
    [self makeToast:message duration:duration position:position];
}

- (void)makeToast:(NSString *)message duration:(NSTimeInterval)duration position:(id)position {
    UIView *toast = [self viewForMessage:message title:nil image:nil];
    [self showToast:toast duration:duration position:position];  
}

- (void)makeToast:(NSString *)message duration:(NSTimeInterval)duration position:(id)position title:(NSString *)title {
    UIView *toast = [self viewForMessage:message title:title image:nil];
    [self showToast:toast duration:duration position:position];  
}

- (void)makeToast:(NSString *)message duration:(NSTimeInterval)duration position:(id)position image:(UIImage *)image {
    UIView *toast = [self viewForMessage:message title:nil image:image];
    [self showToast:toast duration:duration position:position];  
}

- (void)makeToast:(NSString *)message duration:(NSTimeInterval)duration  position:(id)position title:(NSString *)title image:(UIImage *)image {
    UIView *toast = [self viewForMessage:message title:title image:image];
    [self showToast:toast duration:duration position:position];  
}

- (void)showToast:(UIView *)toast {
    [self showToast:toast duration:ADRToastDefaultDuration position:nil];
}


- (void)showToast:(UIView *)toast duration:(NSTimeInterval)duration position:(id)position {
    [self showToast:toast duration:duration position:position tapCallback:nil];
    
}


- (void)showToast:(UIView *)toast duration:(NSTimeInterval)duration position:(id)position
      tapCallback:(void(^)(void))tapCallback
{
    toast.center = [self centerPointForPosition:position withToast:toast];
    toast.alpha = 0.0;
    
    if (ADRToastHidesOnTap) {
        UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:toast action:@selector(handleToastTapped:)];
        [toast addGestureRecognizer:recognizer];
        toast.userInteractionEnabled = YES;
        toast.exclusiveTouch = YES;
    }
    
    [self addSubview:toast];
    
    [UIView animateWithDuration:ADRToastFadeDuration
                          delay:0.0
                        options:(UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction)
                     animations:^{
                         toast.alpha = 1.0;
                     } completion:^(BOOL finished) {
                         NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:duration target:self selector:@selector(toastTimerDidFinish:) userInfo:toast repeats:NO];
                         // associate the timer with the toast view
                         objc_setAssociatedObject (toast, &ADRToastTimerKey, timer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                         objc_setAssociatedObject (toast, &ADRToastTapCallbackKey, tapCallback, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                     }];
}


- (void)hideToast:(UIView *)toast {
    [UIView animateWithDuration:ADRToastFadeDuration
                          delay:0.0
                        options:(UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionBeginFromCurrentState)
                     animations:^{
                         toast.alpha = 0.0;
                     } completion:^(BOOL finished) {
                         [toast removeFromSuperview];
                     }];
}

#pragma mark - Events

- (void)toastTimerDidFinish:(NSTimer *)timer {
    [self hideToast:(UIView *)timer.userInfo];
}

- (void)handleToastTapped:(UITapGestureRecognizer *)recognizer {
    NSTimer *timer = (NSTimer *)objc_getAssociatedObject(self, &ADRToastTimerKey);
    [timer invalidate];
    
    void (^callback)(void) = objc_getAssociatedObject(self, &ADRToastTapCallbackKey);
    if (callback) {
        callback();
    }
    [self hideToast:recognizer.view];
}

#pragma mark - Toast Activity Methods

- (void)makeToastActivity {
    [self makeToastActivity:ADRToastActivityDefaultPosition];
}

- (void)makeToastActivity:(id)position {
    // sanity
    UIView *existingActivityView = (UIView *)objc_getAssociatedObject(self, &ADRToastActivityViewKey);
    if (existingActivityView != nil) return;
    
    UIView *activityView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ADRToastActivityWidth, ADRToastActivityHeight)];
    activityView.center = [self centerPointForPosition:position withToast:activityView];
    activityView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:ADRToastOpacity];
    activityView.alpha = 0.0;
    activityView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin);
    activityView.layer.cornerRadius = ADRToastCornerRadius;
    
    if (ADRToastDisplayShadow) {
        activityView.layer.shadowColor = [UIColor blackColor].CGColor;
        activityView.layer.shadowOpacity = ADRToastShadowOpacity;
        activityView.layer.shadowRadius = ADRToastShadowRadius;
        activityView.layer.shadowOffset = ADRToastShadowOffset;
    }
    
    UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityIndicatorView.center = CGPointMake(activityView.bounds.size.width / 2, activityView.bounds.size.height / 2);
    [activityView addSubview:activityIndicatorView];
    [activityIndicatorView startAnimating];
    
    // associate the activity view with self
    objc_setAssociatedObject (self, &ADRToastActivityViewKey, activityView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [self addSubview:activityView];
    
    [UIView animateWithDuration:ADRToastFadeDuration
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         activityView.alpha = 1.0;
                     } completion:nil];
}

- (void)hideToastActivity {
    UIView *existingActivityView = (UIView *)objc_getAssociatedObject(self, &ADRToastActivityViewKey);
    if (existingActivityView != nil) {
        [UIView animateWithDuration:ADRToastFadeDuration
                              delay:0.0
                            options:(UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionBeginFromCurrentState)
                         animations:^{
                             existingActivityView.alpha = 0.0;
                         } completion:^(BOOL finished) {
                             [existingActivityView removeFromSuperview];
                             objc_setAssociatedObject (self, &ADRToastActivityViewKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                         }];
    }
}

#pragma mark - Helpers

- (CGPoint)centerPointForPosition:(id)point withToast:(UIView *)toast {
    if([point isKindOfClass:[NSString class]]) {
        if([point caseInsensitiveCompare:ADRToastPositionTop] == NSOrderedSame) {
            return CGPointMake(self.bounds.size.width/2, (toast.frame.size.height / 2) + ADRToastVerticalPadding);
        } else if([point caseInsensitiveCompare:ADRToastPositionCenter] == NSOrderedSame) {
            return CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
        }
    } else if ([point isKindOfClass:[NSValue class]]) {
        return [point CGPointValue];
    }
    
    // default to bottom
    return CGPointMake(self.bounds.size.width/2, (self.bounds.size.height - (toast.frame.size.height / 2)) - ADRToastVerticalPadding);
}

- (CGSize)sizeForString:(NSString *)string font:(UIFont *)font constrainedToSize:(CGSize)constrainedSize lineBreakMode:(NSLineBreakMode)lineBreakMode {
    if ([string respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineBreakMode = lineBreakMode;
        NSDictionary *attributes = @{NSFontAttributeName:font, NSParagraphStyleAttributeName:paragraphStyle};
        CGRect boundingRect = [string boundingRectWithSize:constrainedSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil];
        return CGSizeMake(ceilf(boundingRect.size.width), ceilf(boundingRect.size.height));
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [string sizeWithFont:font constrainedToSize:constrainedSize lineBreakMode:lineBreakMode];
#pragma clang diagnostic pop
}

- (UIView *)viewForMessage:(NSString *)message title:(NSString *)title image:(UIImage *)image {
    // sanity
    if((message == nil) && (title == nil) && (image == nil)) return nil;

    // dynamically build a toast view with any combination of message, title, & image.
    UILabel *messageLabel = nil;
    UILabel *titleLabel = nil;
    UIImageView *imageView = nil;
    
    // create the parent view
    UIView *wrapperView = [[UIView alloc] init];
    wrapperView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin);
    wrapperView.layer.cornerRadius = ADRToastCornerRadius;
    
    if (ADRToastDisplayShadow) {
        wrapperView.layer.shadowColor = [UIColor blackColor].CGColor;
        wrapperView.layer.shadowOpacity = ADRToastShadowOpacity;
        wrapperView.layer.shadowRadius = ADRToastShadowRadius;
        wrapperView.layer.shadowOffset = ADRToastShadowOffset;
    }

    wrapperView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:ADRToastOpacity];
    
    if(image != nil) {
        imageView = [[UIImageView alloc] initWithImage:image];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.frame = CGRectMake(ADRToastHorizontalPadding, ADRToastVerticalPadding, ADRToastImageViewWidth, ADRToastImageViewHeight);
    }
    
    CGFloat imageWidth, imageHeight, imageLeft;
    
    // the imageView frame values will be used to size & position the other views
    if(imageView != nil) {
        imageWidth = imageView.bounds.size.width;
        imageHeight = imageView.bounds.size.height;
        imageLeft = ADRToastHorizontalPadding;
    } else {
        imageWidth = imageHeight = imageLeft = 0.0;
    }
    
    if (title != nil) {
        titleLabel = [[UILabel alloc] init];
        titleLabel.numberOfLines = ADRToastMaxTitleLines;
        titleLabel.font = [UIFont boldSystemFontOfSize:ADRToastFontSize];
        titleLabel.textAlignment = NSTextAlignmentLeft;
        titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.alpha = 1.0;
        titleLabel.text = title;
        
        // size the title label according to the length of the text
        CGSize maxSizeTitle = CGSizeMake((self.bounds.size.width * ADRToastMaxWidth) - imageWidth, self.bounds.size.height * ADRToastMaxHeight);
        CGSize expectedSizeTitle = [self sizeForString:title font:titleLabel.font constrainedToSize:maxSizeTitle lineBreakMode:titleLabel.lineBreakMode];
        titleLabel.frame = CGRectMake(0.0, 0.0, expectedSizeTitle.width, expectedSizeTitle.height);
    }
    
    if (message != nil) {
        messageLabel = [[UILabel alloc] init];
        messageLabel.numberOfLines = ADRToastMaxMessageLines;
        messageLabel.font = [UIFont systemFontOfSize:ADRToastFontSize];
        messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
        messageLabel.textColor = [UIColor whiteColor];
        messageLabel.backgroundColor = [UIColor clearColor];
        messageLabel.alpha = 1.0;
        messageLabel.text = message;
        
        // size the message label according to the length of the text
        CGSize maxSizeMessage = CGSizeMake((self.bounds.size.width * ADRToastMaxWidth) - imageWidth, self.bounds.size.height * ADRToastMaxHeight);
        CGSize expectedSizeMessage = [self sizeForString:message font:messageLabel.font constrainedToSize:maxSizeMessage lineBreakMode:messageLabel.lineBreakMode];
        messageLabel.frame = CGRectMake(0.0, 0.0, expectedSizeMessage.width, expectedSizeMessage.height);
    }
    
    // titleLabel frame values
    CGFloat titleWidth, titleHeight, titleTop, titleLeft;
    
    if(titleLabel != nil) {
        titleWidth = titleLabel.bounds.size.width;
        titleHeight = titleLabel.bounds.size.height;
        titleTop = ADRToastVerticalPadding;
        titleLeft = imageLeft + imageWidth + ADRToastHorizontalPadding;
    } else {
        titleWidth = titleHeight = titleTop = titleLeft = 0.0;
    }
    
    // messageLabel frame values
    CGFloat messageWidth, messageHeight, messageLeft, messageTop;

    if(messageLabel != nil) {
        messageWidth = messageLabel.bounds.size.width;
        messageHeight = messageLabel.bounds.size.height;
        messageLeft = imageLeft + imageWidth + ADRToastHorizontalPadding;
        messageTop = titleTop + titleHeight + ADRToastVerticalPadding;
    } else {
        messageWidth = messageHeight = messageLeft = messageTop = 0.0;
    }

    CGFloat longerWidth = MAX(titleWidth, messageWidth);
    CGFloat longerLeft = MAX(titleLeft, messageLeft);
    
    // wrapper width uses the longerWidth or the image width, whatever is larger. same logic applies to the wrapper height
    CGFloat wrapperWidth = MAX((imageWidth + (ADRToastHorizontalPadding * 2)), (longerLeft + longerWidth + ADRToastHorizontalPadding));    
    CGFloat wrapperHeight = MAX((messageTop + messageHeight + ADRToastVerticalPadding), (imageHeight + (ADRToastVerticalPadding * 2)));
                         
    wrapperView.frame = CGRectMake(0.0, 0.0, wrapperWidth, wrapperHeight);
    
    if(titleLabel != nil) {
        titleLabel.frame = CGRectMake(titleLeft, titleTop, titleWidth, titleHeight);
        [wrapperView addSubview:titleLabel];
    }
    
    if(messageLabel != nil) {
        messageLabel.frame = CGRectMake(messageLeft, messageTop, messageWidth, messageHeight);
        [wrapperView addSubview:messageLabel];
    }
    
    if(imageView != nil) {
        [wrapperView addSubview:imageView];
    }
        
    return wrapperView;
}

@end
