

//
//  AuthInfo.m
//
//  Created by Rameez Raja <mrameezraja@gmail.com> on 3/7/16.
//
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AssetsLibrary/ALAssetRepresentation.h>
#import <CoreLocation/CoreLocation.h>
#import "LibraryX.h"

@implementation LibraryX

+ (ALAssetsLibrary *)defaultAssetsLibrary {
   static dispatch_once_t pred = 0;
   static ALAssetsLibrary *library = nil;
   dispatch_once(&pred, ^{
     library = [[ALAssetsLibrary alloc] init];
   });

   // TODO: Dealloc this later?
   return library;
 }

- (void)showGallery:(CDVInvokedUrlCommand*)command
{
    NSLog(@"showGallery");
    ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
    LibraryX* weakSelf = self;
    [self.commandDelegate runInBackground:^{
        [assetLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            if(group)
            {
                NSArray *photoArray = [self getContentFrom:group withAssetFilter:[ALAssetsFilter allPhotos]];
                //NSLog(@"photoArray: %lu", (unsigned long)[photoArray count]);
                //NSLog(@"photoArray: %@", photoArray);
                NSSortDescriptor *sortDescriptor;
                sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
                NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
                NSArray *sortedArray = [photoArray sortedArrayUsingDescriptors:sortDescriptors];
                // now convert date to string if not it will throw json exception
                for (NSMutableDictionary *photo in sortedArray) {
                    //NSLog(@"photo: %@", photo);
                    [photo setObject: [weakSelf dateToString:[photo objectForKey:@"date"]] forKey:@"date"];
                }

                CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:sortedArray];
                [weakSelf.commandDelegate sendPluginResult:result callbackId:command.callbackId];

            }
        } failureBlock:^(NSError *error) {
            NSLog(@"Error Description %@",[error description]);
            if (error.code == ALAssetsLibraryAccessUserDeniedError) {
                NSLog(@"not authorized");

                NSString* settingsButton = (&UIApplicationOpenSettingsURLString != NULL)
                ? NSLocalizedString(@"Settings", nil)
                : nil;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[[UIAlertView alloc] initWithTitle:[[NSBundle mainBundle]
                                                         objectForInfoDictionaryKey:@"CFBundleDisplayName"]
                                                message:NSLocalizedString(@"Access to the Photos has been prohibited; please enable it in the Settings app to continue.", nil)
                                               delegate:self
                                      cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                      otherButtonTitles:settingsButton, nil] show];
                });

            }
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }];
    }];

}

- (void)getAsync:(CDVInvokedUrlCommand*)command
{
    /*ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
    if (status != ALAuthorizationStatusAuthorized)
    {
        NSLog(@"not authorized");

        NSString* settingsButton = (&UIApplicationOpenSettingsURLString != NULL)
        ? NSLocalizedString(@"Settings", nil)
        : nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[UIAlertView alloc] initWithTitle:[[NSBundle mainBundle]
                                                 objectForInfoDictionaryKey:@"CFBundleDisplayName"]
                                        message:NSLocalizedString(@"Access to the Photos has been prohibited; please enable it in the Settings app to continue.", nil)
                                       delegate:self
                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                              otherButtonTitles:settingsButton, nil] show];
        });
    }*/

  // Grab the asset library
  ALAssetsLibrary *library = [LibraryX defaultAssetsLibrary];

  // Run a background job
  [self.commandDelegate runInBackground:^{

    // Enumerate all of the group saved photos, which is our Camera Roll on iOS
    [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {

      // When there are no more images, the group will be nil
      if(group == nil) {

        // Send a null response to indicate the end of photostreaming
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:nil];
        [pluginResult setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

      } else {

        // Enumarate this group of images

        [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {

          if(result)
          {
            ALAssetRepresentation *representation = [result defaultRepresentation];
            NSNumber *lat = 0;
            NSNumber *lng = 0;
            bool *hasGps = false;
            NSDictionary *gpsDict = [[representation metadata] objectForKey:@"{GPS}"];
            if(gpsDict != nil)
            {
                //NSLog(@"gpsDict %@", gpsDict);
                lat = [gpsDict objectForKey:@"Latitude"];
                lng = [gpsDict objectForKey:@"Longitude"];
                hasGps = true;
            }
            NSMutableDictionary *tempDictionary = [[NSMutableDictionary alloc] init];
            [tempDictionary setObject:representation.url.absoluteString forKey:@"imageUrl"];
            [tempDictionary setObject: (hasGps ? @"true" : @"false") forKey:@"hasGPS"];
            [tempDictionary setObject:(lat == nil ? @"" : lat) forKey:@"latitude"];
            [tempDictionary setObject:(lng == nil ? @"" : lng) forKey:@"longitude"];
            // Send the URL for this asset back to the JS callback
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:tempDictionary];
            [pluginResult setKeepCallbackAsBool:YES];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
          }

          /*NSDictionary *urls = [result valueForProperty:ALAssetPropertyURLs];

          [urls enumerateKeysAndObjectsUsingBlock:^(id key, NSURL *obj, BOOL *stop) {
            // Send the URL for this asset back to the JS callback
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:obj.absoluteString];
            [pluginResult setKeepCallbackAsBool:YES];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

          }];*/


        }];
      }
    } failureBlock:^(NSError *error) {
      // Ruh-roh, something bad happened.
      if (error.code == ALAssetsLibraryAccessUserDeniedError) {
        NSLog(@"not authorized");

        NSString* settingsButton = (&UIApplicationOpenSettingsURLString != NULL)
        ? NSLocalizedString(@"Settings", nil)
        : nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[UIAlertView alloc] initWithTitle:[[NSBundle mainBundle]
                                                 objectForInfoDictionaryKey:@"CFBundleDisplayName"]
                                        message:NSLocalizedString(@"Access to the Photos has been prohibited; please enable it in the Settings app to continue.", nil)
                                       delegate:self
                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                              otherButtonTitles:settingsButton, nil] show];
        });

      }
      CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
      [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
  }];

}



- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // If Settings button (on iOS 8), open the settings app
    if (buttonIndex == 1) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wtautological-pointer-compare"
        if (&UIApplicationOpenSettingsURLString != NULL) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        }
#pragma clang diagnostic pop
    }

}

- (NSString *)dateToString: (NSDate *) date
{
    NSString *_date = [NSDateFormatter localizedStringFromDate:date  dateStyle:NSDateFormatterShortStyle
                                                     timeStyle:NSDateFormatterFullStyle];
    return _date;
}

-(NSMutableArray *) getContentFrom:(ALAssetsGroup *) group withAssetFilter:(ALAssetsFilter *)filter
{
    NSMutableArray *contentArray = [NSMutableArray array];
    [group setAssetsFilter:filter];

    [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {

        //ALAssetRepresentation holds all the information about the asset being accessed.
        if(result)
        {
            //NSLog(@"result %@", result);
            ALAssetRepresentation *representation = [result defaultRepresentation];
            NSNumber *lat = 0;
            NSNumber *lng = 0;
            bool *hasGps = false;

            /*CLLocation *location = [result valueForProperty:ALAssetPropertyLocation];
             if(location != nil)
             {
             //NSLog(@"location %@", location);
             lat = location.coordinate.latitude;
             lng = location.coordinate.longitude;
             }*/

            NSDictionary *gpsDict = [[representation metadata] objectForKey:@"{GPS}"];
            if(gpsDict != nil)
            {
                //NSLog(@"gpsDict %@", gpsDict);
                lat = [gpsDict objectForKey:@"Latitude"];
                lng = [gpsDict objectForKey:@"Longitude"];
                hasGps = true;
            }


            //Stores releavant information required from the library
            NSMutableDictionary *tempDictionary = [[NSMutableDictionary alloc] init];
            //Get the url and timestamp of the images in the ASSET LIBRARY.
            //NSString *imageUrl = [representation UTI];
            NSURL *imageUrl = representation.url;
            NSDictionary *metaDataDictonary = [representation metadata];
            NSString *dateString = [result valueForProperty:ALAssetPropertyDate];
            //NSLog(@"imageUrl %@",imageUrl);
            //NSLog(@"metadictionary: %@",metaDataDictonary);

            //NSURL *url = [result valueForProperty:ALAssetPropertyAssetURL];
            //NSLog(@"url %@", url);
            //NSLog(@"url %@", [[self urlTransformer:url] absoluteString]);


            /*NSString* docsPath = [NSTemporaryDirectory()stringByStandardizingPath];
             NSFileManager* fileMgr = [[NSFileManager alloc] init];
             NSString* filePath;
             int i = 1;
             do {
             filePath = [NSString stringWithFormat:@"%@/%@%03d.%@", docsPath, @"cdv_", i++, @"jpg"];
             } while ([fileMgr fileExistsAtPath:filePath]);
             imageUrl = [[NSURL fileURLWithPath:filePath] absoluteString];
             NSLog(@"filePath %@", imageUrl);*/

            //Check for the date that is applied to the image
            // In case its earlier than the last sync date then skip it. ##TODO##

            NSString *imageKey = @"imageUrl";
            NSString *metaKey = @"MetaData";
            NSString *dateKey = @"date";
            NSString *hasGPS = @"hasGPS";
            NSString *latitude = @"latitude";
            NSString *longitude = @"longitude";

            [tempDictionary setObject:imageUrl.absoluteString forKey:imageKey];
            [tempDictionary setObject: (hasGps ? @"true" : @"false") forKey:hasGPS];
            [tempDictionary setObject:(lat == nil ? @"" : lat) forKey:latitude];
            [tempDictionary setObject:(lng == nil ? @"" : lng) forKey:longitude];
            //[tempDictionary setObject:metaDataDictonary forKey:metaKey];

            NSString *date = [NSDateFormatter localizedStringFromDate:[result valueForProperty:ALAssetPropertyDate]
                                                            dateStyle:NSDateFormatterShortStyle
                                                            timeStyle:NSDateFormatterFullStyle];

            [tempDictionary setObject:[result valueForProperty:ALAssetPropertyDate] forKey:dateKey];

            //Add the values to photos array.
            [contentArray addObject:tempDictionary];
        }
    }];
    return contentArray;
}

- (NSURL*) urlTransformer:(NSURL*)url
{
    NSURL* urlToTransform = url;

    // for backwards compatibility - we check if this property is there
    SEL sel = NSSelectorFromString(@"urlTransformer");
    if ([self.commandDelegate respondsToSelector:sel]) {
        // grab the block from the commandDelegate
        NSURL* (^urlTransformer)(NSURL*) = ((id(*)(id, SEL))objc_msgSend)(self.commandDelegate, sel);
        // if block is not null, we call it
        if (urlTransformer) {
            urlToTransform = urlTransformer(url);
        }
    }

    return urlToTransform;
}

@end
