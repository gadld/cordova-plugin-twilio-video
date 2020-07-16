#import "TwilioVideoPlugin.h"
#import <AVFoundation/AVFoundation.h>

@implementation TwilioVideoPlugin

#pragma mark - Plugin Initialization
- (void)pluginInitialize
{
    [[TwilioVideoManager getInstance] setEventDelegate:self];
}

- (void)openRoom:(CDVInvokedUrlCommand*)command {
    self.listenerCallbackID = command.callbackId;
    NSArray *args = command.arguments;
    NSString* token = args[0];
    NSString* room = args[1];
    TwilioVideoConfig *config = [[TwilioVideoConfig alloc] init];
    if ([args count] > 2) {
        [config parse: command.arguments[2]];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"TwilioVideo" bundle:nil];
        self.twilioVc = [sb instantiateViewControllerWithIdentifier:@"TwilioVideoViewController"];

        self.twilioVc.config = config;

        self.twilioVc.view.backgroundColor = [UIColor clearColor];
        self.twilioVc.modalPresentationStyle = UIModalPresentationPopover;
        
        [self.viewController addChildViewController:self.twilioVc];
        [self.twilioVc connectToRoom:room token:token];
        
        self.twilioVc.view.frame = self.viewController.view.frame;//[self frameForContentController];
        [self.viewController.view addSubview:self.twilioVc.view];
        [self.twilioVc didMoveToParentViewController:self.viewController];
        
//        [self.viewController presentViewController:vc animated:NO completion:^{
//            [vc connectToRoom:room token:token];
//        }];
    });
}

- (void)closeRoom:(CDVInvokedUrlCommand*)command {
    [self.twilioVc.view removeFromSuperview];
    
    if ([[TwilioVideoManager getInstance] publishDisconnection]) {
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
    } else {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Twilio video is not running"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }
}

- (void)hasRequiredPermissions:(CDVInvokedUrlCommand*)command {
    BOOL hasRequiredPermissions = [TwilioVideoPermissions hasRequiredPermissions];
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:hasRequiredPermissions] callbackId:command.callbackId];
}

- (void)requestPermissions:(CDVInvokedUrlCommand*)command {
    [TwilioVideoPermissions requestRequiredPermissions:^(BOOL grantedPermissions) {
                     [self.commandDelegate sendPluginResult:
         [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:grantedPermissions]
                                    callbackId:command.callbackId];
    }];
}

#pragma mark - TwilioVideoEventProducerDelegate

- (void)onCallEvent:(NSString *)event with:(NSDictionary*)data {
    if (!self.listenerCallbackID) {
        NSLog(@"Listener callback unavailable.  event %@", event);
        return;
    }
    
    if (data != NULL) {
        NSLog(@"Event received %@ with data %@", event, data);
    } else {
        NSLog(@"Event received %@", event);
    }
    
    NSMutableDictionary *message = [NSMutableDictionary dictionary];
    [message setValue:event forKey:@"event"];
    [message setValue:data != NULL ? data : [NSNull null] forKey:@"data"];
    
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:message];
    [result setKeepCallbackAsBool:YES];
    
    [self.commandDelegate sendPluginResult:result callbackId:self.listenerCallbackID];
}

@end
