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
#define CONFIG_FILE_PATH [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"config.lua"]
#define CONFIG_BYTECODE_FILE_PATH [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"config.out"]

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
        lua_register(L, "updateUI", updateUI);
        lua_register(L, "configUI", configUI);
        
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

int updateUI(lua_State *L)
{
    int width, height;
    float red, green, blue;
    loadConfig(&width, &height, &red, &green, &blue);
    fprintf(stdout, "%d-%d-%.2f-%.2f-%.2f\n", width, height, red, green, blue);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateUI" object:
  @{@"width":[NSNumber numberWithInt:width],
    @"height":[NSNumber numberWithInt:height],
    @"red":[NSNumber numberWithFloat:red],
    @"green":[NSNumber numberWithFloat:green],
    @"blue":[NSNumber numberWithFloat:blue]}];
    
    return 1;
}

int configUI(lua_State *L)
{
    int width = lua_tonumber(L, -5);
    int height = lua_tonumber(L, -4);
    float red = lua_tonumber(L, -3);
    float green = lua_tonumber(L, -2);
    float blue = lua_tonumber(L, -1);
    
    config(width, height, red, green, blue);
    
    return 1;
}

void loadConfig (int *width, int *height, float *red, float *green, float *blue)
{
//    if (luaL_dofile(L, [CONFIG_BYTECODE_FILE_PATH UTF8String]))
//        lua_writestringerror("cannot run configuration file: %s", lua_tostring(L, -1));
    
    if (luaL_dofile(L, [CONFIG_FILE_PATH UTF8String]))
        lua_writestringerror("cannot run configuration file: %s", lua_tostring(L, -1));
    lua_getglobal(L, "width");
    lua_getglobal(L, "height");
    lua_getglobal(L, "background");
    if (!lua_isnumber(L, -3))
        puts("`width' should be a number");
    if (!lua_isnumber(L, -2))
        puts("`height' should be a number");
    if (!lua_istable(L, -1))
        puts("`background' is not a valid color table");
    *width = (int)lua_tonumber(L, -3);
    *height = (int)lua_tonumber(L, -2);
    
    *red = getField("r");
    *green = getField("g");
    *blue = getField("b");
}

void config (int width, int height, float red, float green, float blue)
{
    NSString *content = @"-- configuration file for 'ViewController'\n";
    content = [content stringByAppendingString:[NSString stringWithFormat:@"width = %d\n", width]];
    content = [content stringByAppendingString:[NSString stringWithFormat:@"height = %d\n", height]];
    content = [content stringByAppendingString:[NSString stringWithFormat:@"background = {\n    r = %f,\n    g = %f,\n    b = %f\n}", red, green, blue]];

    NSError *error = nil;
    [content writeToFile:CONFIG_FILE_PATH atomically:NO encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        fprintf(stderr, "%s\n", [[error localizedDescription] UTF8String]);
    }
}

float getField (const char *key)
{
    float result;
    lua_pushstring(L, key);
    lua_gettable(L, -2);
    if (!lua_isnumber(L, -1))
        puts("invalid component in background color");
    result = (float)lua_tonumber(L, -1);
    lua_pop(L, 1);
    return result;
}

@end