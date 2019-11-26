//
//  main.m
//  YOYO
//
//  Created by Derek Selander on 9/3/17.
//  Copyright © 2017 Selander. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "ExternalDeclarations.h"
#import "helpers.h"
#import <sys/socket.h>
#import <dlfcn.h>
//#import <log.h>
@import MachO;


// Originals
#import "debug_application.h"
#import "console.h"
#import "get_provisioning_profiles.h"
#import "list_applications.h"
#import "get_device_info.h"
#import "install_application.h"
#import "yoink.h"
#import "remove_file.h"
#import "send_files.h"
#import "get_logs.h"
#import "delete_application.h"
#import "instruments.h"
#import "sim_location.h"
#import "springboardservices.h"


static NSOperation *timeoutOperation = nil; // kill proc if nothing happens in 30 sec
static NSString *optionalArgument = nil;
static NSString *requiredArgument = nil;
static NSString *ideviceName = nil;
static int return_error = 0;
static void * __n = nil; // device_notification_struct
static int (*actionFunc)(AMDeviceRef, id) = nil; // the callback func for whatever action
static BOOL shouldDisableTimeout = YES;
static NSMutableDictionary *getopt_options;


static BOOL isCurrentlyRunning = NO;
static NSMutableSet *connectedDevices;

__unused static void connect_callback(AMDeviceCallBackDevice *device_callback, int cookie) {
  
  [timeoutOperation cancel];
  timeoutOperation = nil;
  
  // only monitor for connection callbacks
  if (device_callback->status != DeviceConnectionStatusConnect) {
    return;
  }
  
  NSDictionary *connectionDetails = ((__bridge NSDictionary *)(device_callback->connectionDeets));
  if ([connectionDetails isKindOfClass:[NSDictionary class]]) {
    NSString *connectionType = connectionDetails[@"Properties"][@"ConnectionType"];
    dsdebug("Found device %s (DeviceID %d) with ConnectionType: %s\n", [connectionDetails[@"SerialNumber"] UTF8String], [connectionDetails[@"DeviceID"] intValue], [connectionType UTF8String]);
  }

  AMDeviceRef d = device_callback->device;
  
  // Connect
  AMDeviceConnect(d);
  
  // Is Paired
  assert((AMDeviceIsPaired(device_callback) == ERR_SUCCESS));
  
  NSString *deviceUDID = AMDeviceCopyValue(d, nil, @"DeviceName", 0);
  // Validate Pairing
  if (AMDeviceValidatePairing(d)) {
    dsprintf(stderr, "The device \"%s\" might not have been paired yet, Trust this computer on the device\n", [deviceUDID UTF8String]);
    exit(1);
  }
  
  // Start Session
  assert(!AMDeviceStartSession(d));
  [connectedDevices addObject:connectionDetails[@"DeviceID"]];
  
  NSString *deviceName = AMDeviceCopyValue(d, nil, @"DeviceName", 0);
  if (deviceName) {
    ideviceName = deviceName;
    dsprintf(stdout, "%sConnected to: \"%s\" (%s)%s\n", dcolor("cyan"), [deviceName UTF8String], [AMDeviceGetName(d) UTF8String], colorEnd());
  }
  
  if (actionFunc) {
    isCurrentlyRunning = YES;
    return_error = actionFunc(d, getopt_options);
  }
  
  if (actionFunc != &debug_application) {
    AMDeviceNotificationUnsubscribe(device_callback);
    CFRunLoopStop(CFRunLoopGetMain());
  }
}


__attribute__((constructor))
void onLoad() {
  if (getenv("DSPLIST")) {
    quiet_mode = YES;
  }
  if (getenv("DSDEBUG")) {
    dsdebug("Verbose mode enabled...\n");
    unsigned long size = 0;
    uint32_t* data = (uint32_t*)getsectdatafromFramework("MobileDevice", "__DATA", "__data", &size);
    
    for (int i = 0; i < size / sizeof(uint32_t); i++) {
      Dl_info info;
      dladdr(&data[i], &info);
      if (strcmp(info.dli_sname, "gLogLevel") == 0) {
        // Let's crank it ALLLLLL THE WAY UP
        *(uint32_t*)info.dli_saddr = INT32_MAX - 1;
        break;
      }
    }
  }
}

