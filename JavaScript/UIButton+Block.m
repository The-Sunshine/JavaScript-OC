//
//  UIButton+Block.m
//  JavaScript
//


#import "UIButton+Block.h"
#import <objc/runtime.h>

@implementation UIButton (Block)

/*
 objc_setAssociatedObject 相当于 setValue:forKey 进行关联value对象
 
 objc_getAssociatedObject 用来读取对象
 
 objc_AssociationPolicy  属性 是设定该value在object内的属性，即 assgin, (retain,nonatomic)...等
 
 objc_removeAssociatedObjects 函数来移除一个关联对象，或者使用objc_setAssociatedObject函数将key指定的关联对象设置为nil。
 
 -------------------------
 
 objc_setAssociatedObject(<#id  _Nonnull object#>, <#const void * _Nonnull key#>, id  _Nullable value, objc_AssociationPolicy policy)
 
 key：要保证全局唯一，key与关联的对象是一一对应关系。必须全局唯一。通常用@selector(methodName)作为key。
 value：要关联的对象。
 policy：关联策略。有五种关联策略。
 OBJC_ASSOCIATION_ASSIGN 等价于 @property(assign)。
 OBJC_ASSOCIATION_RETAIN_NONATOMIC等价于 @property(strong, nonatomic)。
 OBJC_ASSOCIATION_COPY_NONATOMIC等价于@property(copy, nonatomic)。
 OBJC_ASSOCIATION_RETAIN等价于@property(strong,atomic)。
 OBJC_ASSOCIATION_COPY等价于@property(copy, atomic)。
 
 */
-(void)handleBlock:(btnBlock)block
{
    if (block) {
        objc_setAssociatedObject(self, @selector(btnAction:), block, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [self addTarget:self action:@selector(btnAction:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)btnAction:(id)sender
{
    btnBlock block = objc_getAssociatedObject(self, _cmd);
    if (block) {
        block(sender);
    }
}




@end
