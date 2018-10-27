//
//  ViewController.m
//  JavaScript

#import "ViewController.h"
#import <WebKit/WebKit.h>

@interface ViewController ()<UIWebViewDelegate,WKUIDelegate,WKNavigationDelegate,WKScriptMessageHandler>

@property (nonatomic,strong) WKWebView * webView;

@property (nonatomic, strong) UIProgressView *progressView;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    [self initUIWebView:WKType];
}

#pragma mark - UIWebView
- (void)initUIWebView:(WebViewType)type
{
    NSString * resource = type == WKType ? @"WKWebView" : @"index";
    NSString * path = [[NSBundle mainBundle] pathForResource:resource ofType:@"html"];
    NSURL * url = [NSURL fileURLWithPath:path];
    NSURLRequest * request = [NSURLRequest requestWithURL:url] ;
    
    if (type == UIType)
    {
        UIWebView * webView = [[UIWebView alloc]initWithFrame:CGRectMake(0, 20, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 20)];
        webView.delegate = self;
        webView.backgroundColor = [UIColor yellowColor];
        [self.view addSubview:webView];
        
        [webView loadRequest:request];
    }
    else
    {
        [self initWKWebView];
        [self.webView loadRequest:request];
    }
}

#pragma mark - UIWebViewDelegate
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    self.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    NSLog(@"title - %@",self.title);
    
    self.jsContext = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    self.jsContext[@"iOSDelegate"] = self;
    self.jsContext.exceptionHandler = ^(JSContext *context, JSValue *exceptionValue)
    {
        context.exception = exceptionValue;
        NSLog(@"异常信息：%@", exceptionValue);
    };
    
    //不生成方法 无需再.h声明方法
    self.jsContext[@"startFunction"] = ^(id obj){
        
        [JSContext currentContext];

        NSData * data = [(NSString *)obj dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary * dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        
        NSLog(@"姓名:%@ - 年龄:%@",dict[@"title"],dict[@"age"]);
        
//        NSString * param = @"";
//        [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.getElementById('token').value='%@'",param]];
    };
}

- (void)callbackFinish
{
    NSLog(@"callbackFinish");
    
    // 之后在回调js的方法Callback把内容传出去
    JSValue * callback = self.jsContext[@"Callback"];
    
    //传值给web端
    [callback callWithArguments:@[@"唤起OC - 回调完成"]];
}

- (void)receiveJSAndCallBackNil:(NSString *)string
{
    NSLog(@"receiveJS:%@", string);
    
    // 成功回调js的方法Callback
    JSValue *Callback = self.jsContext[@"alerCallback"];
    [Callback callWithArguments:nil];
}

- (void)OC_ADD_JS_Alert
{
    NSLog(@"交互3响应");
    
    NSString * str = @"alert('OC添加JS提示成功')";
    [self.jsContext evaluateScript:str];
}

/*
 iOS 8.0 中引入的新组件WKWebView
 https://www.jianshu.com/p/20cfd4f8c4ff
 
 1.内存占用是UIWebView的1/4~1/3
 2.页面加载速度有提升，有的文章说它的加载速度比UIWebView提升了一倍左右。
 3.更为细致地拆分了 UIWebViewDelegate 中的方法
 4.自带进度条。不需要像UIWebView一样自己做假进度条（通过NJKWebViewProgress和双层代理技术实现），技术复杂度和代码量，根贴近实际加载进度优化好的多。
 5.允许JavaScript的Nitro库加载并使用（UIWebView中限制）
 6.可以和js直接互调函数，不像UIWebView需要第三方库WebViewJavascriptBridge来协助处理和js的交互。
 7.不支持页面缓存，需要自己注入cookie,而UIWebView是自动注入cookie。
 8.无法发送POST参数问题
 */

#pragma mark - WKWebView
- (void)initWKWebView
{
    //JS配置
//    [wkUsercc addScriptMessageHandler:self name:@"JS_Function_Name"];
    
    //移除
//    [wkUsercc removeScriptMessageHandlerForName:@"JS_Function_Name"];
    
    //WKWebView配置
    WKWebViewConfiguration * configuration = [[WKWebViewConfiguration alloc]init];
    [configuration.userContentController addScriptMessageHandler:self name:@"webViewApp"];
    configuration.preferences.minimumFontSize = 40;
    //显示
    WKWebView * wkWebView = [[WKWebView alloc]initWithFrame:CGRectMake(0, 20, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 20) configuration:configuration];
    wkWebView.UIDelegate = self;
    wkWebView.navigationDelegate = self;
    [self.view addSubview:wkWebView];
    _webView = wkWebView;
    
//    [wkWebView loadRequest:[[NSURLRequest alloc] initWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"WKWebView" ofType:@"html"]]]];
    
//    iOS调用JS直接使用WKWebView的[webView evaluateJavaScript:@"JS函数名称('参数1','参数2')" completionHandler:nil]来向JS发送消息。
}

