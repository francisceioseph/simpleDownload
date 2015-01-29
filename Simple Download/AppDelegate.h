//
//  AppDelegate.h
//  Simple Download
//
//  Created by Francisco José A. C. Souza on 28/01/15.
//  Copyright (c) 2015 Francisco José A. C. Souza. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (copy) void (^backgroundSessionCompletionHandler)();

@end
