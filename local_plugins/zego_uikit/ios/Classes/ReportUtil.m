#import "ReportUtil.h"

@interface ReportUtil ()

@property(nonatomic, strong) dispatch_queue_t syncQueue;

@end

@implementation ReportUtil

+ (instancetype)sharedInstance {
    static ReportUtil *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ReportUtil alloc] initPrivate];
    });
    return instance;
}

- (instancetype)init {
    return [[self class] sharedInstance];
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        _syncQueue = dispatch_queue_create("com.zegocloud.uikit.reporter", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)createWithAppID:(unsigned int)appID
            signOrToken:(NSString *)signOrToken
           commonParams:(NSDictionary *)commonParams {
    dispatch_async(self.syncQueue, ^{
        // Reporter deshabilitado: no se realiza ninguna operación.
    });
}

- (void)destroy {
    dispatch_async(self.syncQueue, ^{
        // Reporter deshabilitado: no se realiza ninguna operación.
    });
}

- (void)updateToken:(NSString *)token {
    dispatch_async(self.syncQueue, ^{
        // Reporter deshabilitado: no se realiza ninguna operación.
    });
}

- (void)updateCommonParams:(NSDictionary *)params {
    dispatch_async(self.syncQueue, ^{
        // Reporter deshabilitado: no se realiza ninguna operación.
    });
}

- (void)reportEvent:(NSString *)event paramsDict:(NSDictionary *)params {
    dispatch_async(self.syncQueue, ^{
        // Reporter deshabilitado: no se realiza ninguna operación.
    });
}

@end










