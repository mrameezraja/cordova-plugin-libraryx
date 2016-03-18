
#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>

@interface LibraryX : CDVPlugin

- (void)showGallery:(CDVInvokedUrlCommand*)command;
- (void)getAsync:(CDVInvokedUrlCommand*)command;

@end
