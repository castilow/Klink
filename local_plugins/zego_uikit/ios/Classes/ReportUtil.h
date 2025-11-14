#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ReportUtil : NSObject

+ (instancetype)sharedInstance;

- (void)createWithAppID:(unsigned int)appID
            signOrToken:(nullable NSString *)signOrToken
           commonParams:(nullable NSDictionary *)commonParams;

- (void)destroy;

- (void)updateToken:(nullable NSString *)token;

- (void)updateCommonParams:(nullable NSDictionary *)params;

- (void)reportEvent:(nullable NSString *)event
         paramsDict:(nullable NSDictionary *)params;

@end

NS_ASSUME_NONNULL_END










