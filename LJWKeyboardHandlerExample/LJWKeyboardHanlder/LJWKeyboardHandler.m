//
//  LJWKeyboardHandler.m
//  Parking
//
//  Created by ljw on 15/5/17.
//  Copyright (c) 2015年 Mark. All rights reserved.
//

#import "LJWKeyboardHandler.h"
#import "UIWindow+LJWPresentViewController.h"
#import "UIView+FirstResponderNotification.h"
#import "LJWKeyboardToolBar.h"
#import "UIView+FindOutViews.h"

@interface LJWKeyboardHandler () <LJWKeyboardToolBarDelegate>

/**
 *  键盘是否出现
 */
@property (nonatomic, assign) BOOL isKeyboardShowing;

/**
 *  是否是原始位置
 */
@property (nonatomic, assign) BOOL isOrigin;

/**
 *  键盘的frame
 */
@property (nonatomic, assign) CGRect keyboardFrame;

/**
 *  第一响应者
 */
@property (nonatomic, strong) UIView *firstResponder;

/**
 *  需要被调整的视图
 *  目前只支持vc.view,所以没有开放设置。
 */
@property (nonatomic, strong) UIView *viewNeedsToBeReset;

/**
 *  键盘的accessoryView
 */
@property (nonatomic, strong) LJWKeyboardToolBar *ljwKeyboardToolBar;

@end

@implementation LJWKeyboardHandler

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        [self startHandling];
        self.assistantHeight = 10.f;
        self.shouldShowKeyboardToolBar = YES;
    }
    return self;
}

- (UIToolbar *)ljwKeyboardToolBar
{
    if (!_ljwKeyboardToolBar) {
        _ljwKeyboardToolBar = [[LJWKeyboardToolBar alloc] initWithFrame:CGRectMake(0, 0, [UIApplication sharedApplication].keyWindow.frame.size.width, 44)];
        _ljwKeyboardToolBar.ljwKeyboardDelegate = self;
        
        //添加当前view里所有会弹键盘的responder
        _ljwKeyboardToolBar.responders = [[UIApplication sharedApplication].keyWindow.presentViewController.view findOutViews:@[[UITextField class], [UITextView class], [UISearchBar class]]];

    }
    
    return _ljwKeyboardToolBar;
}

- (void)setFirstResponder:(UIView *)firstResponder
{
    
    if (_firstResponder == firstResponder) {
        return;
    }
    
    _firstResponder = firstResponder;
    
    if (self.shouldShowKeyboardToolBar) {
        
        if (!_firstResponder.inputAccessoryView) {
            
            if ([_firstResponder respondsToSelector:@selector(setInputAccessoryView:)]) {
                [_firstResponder performSelector:@selector(setInputAccessoryView:) withObject:self.ljwKeyboardToolBar];
            }
            
        }
        
        self.ljwKeyboardToolBar.currentResponder = firstResponder;
        
    }
    else
    {
        if ([_firstResponder respondsToSelector:@selector(setInputAccessoryView:)]) {
            [_firstResponder performSelector:@selector(setInputAccessoryView:) withObject:nil];
        }
    }

    
}

- (UIView *)viewNeedsToBeReset
{
    if (!_viewNeedsToBeReset) {
        _viewNeedsToBeReset = [UIApplication sharedApplication].keyWindow.presentViewController.view;
    }
    return _viewNeedsToBeReset;
}


- (void)startHandling
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willKeyboardShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willKeyboardHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFirstResponderChanged:) name:LJWFirstResponderChanged object:nil];
}

- (void)stopHandling
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LJWFirstResponderChanged object:nil];
}

- (void)willKeyboardShow:(NSNotification *)notification
{
    self.isKeyboardShowing = YES;
    
    self.keyboardFrame = [notification.userInfo[@"UIKeyboardFrameEndUserInfoKey"] CGRectValue];
    
    [self resetTheViewNeedsToBeResetAppropraitly];
    
}

