#include <Foundation/Foundation.h>


@interface MUMAuthorizer : NSObject
+ (NSError *)checkAuthorization:(NSData *)authData command:(SEL)command;
+ (NSData  *)authorizeHelper;

@end
