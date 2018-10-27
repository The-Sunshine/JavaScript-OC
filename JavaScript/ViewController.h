//
//  ViewController.h
//  JavaScript


#import <UIKit/UIKit.h>
#import <JavaScriptCore/JavaScriptCore.h>

typedef NS_ENUM(NSInteger ,WebViewType)
{
    UIType,
    WKType
};

@protocol JSObjcDelegate <JSExport>

- (void)callbackFinish;
- (void)receiveJSAndCallBackNil:(NSString *)string;
- (void)OC_ADD_JS_Alert;

@end
@interface ViewController : UIViewController<JSObjcDelegate>

@property (nonatomic, strong) JSContext *jsContext;

@end

