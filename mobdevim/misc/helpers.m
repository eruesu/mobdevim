//
//  
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2017 Selander. All rights reserved.
//

#include "helpers.h"



//*****************************************************************************/
#pragma mark - Externals
//*****************************************************************************/

const char *version_string = "0.0.1";
const char *program_name = "mobdevim";
// TODO
// const char *git_hash = "|||||";
const char *usage = "mobdevim [-v] [-l|-l appIdent][-i path_to_app_dir] [-p|-p UUID_PROVSIONPROFILE] [-c] [-C] [-s bundleIdent path] [-f]";
BOOL quiet_mode = NO;




char* dcolor(char *color) {
  static BOOL useColor = NO;
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    if (getenv("DSCOLOR")) {
      useColor = YES;
    }
  });
  if (!useColor) {
    return "";
  }
  if (strcmp("cyan", color) == 0) {
    return "\e[36m";
  } else if (strcmp("yellow", color) == 0) {
    return "\e[33m";
  } else if (strcmp("magenta", color) == 0) {
    return "\e[95m";
  } else if (strcmp("red", color) == 0) {
    return "\e[91m";
  } else if (strcmp("blue", color) == 0) {
    return "\e[34m";
  } else if (strcmp("gray", color) == 0) {
    return "\e[90m";
  } else if (strcmp("bold", color) == 0) {
    return "\e[1m";
  }
  return "";
}

char *colorEnd() {
  static BOOL useColor = NO;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    if (getenv("DSCOLOR")) {
      useColor = YES;
    }
  });
  if (useColor) {
    return "\e[0m";
  }
  
  return "";
}

void dsprintf(FILE * f, const char *format, ...) {
  if (quiet_mode) {
    return;
  }
  va_list args;
  va_start( args, format );
  vfprintf(f, format, args );
  va_end( args );
}


void print_manpage(void) {
  BOOL hasColor = getenv("DSCOLOR") ? YES : NO;
  if (!hasColor) {
    putenv("DSCOLOR=1");
  }
  char *manDescription = "\n\
  %sName%s\n\
  %s%s%s -- (mobiledevice-improved) Interact with an iOS device (compiled %s)\n\n\
  %sSynopsis%s\n\
  \tmobdevim [-Rq][-f]\n\
  \tmobdevim [-Rq][-l | -l bundleIdentifier][key]\n\
  \tmobdevim [-Rq][-p | -p provisioningUUID]\n\
  \tmobdevim [-Rq][-g | -g bundleIdentifier | -g number]\n\
  \tmobdevim [-Rq][-i pathToIPA]\n\
  \tmobdevim [-Rq][-D bun]eIdentifier\n\
  \tmobdevim [-q][-C]\n\
  \tmobdevim [-q][-y bundleIdentifier]\n\
  \tmobdevim [-q][-s bundleIdentifier path]\n\
  \tmobdevim [-c]\n\n\
  %sDescription%s\n\
  \tThe mobdevim utlity interacts with your plugged in iOS device over USB using Apple's private\n\
  framework, MobileDevice.\n\n\
  The options are as follows:\n\
  \t%s-f%s\tGet device info\n\n\
  \t%s-g%s\tGet device logs/issues\n\
          \t\t%smobdevim -g com.example.name%s Get issues for com.example.name app\n\
          \t\t%smobdevim -g 3%s Get the 3rd most recent issue\n\
          \t\t%smobdevim -g __all%s Get all the logs\n\n\
  \t%s-y%s\tYoink sandbox content\n\
          \t\t%smobdevim -y com.example.test%s Yoink contacts from app\n\n\
  \t%s-s%s\tSend content to device (use content from yoink command)\n\
          \t\t%smobdevim -s com.example.test /tmp/com.example.test%s Send contents in /tmp/com.example.test to app\n\n\
  \t%s-i%s\tInstall application, expects path to bundle\n\
          \t\t%smobdevim -i /path/to/app/bundle%s Install app\n\n\
  \t%s-u%s\tUninstall application, expects bundleIdentifier\n\
          \t\t%smobdevim -u com.example.test%s Uninstall app\n\n\
  \t%s-c%s\tDump out the console information. Use ctrl-c to terminate\n\n\
  \t%s-C%s\tGet certificates on device\n\n\
  \t%s-p%s\tDisplay developer provisioning profile info\n\
            \t\t%smobdevim -p%s List all installed provisioning profiles\n\
            \t\t%smobdevim -p b68410a1-d825-4b7c-8e5d-0f76a9bde6b9%s Get detailed provisioning UUID info\n\n\
  \t%s-l%s\tList app information\n\
        \t\t%smobdevim -l%s List all apps\n\
        \t\t%smobdevim -l com.example.test%s Get detailed information about app, com.example.test\n\
        \t\t%smobdevim -l com.example.test Entitlements%s List \"Entitlements\" key from com.example.test\n\
  \t%s-R%s\tUse color\n\n\
  \t%s-q%s\tQuiet mode, ideal for limiting output or checking if a value exists based upon return status\n\n";
  
  char formattedString[4096];
  snprintf(formattedString, 4096, manDescription, dcolor("bold"), colorEnd(), dcolor("bold"), program_name, colorEnd(), __DATE__, dcolor("bold"), colorEnd(),
           dcolor("bold"), colorEnd(), // -f
           dcolor("bold"), colorEnd(), // -g
               dcolor("bold"), colorEnd(), // -g
               dcolor("bold"), colorEnd(), // -g
               dcolor("bold"), colorEnd(), // -g
           dcolor("bold"), colorEnd(), // -i
               dcolor("bold"), colorEnd(), // -i
           dcolor("bold"), colorEnd(), // -u
               dcolor("bold"), colorEnd(), // -u
           dcolor("bold"), colorEnd(), // -D
           dcolor("bold"), colorEnd(), // -y
               dcolor("bold"), colorEnd(), // -y
           dcolor("bold"), colorEnd(), // -s
               dcolor("bold"), colorEnd(), // -g
           dcolor("bold"), colorEnd(), // -c
           dcolor("bold"), colorEnd(), // -C
           dcolor("bold"), colorEnd(), // -c
           dcolor("bold"), colorEnd(), // -p
               dcolor("bold"), colorEnd(), // -p
               dcolor("bold"), colorEnd(), // -p
           dcolor("bold"), colorEnd(), // -l
               dcolor("bold"), colorEnd(), // -l
               dcolor("bold"), colorEnd(), // -l
               dcolor("bold"), colorEnd(), // -l
           dcolor("bold"), colorEnd(), // -R
           dcolor("bold"), colorEnd()); // -q
  
  dsprintf(stdout, "%s", formattedString);
  
  if (!hasColor) {
    unsetenv("DSCOLOR");
  }
}

void assertArg(void) {
  if (!optarg) {
    print_manpage();
    exit(1);
  }
}

NSString * const kOptionArgumentDestinationPath = @"com.selander.destination";