- (void)willKeyboardHide:(NSNotification *)notification
{
    self.isKeyboardShowing = NO;
    
    self.keyboardFrame = [notification.userInfo[@"UIKeyboardFrameEndUserInfoKey"] CGRectValue];
    
    [self resetTheViewNeedsToBeResetAppropraitly];
    
}

- (void)resetTheViewNeedsToBeResetAppropraitly
{
    
//    NSLog(@"%@", NSStringFromCGRect(self.firstResponder.frame));
    
    UIView *tempSuperView = [[UIView alloc] initWithFrame:self.viewNeedsToBeReset.frame];
    UIView *tempSuberView = [[UIView alloc] initWithFrame:self.firstResponder.frame];
    
    tempSuberView.frame = [self.firstResponder convertRect:self.firstResponder.bounds toView:self.viewNeedsToBeReset];
    
    [tempSuperView addSubview:tempSuberView];
    [self.firstResponder.window addSubview:tempSuperView];
    
    CGRect firstResponderFrameInWindow = [tempSuberView convertRect:tempSuberView.bounds toView:self.firstResponder.window];
    
    [tempSuperView removeFromSuperview];
    
    if (self.firstResponder) {
        
        if (self.keyboardFrame.origin.y < firstResponderFrameInWindow.origin.y + firstResponderFrameInWindow.size.height + self.assistantHeight) {
            
            [self addBoundsChangeAnimationFrome:self.viewNeedsToBeReset.bounds to:CGRectMake(0, (firstResponderFrameInWindow.origin.y + firstResponderFrameInWindow.size.height - self.keyboardFrame.origin.y + self.assistantHeight), self.viewNeedsToBeReset.frame.size.width, self.viewNeedsToBeReset.frame.size.height) inView:self.viewNeedsToBeReset];
            
            self.isOrigin = NO;
            
        }
        else
        {
            [self setOrigin];
        }
        
    }
    else
    {
        [self setOrigin];
    }
    
}

- (void)setOrigin
{
    if (self.isOrigin) {
        return;
    }
    
    [self addBoundsChangeAnimationFrome:self.viewNeedsToBeReset.bounds to:CGRectMake(0, 0, self.viewNeedsToBeReset.bounds.size.width, self.viewNeedsToBeReset.bounds.size.height) inView:self.viewNeedsToBeReset];
    
    self.isOrigin = YES;
}

- (void)addBoundsChangeAnimationFrome:(CGRect)from to:(CGRect)to inView:(UIView *)view
{
    
    [UIView animateWithDuration:0.25 animations:^{
        view.bounds = to;
    }];

}

- (void)dealloc
{
//    NSLog(@"%@ dealloc", self);
    [self stopHandling];
}

#pragma mark - 如果缺少类目请使用此方法获取presentViewController
/**
 *  递归获取当前展示的viewController请传入keywindow的根视图控制器
 *
 *  @param currentViewController 当前的vc
 *
 *  @return presentVC
 */
- (UIViewController *)getPresentViewController:(UIViewController *)currentViewController
{
    
    if ([currentViewController isKindOfClass:[UINavigationController class]]) {
        return [self getPresentViewController:[(UINavigationController *)currentViewController topViewController]];
    }
    
    if ([currentViewController isKindOfClass:[UITabBarController class]]) {
        return [self getPresentViewController:[(UITabBarController *)currentViewController selectedViewController]];
    }
    
    if ([currentViewController presentingViewController]) {
        return [self getPresentViewController:[currentViewController presentingViewController]];
    }
    
    return currentViewController;
}

+ (instancetype)shareHandler
{
    static LJWKeyboardHandler *s_Handler = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_Handler = [[LJWKeyboardHandler alloc] init];
    });
    
    return s_Handler;
}

- (void)didFirstResponderChanged:(NSNotification *)notification
{
    
    if (self.firstResponder == notification.userInfo[@"firstResponder"]) {
        return;
    }
    
    self.firstResponder = notification.userInfo[@"firstResponder"];
    
    if (self.isKeyboardShowing) {
        [self resetTheViewNeedsToBeResetAppropraitly];
    }

}

#pragma mark - LJWKeyboardToolBarDelegate

@end
