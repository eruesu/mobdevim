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

static NSOperation *_op = nil; //
static NSString *optionalArgument = nil;
static NSString *requiredArgument = nil;
static NSString *ideviceName = nil;
static int return_error = 0;
static void * __n = nil; // device_notification_struct
static int (*actionFunc)(AMDeviceRef, id) = nil; // the callback func for whatever action
static BOOL shouldDisableTimeout = YES;
static NSMutableDictionary *getopt_options;



__unused static void connect_callback(AMDeviceRef deviceArray, int cookie) {

  [_op cancel];
  _op = nil;
  
  AMDeviceRef d = *(AMDeviceRef *) deviceArray;

  // Connect
  AMDeviceConnect(d);
  
  // Is Paired
  assert((AMDeviceIsPaired(deviceArray) == ERR_SUCCESS));
  
  // Validate Pairing
  assert(!AMDeviceValidatePairing(d));

  // Start Session
  assert(!AMDeviceStartSession(d));
  
  NSString *deviceName = AMDeviceCopyValue(d, nil, @"DeviceName", 0);
  if (deviceName) {
    ideviceName = deviceName;
    dsprintf(stdout, "%sConnected to: \"%s\" (%s)%s\n", dcolor("cyan"), [deviceName UTF8String], [AMDeviceGetName(d) UTF8String], colorEnd());
  }
  
  if (actionFunc) {
    return_error = actionFunc(d, getopt_options);
  }
  
  
  if (shouldDisableTimeout) {
    AMDeviceNotificationUnsubscribe(deviceArray);
    CFRunLoopStop(CFRunLoopGetMain());
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
    
    getopt_options = [NSMutableDictionary new];
    
      while ((option = getopt (argc, (char **)argv, ":d::Rr:fn:qs:zd:hvl::i:Cc::p::y::")) != -1) {
          switch (option) {
            case 'R': // Use color
                  setenv("DSCOLOR", "1", 1);
                  break;
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
              case 'f':
                  actionFunc = &get_device_info;
                  break;
              case 'l':
                  assertArg();
                  actionFunc = &list_applications;
                  addr = strdup(optarg);
                 [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kListApplicationsName];
                  break;
              case 'q':
                  quiet_mode = YES;
                  break;
            case 'n':
              assertArg();
              [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kOptionArgumentDestinationPath];
                  break;
              case 's':
                  assertArg();
                  actionFunc = &send_files;
                  [getopt_options setObject:[NSString stringWithUTF8String:argv[optind]] forKey:kSendFilePath];
                  [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kSendAppBundle];
                  break;
              case 'i':
                  assertArg();
                  actionFunc = &install_application;
                  addr = strdup(optarg);
                  [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kInstallApplicationPath];
                  requiredArgument = [NSString stringWithUTF8String:addr];
                  break;
              case 'h':
                  print_manpage();
                  exit(EXIT_SUCCESS);
              case 'd':
                  // TODO
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
            case ':':
              switch (optopt)
            {
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
                actionFunc = debug_application;
                break;
              case 'y':
                dsprintf(stderr, "%sList a BundleIdentifier to yoink it's contents%s\n\n", dcolor("yellow"), colorEnd());
                actionFunc = &list_applications;
                break;
              default:
                fprintf(stderr, "option -%c is missing a required argument\n", optopt);
                return EXIT_FAILURE;
            }
              break;
              default:
                  printf("%s\n", usage);
                  exit(EXIT_FAILURE);
                  break;
          }
      }

    AMDeviceNotificationSubscribe(connect_callback, 0, 0, 0, &__n);
    
    _op = [NSBlockOperation blockOperationWithBlock:^{
      printf("Your device might not be connected. You've got about 25 seconds to connect your device before the timeout gets fired or you can start fresh with a ctrl-c. Choose wisely... dun dun\n");
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      [[NSOperationQueue mainQueue] addOperation:_op];
    });
    
    if (shouldDisableTimeout) {
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CFRunLoopStop(CFRunLoopGetMain());
        dsprintf(stdout, "Script timed out, exiting now.\n");
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