//直接调用js
//webView.evaluateJavaScript("hi()", completionHandler: nil)

//调用js带参数
//webView.evaluateJavaScript("hello('liuyanwei')", completionHandler: nil)

//调用js获取返回值
//webView.evaluateJavaScript("getName()") { (any,error) -> Void in
//    NSLog("%@", any as! String)
//}

#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    //收到JS回执脚本就会执行一次
    NSLog(@"收到 name:%@,body:%@",message.name,message.body);
    
    NSDictionary * dict = message.body;
    NSString * method = [dict objectForKey:@"method"];
    
    if ([method isEqualToString:@"hello"])
    {
        NSLog(@"%@",dict[@"param1"]);
    }
    else if ([method isEqualToString:@"Call JS"])
    {
        [self.webView evaluateJavaScript:@"iOSCallJSON()" completionHandler:nil];
    }
    else if ([method isEqualToString:@"Call JS Msg"])
    {
        [self.webView evaluateJavaScript:@"iOSCallJS('你猜猜')" completionHandler:nil];
    }
}

#pragma mark - WKUIDelegate
-(void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    //页面开始加载
    
}

-(void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation
{
    //开始获取到网页内容时返回
    
}

-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    //页面加载完成之后调用
    NSLog(@"didFinishNavigation");
    
    if (webView.title.length > 0)
    {
        NSLog(@"title - %@",webView.title);
        self.title = webView.title;
    }
}

-(void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    //页面加载失败时调用
    
}

// 接收到服务器跳转请求之后调用

//- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation;

// 在收到响应后，决定是否跳转

//- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler;

// 在发送请求之前，决定是否跳转

//- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler;

#pragma mark - WKUIDelegate - alert
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler
{
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:message message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
        completionHandler();
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"sure" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        completionHandler();
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

// JS端调用confirm函数时，会触发此方法，通过message可以拿到JS端所传的数据，在iOS端显示原生alert得到YES/NO后，通过completionHandler回调给JS端
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler
{
    NSLog(@"message = %@",message);
}

#pragma mark - WKUIDelegate - textInput
-(void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler
{
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:prompt message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        
        textField.placeholder = defaultText;
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        UITextField * textField = alert.textFields.firstObject;
        completionHandler(textField.text);
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - WKNavigationDelegate
//让JS打开新的web页面，在WKWebView的WKNavigationDelegate协议中,判断要打开的新的web页面是否是含有你需要的东西，如果有需要就截获，不打开并且进行本地操作。
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
//    NSString * url = navigationAction.request.URL.absoluteString;
    
    if (decisionHandler)
    {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

- (void)dealloc
{
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"estimatedProgress"])
    {
        self.progressView.progress = self.webView.estimatedProgress;
        if (self.progressView.progress == 1)
        {
            __weak typeof (self) weakSelf = self;
            [UIView animateWithDuration:0.25f delay:0.3f options:UIViewAnimationOptionCurveEaseOut animations:^
             {
                 weakSelf.progressView.transform = CGAffineTransformMakeScale(1.0f, 1.4f);
             }
                             completion:^(BOOL finished)
             {
                 weakSelf.progressView.hidden = YES;
             }];
        }
    }
}

//- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
//{
//    self.progressView.hidden = NO;
//    self.progressView.transform = CGAffineTransformMakeScale(1.0f, 1.5f);
//    [self.view bringSubviewToFront:self.progressView];
//}
//
//- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
//{
//    self.progressView.hidden = YES;
//}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    if(error.code==NSURLErrorCancelled)
    {
        [self webView:webView didFinishNavigation:navigation];
    }
    else
    {
        self.progressView.hidden = YES;
    }
}

- (UIProgressView *)progressView
{
    if (!_progressView)
    {
        
        _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 2)];
        _progressView.backgroundColor = [UIColor blueColor];
        _progressView.transform = CGAffineTransformMakeScale(1.0f, 1.5f);
        _progressView.progressTintColor = [UIColor greenColor];
        [self.view addSubview:self.progressView];
    }
    return _progressView;
}


@end
