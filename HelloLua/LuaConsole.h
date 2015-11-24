//
//  LuaConsole.h
//  HelloLua
//
//  Created by duanqinglun on 15/11/16.
//  Copyright © 2015年 duanqinglun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LuaConsole : NSObject

+ (LuaConsole *)instance;

- (NSString *)run:(NSString *)code;

@end
