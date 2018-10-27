//
//  UIButton+Block.h
//  JavaScript
//

#import <UIKit/UIKit.h>

typedef void (^btnBlock)(id sender);

@interface UIButton (Block)

- (void)handleBlock:(btnBlock)block;

@end

