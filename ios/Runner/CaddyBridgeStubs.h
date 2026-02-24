#ifndef CaddyBridgeStubs_h
#define CaddyBridgeStubs_h

#include <Foundation/Foundation.h>

NSString* _Nullable CaddyBridgeStartCaddy(NSString* _Nullable configJSON);
NSString* _Nullable CaddyBridgeStopCaddy(void);
NSString* _Nullable CaddyBridgeReloadCaddy(NSString* _Nullable configJSON);
NSString* _Nullable CaddyBridgeGetCaddyStatus(void);
NSString* _Nullable CaddyBridgeSetEnvironment(NSString* _Nullable envJSON);

#endif