//*****************************************************************************/
#pragma mark - MAIN
//*****************************************************************************/

int main(int argc, const char * argv[]) {
  
  @autoreleasepool {
    int option = -1;
    char *addr;

    if (argc == 1) {
      print_manpage();
      exit(EXIT_SUCCESS);
    }
    
    int UseWifiToConnect = 0;
    int UseUSBToConnect = 1;
    getopt_options = [NSMutableDictionary new];
    connectedDevices = [NSMutableSet new];
    
    while ((option = getopt (argc, (char **)argv, ":QWUV:D:d::Rr:fFqS::s:zd:u:hvg::l::i:Cc::p::y::L:")) != -1) {
      switch (option) {
        case 'R': // Use color
          setenv("DSCOLOR", "1", 1);
          break;
        case 'Q': // Use color
          quiet_mode = YES;
          break;
        case 'W':
          UseWifiToConnect = YES;
          break;
        case 'U':
          UseUSBToConnect = YES;
          break;
          case 'V': {
              assertArg();
              NSMutableArray *arr = nil;
              if (getopt_options[kDebugEnvVars]) {
                  arr = getopt_options[kDebugEnvVars];
              } else {
                  arr = [NSMutableArray array];
              }
              
              [arr addObject:[NSString stringWithUTF8String:optarg]];
              [getopt_options setObject:arr forKey:kDebugEnvVars];
              break;
          }
        case 'r':
          assertArg();
          actionFunc = &remove_file;
          [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kRemoveFileBundleID];
          
          if (argc > optind) {
            [getopt_options setObject:[NSString stringWithUTF8String:argv[optind]] forKey:kRemoveFileRemotePath];
          }
          break;
        case 'v':
          printf("%s v%s\n", program_name, version_string);
          exit(EXIT_SUCCESS);
        case 'g':
          assertArg();
          actionFunc = &get_logs;
          if (strcmp("__delete", optarg) == 0) {
            [getopt_options setObject:@YES forKey:kGetLogsDelete];
          } else {
            [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kGetLogsAppBundle];
          }
          
          if (argc > optind) {
            [getopt_options setObject:[NSString stringWithUTF8String:argv[optind]] forKey:kGetLogsFilePath];
          }
          break;
        case 'f':
          actionFunc = &get_device_info;
          break;
        case 'F':
          actionFunc = &instruments;
          break;
        case 'l':
//          assertArg();
          actionFunc = &list_applications;
          addr = strdup(optarg);
          [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kListApplicationsName];
          if (argc > optind) {
            [getopt_options setObject:[NSString stringWithUTF8String:argv[optind]] forKey:kListApplicationsKey];
          }
          break;
        case 'u':
          assertArg();
          actionFunc = &delete_application;
          [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kDeleteApplicationIdentifier];
          break;
        case 's':
          assertArg();
          if(argc != 4) {
            dsprintf(stderr, "Err: mobdevim -s BundleIdentifier /path/to/directories\n");
            exit(1);
          }
          actionFunc = &send_files;
          [getopt_options setObject:[NSString stringWithUTF8String:argv[optind]] forKey:kSendFilePath];
          [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kSendAppBundle];
          break;
        case 'S':
          [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kSBCommand];
          actionFunc = &springboard_services;
          break;
        case 'i':
          assertArg();
          shouldDisableTimeout = NO;
          actionFunc = &install_application;
          addr = strdup(optarg);
          [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kInstallApplicationPath];
          requiredArgument = [NSString stringWithUTF8String:addr];
          break;
        case 'L':
          assertArg();
          shouldDisableTimeout = NO;
          actionFunc = &sim_location;
          [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kSimLocationLat];
          [getopt_options setObject:[NSString stringWithUTF8String:argv[optind]] forKey:kSimLocationLon];
          optind++;
          break;
        case 'h':
          print_manpage();
          exit(EXIT_SUCCESS);
          break;
        case 'D':
              [getopt_options setObject:@YES forKey:kDebugQuickLaunch];
           // drops through to debug
        case 'd':
          assertArg();
          shouldDisableTimeout = NO;
          [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kDebugApplicationIdentifier];
          actionFunc = debug_application;
          break;
        case 'c':
          assertArg();
          shouldDisableTimeout = NO;
          actionFunc = console;
          [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kConsoleProcessName];
          break;
        case 'C':
          actionFunc = &get_provisioning_profiles;
          [getopt_options setObject:@YES forKey:kProvisioningProfilesCopyDeveloperCertificates];
          break;
        case '?': // TODO fix this
          goto MEH_IM_DONE;
          break;
        case 'p':
          assertArg();
          actionFunc = &get_provisioning_profiles;
          [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kProvisioningProfilesFilteredByDevice];
          break;
        case 'y':
          assertArg();
          actionFunc = &yoink_app;
          [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kYoinkBundleIDContents];
          break;
        case ':': // cases for optional non argument
          switch (optopt)
        {
          case 'g':
            actionFunc = &get_logs;
            break;
          case 'S':
            actionFunc = springboard_services;
            break;
          case 'p':
            actionFunc = &get_provisioning_profiles;
            break;
          case 'c':
            shouldDisableTimeout = NO;
            actionFunc = console;
            break;
          case 'l':
            actionFunc = &list_applications;
            break;
          case 'd':
            shouldDisableTimeout = NO;
            actionFunc = debug_application;
            break;
          case 'y':
            dsprintf(stderr, "%sList a BundleIdentifier to yoink it's contents%s\n\n", dcolor("yellow"), colorEnd());
            actionFunc = &list_applications;
            break;
          case 'L':
            assertArg();
            shouldDisableTimeout = NO;
            actionFunc = &sim_location;
            break;
          case '?':
            break;
          default:
            dsprintf(stderr, "option -%c is missing a required argument\n", optopt);
            return EXIT_FAILURE;
        }
          break;
        default:
          dsprintf(stderr, "%s\n", usage);
          exit(EXIT_FAILURE);
          break;
      }
    }
    
  MEH_IM_DONE:
    
    
    
    if (!isatty(fileno(stdout))) {
      unsetenv("DSCOLOR");
    }
    
    
    AMDeviceNotificationSubscribeWithOptions(connect_callback, 0,0,0,&__n, @{@"NotificationOptionSearchForPairedDevices" : @(UseUSBToConnect), @"NotificationOptionSearchForWiFiPairableDevices" : @(UseWifiToConnect) });

    timeoutOperation = [NSBlockOperation blockOperationWithBlock:^{
      dsprintf(stderr, "Your device might not be connected. You've got about 25 seconds to connect your device before the timeout gets fired or you can start fresh with a ctrl-c. Choose wisely... dun dun\n");
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      [[NSOperationQueue mainQueue] addOperation:timeoutOperation];
    });
    
    if (shouldDisableTimeout) {
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CFRunLoopStop(CFRunLoopGetMain());
        dsprintf(stderr, "Script timed out, exiting now.\n");
        exit(EXIT_FAILURE);
        
      });
    }
    
    CFRunLoopRun();
    
  }
  return return_error;
}


/*
 /System/Library/PrivateFrameworks/CommerceKit.framework/Versions/A/CommerceKit
 po [[CKAccountStore sharedAccountStore] primaryAccount]
 <ISStoreAccount: 0x6080000d8f70>: dereks@somoioiu.com (127741183) isSignedIn=1 managedStudent=0
 */
