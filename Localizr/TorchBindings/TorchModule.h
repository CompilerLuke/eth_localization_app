#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TorchModule : NSObject
- (nullable instancetype)initWithFileAtPath:(NSString*)filePath
    NS_SWIFT_NAME(init(fileAtPath:))NS_DESIGNATED_INITIALIZER;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
@end

@interface LocalizationModule : TorchModule
- (NSArray<NSArray<NSNumber*>*>*)localizeImage:(const float*) image width:(int) width height:(int) height NS_SWIFT_NAME(localizeImage(image:, width:, height:));
@end

NS_ASSUME_NONNULL_END
