#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "RCIMWrapperArgumentAdapter.h"
#import "RCIMWrapperEngine.h"
#import "RCIMWrapperMainThreadPoster.h"
#import "RCIMWrapperPlugin.h"

FOUNDATION_EXPORT double rongcloud_im_wrapper_pluginVersionNumber;
FOUNDATION_EXPORT const unsigned char rongcloud_im_wrapper_pluginVersionString[];

