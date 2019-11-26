//
//  DebugServer.h
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2017 Selander. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ExternalDeclarations.h"

/// The path to the IPA file
extern NSString * const kDebugApplicationIdentifier;
extern NSString * const kDebugQuickLaunch;
extern NSString * const kDebugEnvVars;

int debug_application(AMDeviceRef d, NSDictionary* options);
