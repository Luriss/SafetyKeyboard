//
//  LRSafetyKeyboard.h
//  LRSafetyKeyboard
//
//  Created by luris on 2018/6/22.
//  Copyright © 2018年 luris. All rights reserved.
//

#import <UIKit/UIKit.h>


/**
 输入文字 Block
 
 @param text 字符串
 */
typedef void(^TextBlock)(NSString *text);


/**
 键盘类型

 - LRSafetyKeyboardTypeSafetyQWERTY: 全键盘
 - LRSafetyKeyboardTypeSafetyNumber: 数字键盘
 */
typedef NS_ENUM(NSInteger,LRSafetyKeyboardType) {
    LRSafetyKeyboardTypeSafetyQWERTY        = 0,
    LRSafetyKeyboardTypeSafetyNumber,
};


@interface LRSafetyKeyboard : UIView


/**
 是否安全输入，安全输入状态下输入框内容会显示为 圆点
 default is YES.
 */
@property(nonatomic, assign) BOOL secureEntry;


/**
 初始化键盘
 
 @param view 添加键盘的view 仅支持 UITextField/UITextView
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
- (void)secureTextDidEndEditing:(TextBlock)callback;


/**
 安全输入状态下，监听输入框内容
 
 @param callback callback
 */
- (void)secureTextDidChange:(TextBlock)callback;



@end
