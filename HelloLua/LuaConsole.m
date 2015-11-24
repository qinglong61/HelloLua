//
//  LuaConsole.m
//  HelloLua
//
//  Created by duanqinglun on 15/11/16.
//  Copyright © 2015年 duanqinglun. All rights reserved.
//

#import "LuaConsole.h"
#import "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#define LOG_FILE_PATH [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"stdout.log"]

@implementation LuaConsole

static lua_State *L;

+ (LuaConsole *)instance
{
    static LuaConsole *instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[super allocWithZone:NULL] init];
    });
    
    return instance;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self instance];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (instancetype)init
{
    if (self = [super init])
    {
        L = luaL_newstate();
        luaopen_base(L);
        
        lua_register(L, "aTestFunc", sayHi);
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:LOG_FILE_PATH]) {
            [fileManager createFileAtPath:LOG_FILE_PATH contents:nil attributes:nil];
        }
        
        freopen([LOG_FILE_PATH UTF8String], "a+", stderr);
        freopen([LOG_FILE_PATH UTF8String], "a+", stdout);
    }
    return self;
}

- (NSString *)run:(NSString *)code
{
    [@"" writeToFile:LOG_FILE_PATH atomically:NO encoding:NSUTF8StringEncoding error:NULL];
    
    if (luaL_dostring(L, [code UTF8String]))
        lua_writestringerror("error: %s", lua_tostring(L, -1));
    
    fflush(stdout);
    fflush(stderr);
    return [NSString stringWithContentsOfFile:LOG_FILE_PATH encoding:NSUTF8StringEncoding error:NULL];
}

int sayHi(lua_State *L)
{
    const char *s = lua_tostring(L, 1);
    NSString *arg = [NSString stringWithUTF8String:s];
    NSString *ret = [NSString stringWithFormat:@"Hi, %@", arg];
    lua_pushstring(L, [ret UTF8String]);
    puts("this is a test C function");
    return 1;
}

@end