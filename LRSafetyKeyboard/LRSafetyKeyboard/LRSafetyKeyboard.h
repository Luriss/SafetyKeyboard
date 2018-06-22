//
//  LRSafetyKeyboard.h
//  LRSafetyKeyboard
//
//  Created by luris on 2018/6/21.
//  Copyright © 2018年 luris. All rights reserved.
//

#import <UIKit/UIKit.h>


/**
 字符串Block
 
 @param text 字符串
 */
typedef void(^StringBlock)(NSString *text);


/**
 键盘类型
 
 - LRSafetyKeyboardTypeNormal: 普通的全键盘
 - LRSafetyKeyboardTypeNumberNormal: 普通的数字键盘
 - LRSafetyKeyboardTypeSafetyQWERTY: 安全的全键盘 默认输入内容隐藏
 - LRSafetyKeyboardTypeSafetyNumber: 安全的数字键盘 默认输入内容隐藏
 */
typedef NS_ENUM(NSInteger,LRSafetyKeyboardType) {
    LRSafetyKeyboardTypeNormal          = 0,
    LRSafetyKeyboardTypeNumberNormal,
    LRSafetyKeyboardTypeSafetyQWERTY,
    LRSafetyKeyboardTypeSafetyNumber,
};


@interface LRSafetyKeyboard : UIView


/**
 初始化键盘
 
 @param view 输入源 仅支持 UITextField/UITextView
 @param type 类型
 @return self
 */
- (instancetype)initWithInputSource:(UIView *)view
                       keyboardType:(LRSafetyKeyboardType)type;


/**
 设置键盘标题
 
 @param title 标题文字
 */
- (void)setKeyBoardTitle:(NSString *)title;


/**
 安全输入状态下，输入框内容全部显示为 •
 需要调用此方法获取输入内容
 
 @param callback callback
 */
- (void)secureTextDidEndEditing:(StringBlock)callback;


/**
 安全输入状态下，监听输入框内容
 
 @param callback callback
 */
- (void)secureTextDidChange:(StringBlock)callback;



@end
