//
//  ViewController.m
//  HelloLua
//
//  Created by duanqinglun on 15/11/9.
//  Copyright © 2015年 duanqinglun. All rights reserved.
//

#import "ViewController.h"
#import "LuaConsole.h"
#import "lua.h"

#define CODE_PREFIX @"> "

@interface ViewController () <UITextViewDelegate>

@property (nonatomic, retain) LuaConsole *console;
@property (nonatomic, retain) UITextView *consoleTV;

@end

@implementation ViewController
{
    NSUInteger currentIndex;
    NSRange lastSelectedRange;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.console = [LuaConsole instance];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UITextView *tv = [[UITextView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:tv];
    tv.delegate = self;
    tv.backgroundColor = [UIColor blackColor];
    tv.textColor = [UIColor greenColor];
    tv.text = [NSString stringWithFormat:@"%@\n%@", [NSString stringWithUTF8String:LUA_COPYRIGHT], CODE_PREFIX];
    tv.font = [UIFont systemFontOfSize:16.f];
    self.consoleTV = tv;
    
    currentIndex = tv.text.length;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUI:) name:@"updateUI" object:nil];
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@""] && [[textView.text substringFromIndex:currentIndex] isEqualToString:@""]) {
        return NO;//handle delete key
    }
    if ([text isEqualToString:@"\n"]) {
        NSString *code = [textView.text substringFromIndex:currentIndex];
        NSString *result = [self.console run:code];
        textView.text = [NSString stringWithFormat:@"%@\n%@%@", textView.text, result, CODE_PREFIX];
        currentIndex = textView.text.length;
        return NO;
    }
    return YES;
}

- (void)textViewDidChangeSelection:(UITextView *)textView
{
    if (![self isLegalSelectedRange:textView.selectedRange]) {
        textView.selectedRange = lastSelectedRange;
    }
    lastSelectedRange = textView.selectedRange;
}

#pragma mark - handle notification

- (void)updateUI:(NSNotification *)notify
{
    NSDictionary *config = notify.object;
    self.consoleTV.frame = CGRectMake(0, 0, [config[@"width"] intValue], [config[@"height"] intValue]);
    self.consoleTV.backgroundColor = [UIColor colorWithRed:[config[@"red"] floatValue] green:[config[@"green"] floatValue] blue:[config[@"blue"] floatValue] alpha:1];
}

#pragma mark - private

- (BOOL)isLegalSelectedRange:(NSRange)selectedRange
{
    return selectedRange.location >= currentIndex;
}

@end
