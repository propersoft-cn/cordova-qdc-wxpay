//
//  CDVWxpay.m
//  cordova-plugin-wxpay
//
//  Created by tong.wu on 06/30/15.
//
//

#import "CDVWxpay.h"

@implementation CDVWxpay

#pragma mark "API"

- (void)payment:(CDVInvokedUrlCommand *)command
{
    [self.commandDelegate runInBackground:^{
        // check arguments
        NSDictionary *params = [command.arguments objectAtIndex:0];
        if (!params)
        {
            [self failWithCallbackID:command.callbackId withMessage:@"参数格式错误"];
            return ;
        }
        
        NSString *appid = nil;
        NSString *noncestr = nil;
        NSString *package = nil;
        NSString *partnerid = nil;
        NSString *prepayid = nil;
        NSString *timestamp = nil;
        NSString *sign = nil;
        
        // check the params
        if (![params objectForKey:@"appid"])
        {
            [self failWithCallbackID:command.callbackId withMessage:@"appid参数错误"];
            return ;
        }
        appid = [params objectForKey:@"appid"];

        if (![params objectForKey:@"noncestr"])
        {
            [self failWithCallbackID:command.callbackId withMessage:@"noncestr参数错误"];
            return ;
        }
        noncestr = [params objectForKey:@"noncestr"];

        if (![params objectForKey:@"package"])
        {
            [self failWithCallbackID:command.callbackId withMessage:@"package参数错误"];
            return ;
        }
        package = [params objectForKey:@"package"];

        if (![params objectForKey:@"partnerid"])
        {
            [self failWithCallbackID:command.callbackId withMessage:@"partnerid参数错误"];
            return ;
        }
        partnerid = [params objectForKey:@"partnerid"];

        if (![params objectForKey:@"prepayid"])
        {
            [self failWithCallbackID:command.callbackId withMessage:@"prepayid参数错误"];
            return ;
        }
        prepayid = [params objectForKey:@"prepayid"];

        if (![params objectForKey:@"timestamp"])
        {
            [self failWithCallbackID:command.callbackId withMessage:@"timestamp参数错误"];
            return ;
        }
        timestamp = [params objectForKey:@"timestamp"];

        if (![params objectForKey:@"sign"])
        {
            [self failWithCallbackID:command.callbackId withMessage:@"sign参数错误"];
            return ;
        }
        sign = [params objectForKey:@"sign"];
		
        // 在应用启动时会向微信注册，这里取消注册
        //[WXApi registerApp:appid];
        
        if (![WXApi isWXAppInstalled]) {
            [self failWithCallbackID:command.callbackId withMessage:@"未安装微信"];
            return;
        }
    
        PayReq *req = [[PayReq alloc] init];
        req.openID = appid;
        req.partnerId = partnerid;
        req.prepayId = prepayid;
        req.nonceStr = noncestr;
        req.timeStamp = timestamp.intValue;
        req.package = package;
        req.sign = sign;
        
        [WXApi sendReq:req];
        //日志输出
        NSLog(@"\nappid=%@\npartid=%@\nprepayid=%@\nnoncestr=%@\ntimestamp=%ld\npackage=%@\nsign=%@",req.openID,req.partnerId,req.prepayId,req.nonceStr,(long)req.timeStamp,req.package,req.sign );

        // save the callback id
        self.currentCallbackId = command.callbackId;
        
    }];
}

- (void)registerApp:(NSString *)wechatAppId
{
    self.wechatAppId = wechatAppId;
    
    [WXApi registerApp:wechatAppId];
    
    NSLog(@"Register wechat app: %@", wechatAppId);
}

#pragma mark "WXApiDelegate"

/**
 * Not implemented
 */
- (void)onReq:(BaseReq *)req
{
    NSLog(@"%@", req);
}
- (NSString *) jsonStringWithDictionary:(NSDictionary *) dictionary {
    
    NSString *jsonString = nil;
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        NSLog(@"Got an error: %@", error);
        jsonString = nil;
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    return jsonString;
}
- (void)onResp:(BaseResp *)resp
{
   
    CDVPluginResult *commandResult = nil;
    NSMutableDictionary* dicRtn=[[NSMutableDictionary alloc]init];
    [dicRtn setValue:[NSNumber numberWithInteger:resp.errCode] forKey:@"code"];
    NSString *errStr=@"";
    if(resp.errStr!=nil){
        errStr=resp.errStr;
    }
    [dicRtn setValue:errStr forKey:@"errStr"];
    NSString *strMsg = [self jsonStringWithDictionary:dicRtn];
    commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:strMsg];
    
    
    [self.commandDelegate sendPluginResult:commandResult callbackId:self.currentCallbackId];
    
    self.currentCallbackId = nil;
}

#pragma mark "CDVPlugin Overrides"

- (void)handleOpenURL:(NSNotification *)notification
{
    NSURL* url = [notification object];
    
    if ([url isKindOfClass:[NSURL class]] && [url.scheme isEqualToString:self.wechatAppId])
    {
        [WXApi handleOpenURL:url delegate:self];
    }
}

#pragma mark "Private methods"

- (NSData *)getNSDataFromURL:(NSString *)url
{
    NSData *data = nil;
    
    if ([url hasPrefix:@"http://"] || [url hasPrefix:@"https://"])
    {
        data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
    }else if([url containsString:@"temp:"]){
        url =  [NSTemporaryDirectory() stringByAppendingPathComponent:[url componentsSeparatedByString:@"temp:"][1]];
        data = [NSData dataWithContentsOfFile:url];
    }
    else
    {
        // local file
        url = [[NSBundle mainBundle] pathForResource:[url stringByDeletingPathExtension] ofType:[url pathExtension]];
        data = [NSData dataWithContentsOfFile:url];
    }
    
    return data;
}

- (UIImage *)getUIImageFromURL:(NSString *)url
{
    NSData *data = [self getNSDataFromURL:url];
    return [UIImage imageWithData:data];
}

- (void)successWithCallbackID:(NSString *)callbackID
{
    [self successWithCallbackID:callbackID withMessage:@"OK"];
}

- (void)successWithCallbackID:(NSString *)callbackID withMessage:(NSString *)message
{
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:message];
    [self.commandDelegate sendPluginResult:commandResult callbackId:callbackID];
}

- (void)failWithCallbackID:(NSString *)callbackID withError:(NSError *)error
{
    [self failWithCallbackID:callbackID withMessage:[error localizedDescription]];
}

- (void)failWithCallbackID:(NSString *)callbackID withMessage:(NSString *)message
{
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:message];
    [self.commandDelegate sendPluginResult:commandResult callbackId:callbackID];
}

@end