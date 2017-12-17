//
//  DebugServer.m
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2017 Selander. All rights reserved.
//

#import "debug_application.h"
#import <dlfcn.h>

int debug_application(AMDeviceRef d, NSDictionary* options) {
  
  AMDServiceConnectionRef connection = NULL;
  NSDictionary *params = @{@"CloseOnInvalidate" : @YES, @"InvalidateOnDetach" : @YES};
  AMDeviceSecureStartService(d, @"com.apple.debugserver", params, &connection);
  int socket = (int)AMDServiceConnectionGetSocket(connection);
    CFSocketCreateWithNative(NULL, socket, AF_UNIX, NULL, NULL);
//  void * handle = dlopen("/Users/derekselander/Desktop/LLDBRPC", RTLD_NOW);
//
//  void *socketHandle = NULL;
//  int (*createSocket)(void *, char *) = dlsym(handle, "_ZN3rpc10Connection18ConnectToRPCServerEPKc");
//  int (*getConnection)(void *, int) = dlsym(handle, "_ZNK3rpc10Connection18SendFileDescriptorEi");
//  assert(createSocket && getConnection);
//
//
//  createSocket(&socketHandle, "/Applications/Xcode.app/Contents/SharedFrameworks");
  
//  int remoteFD = getConnection(&socketHandle, socket);
  
  
//  int remoteFD = getConnection(, socket);
  
  
  //  AFCDirectoryRead(connectionRef, <#char *#>, <#void *#>)
  //  while ([outstandingDirectories count]) {
  //    dirContents = nil;
  //
  //    for (NSString *path in dirContents) {
  //
  //      NSString *newString = [currentDirectory stringByAppendingPathComponent:path];
  //      AFCDirectoryOpen(connectionRef, [newString UTF8String], &dirContents);
  ////      [currentDirectory stringByDeletingLastPathComponent];
  //
  //      NSLog(@"%@", dirContents);
  //    }
  //
  //  }
  //  while
  
  //
  //
  //  __unused long rr = AMDServiceConnectionGetSocket(serviceConnect);
  //  int removeSuccess = AMDeviceSecureRemoveApplicationArchive(serviceConnect, d, requiredArgument, rr, rr, rr);
  //  if (removeSuccess) {
  //    dsprintf(stderr, "Error removing archived application: %d", removeSuccess);
  //  }
  //
  //
  //
  //
  //  NSDictionary *params = @{@"ArchiveType" : @"ApplicationOnly", @"SkippUninstall" : @YES};
  //
  //  int archiveSuccess = AMDeviceSecureArchiveApplication(serviceConnect, d, requiredArgument, params, &yoink_callbackfunc, requiredArgument);
  //
  //  if (archiveSuccess != ERR_SUCCESS && archiveSuccess != kAMDAlreadyArchivedError) {
  //    NSLog(@"Error: %d, exiting early", archiveSuccess);
  //    return 1;
  //  }
  //
  //
  //  //  perform_command(AMDServiceConnectionRef, @"Browse", 0, callback_func, NSDictionary *, @"ClientOptions")
  //  //  AMDeviceSecureStartService(d, @"com.apple.mobile.debug", inputDict, &f);
  //  //  AFCConnectionSetSecureContext
  //  //  AFCConnectionOpen(f, 0, &conn);
  //
  //  //   AMDeviceSecureRemoveApplicationArchive(var_48, [var_28 GetDevice], var_8->srcFilePath_, 0x0, 0x0, 0x0);

  return 0;
}
