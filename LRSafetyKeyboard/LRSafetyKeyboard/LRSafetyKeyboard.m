//
//  LRSafetyKeyboard.m
//  LRSafetyKeyboard
//
//  Created by luris on 2018/6/21.
//  Copyright © 2018年 luris. All rights reserved.
//

#import "LRSafetyKeyboard.h"

#define LRColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define iPhoneX (([UIScreen mainScreen].bounds.size.width == 375.0f) && ([UIScreen mainScreen].bounds.size.height == 812.0f))


@interface LRSafetyKeyboard ()
{
@private
    CGFloat     _viewH;
    CGFloat     _viewW;
    CGFloat     _spaceY;
    CGFloat     _spaceX;
    CGFloat     _btnH;
    CGFloat     _btnW;
    
    UIImage    *_normalImage;
    UIImage    *_highlightImage;
    
    UIColor    *_btnBgColor;
    
@protected
    BOOL        _isSafety;
    BOOL        _isOnlyNumber;
    BOOL        _isUpper;
    BOOL        _isMoreSymbol;
    
}

@property(nonatomic, assign)LRSafetyKeyboardType type;
@property(nonatomic, copy)StringBlock        resultBlock;
@property(nonatomic, copy)StringBlock        changeBlock;

@property(nonatomic, strong)UILabel         *titleLabel;
@property(nonatomic, strong)UIImageView     *safetyImageV;
@property(nonatomic, strong)UIView          *numbersView;
@property(nonatomic, strong)UIView          *qwertyView;
@property(nonatomic, strong)UIView          *charsView;
@property(nonatomic, strong)UIView          *symbolView;
@property(nonatomic, weak)UIView            *inputSource;


@property(nonatomic, strong)NSMutableArray<UIButton *> *bottomBtns;
@property(nonatomic, strong)NSMutableArray<UIButton *> *charsBtns;
@property(nonatomic, strong)NSMutableArray<UIButton *> *symbolsBtns;

@property(nonatomic, strong)NSArray<NSString *> *numbers;
@property(nonatomic, strong)NSArray<NSString *> *chars;
@property(nonatomic, strong)NSArray *symbols;
@property(nonatomic, strong)NSMutableString   *secureText;


@end

@implementation LRSafetyKeyboard

- (instancetype)initWithInputSource:(UIView *)view
                       keyboardType:(LRSafetyKeyboardType)type
{
    self = [super initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, iPhoneX?290:260)];
    if (self) {
        self.inputSource = view;
        [self configValue];
        self.backgroundColor = [UIColor whiteColor];
        // 添加标题
        [self addSubview:self.titleLabel];
        // 根据类型添加键盘
        [self addSafetyKeyboardWithType:type];
    }
    return self;
}

#pragma mark -
#pragma mark --- Publick Method
- (void)setKeyBoardTitle:(NSString *)title
{
    if (title.length > 0) {
        self.titleLabel.text = title;
    }
}

- (void)secureTextDidEndEditing:(StringBlock)callback
{
    if (!_isSafety) {
        return;
    }
    self.resultBlock = callback;
}

- (void)secureTextDidChange:(StringBlock)callback
{
    if (!_isSafety) {
        return ;
    }
    
    self.changeBlock = callback;
}

- (void)configValue
{
    // 键盘宽度
    _viewW = [UIScreen mainScreen].bounds.size.width;
    // 键盘高度
    _viewH = 260;
    // 键盘按键纵向间距
    _spaceY = 10;
    // 键盘按钮高度
    _btnH = floorf((_viewH - 30 - _spaceY*4)/4);
    // 键盘按钮横向间距
    _spaceX = 6;
    // 键盘按钮宽度
    _btnW = floorf((_viewW - _spaceX*10)/10);
    // 键盘按钮背景色
    _btnBgColor = LRColorFromRGB(0xacb3be);
    // 键盘按钮高亮背景图片
    _highlightImage = [self imageWithColor:_btnBgColor];
    // 键盘按钮默认背景图片
    _normalImage = [self imageWithColor:[UIColor whiteColor]];
    // 是否大写
    _isUpper = NO;
    // 是否更多特殊字符
    _isMoreSymbol = NO;
}

- (void)addSafetyKeyboardWithType:(LRSafetyKeyboardType)type
{
    switch (type) {
        case LRSafetyKeyboardTypeNormal:{
            self.type = type;
            _isSafety = NO;
            _isOnlyNumber = NO;
            [self addSubview:self.qwertyView];
            break;
        }
        case LRSafetyKeyboardTypeSafetyQWERTY:{
            self.type = type;
            _isSafety = YES;
            _isOnlyNumber = NO;
            [self addSubview:self.safetyImageV];
            [self addSubview:self.qwertyView];
            break;
        }
        case LRSafetyKeyboardTypeNumberNormal:{
            self.type = type;
            _isSafety = NO;
            _isOnlyNumber = YES;
            
            [self addSubview:self.numbersView];
            break;
        }
        case LRSafetyKeyboardTypeSafetyNumber:{
            self.type = type;
            _isSafety = YES;
            _isOnlyNumber = YES;
            
            [self addSubview:self.safetyImageV];
            [self addSubview:self.numbersView];
            break;
        }
            
        default:
            self.type = LRSafetyKeyboardTypeNormal;
            _isSafety = NO;
            _isOnlyNumber = NO;
            [self addSubview:self.qwertyView];
            break;
    }
}


#pragma mark -
#pragma mark --- Button Action

// 英文字符 点击
- (void)keyBoardCharButtonClicked:(UIButton *)button
{
    NSInteger tag = button.tag;
    if (tag < self.chars.count) {
        NSString *str = self.chars[tag];
        if (_isUpper) {
            str = [str uppercaseString];
        }
        
        [self insertText:str];
    }
    else{
        // 大写按钮
        if (tag == self.chars.count) {
            button.selected = !button.selected;
            if (button.selected) {
                [self upperCaseString];
            }
            else{
                [self lowerCaseString];
            }
        }
        else{
            // 删除按钮
            [self deleteText];
        }
    }
}

// 全键盘底部功能按钮点击
- (void)keyBoardBottomButtonClicked:(UIButton *)button
{
    button.selected = !button.selected;
    
    switch (button.tag) {
        case 10:{
            // 英文数字切换
            [self showNumberKeyboard];
            break;
        }
        case 11:{
            // 英文特殊符号切换
            [self showSymbolKeyboard];
            break;
        }
        case 12:{
            // 空格
            [self insertText:@" "];
            break;
        }
        case 13:{
            // 完成
            [self endInput];
            break;
        }
            
        default:
            break;
    }
}


/**
 特殊字符按钮点击
 
 */
- (void)keyBoardSymbolsButtonClicked:(UIButton *)button
{
    NSInteger tag = button.tag;
    
    if (tag == 25) {
        button.selected = !button.selected;
        // 显示更多特殊字符
        if (button.selected) {
            [button setTitle:@"#+=" forState:UIControlStateNormal];
            [self showMoreSymbols];
        }
        else{
            [button setTitle:@"$<¥" forState:UIControlStateNormal];
            [self hideMoreSymbols];
        }
    }
    else if (tag == 26){
        // 删除
        [self deleteText];
    }
    else if (tag > 19){
        // 输入内容
        [self insertText:self.symbols[1][tag-20]];
    }
    else{
        // 输入特殊字符
        if (tag < 10){
            if (_isMoreSymbol) {
                [self insertText:self.symbols[2][tag]];
            }
            else{
                [self insertText:self.numbers[tag]];
            }
        }
        else{
            if (_isMoreSymbol) {
                [self insertText:self.symbols[3][tag-10]];
            }
            else{
                [self insertText:self.symbols[0][tag-10]];
            }
        }
    }
}



/**
 数字键盘按钮点击
 
 */
- (void)numberButtonClicked:(UIButton *)btn
{
    NSInteger tag = btn.tag;
    
    // 输入小数点 .
    if (tag == 12) {
        [self insertText:@"."];
        return ;
    }
    
    // 完成
    if (tag == 14){
        [self endInput];
        return ;
    }
    
    // 删除
    if (tag == 13) {
        [self deleteText];
        return ;
    }
    
    // 输入 1 ~ 9
    if (tag < 10) {
        [self insertText:self.numbers[tag-1]];
    }
    
    // 输入 0
    if (tag == 11) {
        [self insertText:self.numbers.lastObject];
    }
    
    // 全键盘切换
    if (tag == 10) {
        [self showQWERTYKeyboard];
    }
}


#pragma mark -
#pragma mark --- Private Method

/**
 颜色生成图片
 
 @param color 颜色
 @return 图片
 */
- (UIImage *)imageWithColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 0);
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}


/**
 设置字符大写
 */
- (void)upperCaseString
{
    _isUpper = YES;
    for (UIButton *btn in self.charsBtns) {
        if (btn.tag < self.chars.count) {
            NSString *str = self.chars[btn.tag];
            [btn setTitle:[str uppercaseString] forState:UIControlStateNormal];
        }
    }
}


/**
 设置字符小写
 */
- (void)lowerCaseString
{
    _isUpper = NO;
    for (UIButton *btn in self.charsBtns) {
        if (btn.tag < self.chars.count) {
            NSString *str = self.chars[btn.tag];
            [btn setTitle:[str lowercaseString] forState:UIControlStateNormal];
        }
    }
}


/**
 显示更多字符 默认更改上面两行 20 个特殊字符
 */
- (void)showMoreSymbols
{
    _isMoreSymbol = YES;
    for (UIButton *btn in self.symbolsBtns) {
        if (btn.tag < 20) {
            if (btn.tag < 10) {
                [btn setTitle:self.symbols[2][btn.tag] forState:UIControlStateNormal];
            }
            else{
                [btn setTitle:self.symbols[3][btn.tag-10] forState:UIControlStateNormal];
            }
        }
    }
}


/**
 隐藏更多特殊字符 默认更改上面两行 20 个特殊字符
 */
- (void)hideMoreSymbols
{
    _isMoreSymbol = NO;
    for (UIButton *btn in self.symbolsBtns) {
        if (btn.tag < 20) {
            if (btn.tag < 10) {
                [btn setTitle:self.numbers[btn.tag] forState:UIControlStateNormal];
            }
            else{
                [btn setTitle:self.symbols[0][btn.tag-10] forState:UIControlStateNormal];
            }
        }
    }
}


/**
 显示数字键盘
 */
- (void)showNumberKeyboard
{
    self.qwertyView.hidden = YES;
    if (_numbersView) {
        self.numbersView.hidden = NO;
    }
    else{
        [self addSubview:self.numbersView];
    }
}


/**
 显示特殊字符键盘
 */
- (void)showSymbolKeyboard
{
    UIButton *btn = self.bottomBtns[0];
    btn.selected = NO;
    
    self.charsView.hidden = !self.charsView.hidden;
    if (_symbolView) {
        self.symbolView.hidden = !self.symbolView.hidden;
    }
    else{
        [self.qwertyView addSubview:self.symbolView];
    }
}


/**
 显示全键盘
 */
- (void)showQWERTYKeyboard
{
    if (_isOnlyNumber) {
        return;
    }
    
    self.numbersView.hidden = YES;
    self.qwertyView.hidden = NO;
    UIButton *btn = self.bottomBtns.firstObject;
    btn.selected = !btn.selected;
}


/**
 输入字符
 @param text 输入内容
 */
- (void)insertText:(NSString *)text
{
    NSAssert(self.inputSource, @"no input source.");
    
    if (!self.inputSource) {
        return ;
    }
    
    if ([self.inputSource isKindOfClass:[UITextField class]]) {
        UITextField *tf = (UITextField *)self.inputSource;
        // 若输入框内容为空，则说明未输入或者被清空了，设置保存的安全字符为空串
        if (tf.text.length < 1) {
            [self.secureText setString:@""];
        }
        
        // 安全模式下 保存的安全字符串拼接输入内容，设置回调，同时输入框显示 •
        if (_isSafety) {
            [self.secureText appendString:text];
            if (self.changeBlock) {
                self.changeBlock(self.secureText);
            }
            text = @"•";
        }
        
        // 输入框插入内容
        if (tf.delegate && [tf.delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
            NSRange range = NSMakeRange(tf.text.length, 1);
            BOOL ret = [tf.delegate textField:tf shouldChangeCharactersInRange:range replacementString:text];
            if (ret) {
                [tf insertText:text];
            }
            else{
                NSLog(@"TextField shouldChangeCharactersInRange return NO.");
            }
        }
        else{
            [tf insertText:text];
        }
        return ;
    }
    
    
    if ([self.inputSource isKindOfClass:[UITextView class]]){
        UITextView *tv = (UITextView *)self.inputSource;
        // 若输入框内容为空，则说明未输入或者被清空了，设置保存的安全字符为空串
        if (tv.text.length < 1) {
            [self.secureText setString:@""];
        }
        
        // 安全模式下 保存的安全字符串拼接输入内容，设置回调，同时输入框显示 •
        if (_isSafety) {
            [self.secureText appendString:text];
            if (self.changeBlock) {
                self.changeBlock(self.secureText);
            }
            text = @"•";
        }
        
        // 输入框插入内容
        if (tv.delegate && [tv.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
            NSRange range = NSMakeRange(tv.text.length, 1);
            BOOL ret = [tv.delegate textView:tv shouldChangeTextInRange:range replacementText:text];
            if (ret) {
                [tv insertText:text];
            }
            else{
                NSLog(@"TextView shouldChangeTextInRange return NO.");
            }
        }
        else{
            [tv insertText:text];
        }
        return ;
    }
}


/**
 删除字符
 */
- (void)deleteText
{
    NSAssert(self.inputSource, @"no input source.");
    
    if (!self.inputSource) {
        return ;
    }
    
    // 安全模式下 保存的安全字符串删除最后一个字符，设置回调
    if (_isSafety && self.secureText.length>0) {
        [self.secureText deleteCharactersInRange:NSMakeRange(self.secureText.length - 1, 1)];
        if (self.changeBlock) {
            self.changeBlock(self.secureText);
        }
    }
    
    // 输入框删除内容
    if ([self.inputSource isKindOfClass:[UITextField class]]) {
        UITextField *tf = (UITextField *)self.inputSource;
        [tf deleteBackward];
        return ;
    }
    
    // 输入框删除内容
    if ([self.inputSource isKindOfClass:[UITextView class]]){
        UITextView *tv = (UITextView *)self.inputSource;
        [tv deleteBackward];
        return ;
    }
}


/**
 结束输入
 */
- (void)endInput
{
    NSAssert(self.inputSource, @"no input source.");
    
    if (!self.inputSource) {
        return ;
    }
    
    // 安全模式下 保存的安全字符串设置回调
    if (_isSafety) {
        if (self.resultBlock) {
            self.resultBlock([self.secureText copy]);
        }
    }
    
    if ([self.inputSource isKindOfClass:[UITextField class]]) {
        UITextField *tf = (UITextField *)self.inputSource;
        [tf resignFirstResponder];
        return ;
    }
    
    if ([self.inputSource isKindOfClass:[UITextView class]]){
        UITextView *tv = (UITextView *)self.inputSource;
        [tv resignFirstResponder];
        return ;
    }
}


#pragma mark -
#pragma mark --- Get Source

/**
 获取全键盘英文字符
 */
- (NSArray *)getQWERTYSource
{
    NSMutableArray *characters = [NSMutableArray arrayWithObjects:@"q",@"w",@"e",@"r",@"t",@"y",@"u",@"i",@"o",@"p",@"a",@"s",@"d",@"f",@"g",@"h",@"j",@"k",@"l",@"z",@"x",@"c",@"v",@"b",@"n",@"m", nil];
    if (!_isSafety) {
        return characters;
    }
    
    // 返回乱序的英文字符
    return [self getRandomSource:characters];
}


/**
 获取特殊字符
 */
- (NSArray *)getSymbolSource
{
    return @[@[@"~",@"+",@"-",@"*",@"/",@"=",@"#",@"%",@"^",@"&"],@[@".",@"@",@"?",@"!",@"_"],@[@"\\",@"|",@"[",@"]",@"{",@"}",@"(",@")",@"<",@">"],@[@":",@",",@";",@"\"",@"'",@"¥",@"$",@"€",@"£",@"•"]];
}


/**
 获取数字键盘数字
 */
- (NSArray *)getNumberSource
{
    NSMutableArray *numbers = [NSMutableArray arrayWithObjects:@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9",@"0", nil];
    
    if (!_isSafety) {
        return numbers;
    }
    
    // 乱序的数字
    return [self getRandomSource:numbers];
}


/**
 乱序数据
 @param mutableArray 入参
 */
- (NSArray *)getRandomSource:(NSMutableArray *)mutableArray
{
    NSInteger count = mutableArray.count;
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:count];
    for (NSInteger i = 0; i < count; i ++) {
        int number = arc4random()%(mutableArray.count);
        [array addObject:mutableArray[number]];
        [mutableArray removeObjectAtIndex:number];
    }
    
    return  [array copy];
}


#pragma mark -
#pragma mark --- Add Subview

/**
 添加英文字符按钮
 */
- (void)addCharsButton
{
    CGFloat y1 = floorf(_spaceY*0.5);
    CGFloat x2 = floorf(_spaceX+_btnW*0.63);
    CGFloat y2 = floorf(_spaceY*1.5+_btnH);
    CGFloat x3 = floorf(x2+_btnW+_spaceX);
    CGFloat y3 = floorf(_spaceY*2.5+_btnH*2);
    CGFloat sBtnW = floorf((_btnW*2.5+_spaceX*2)/2);
    NSInteger count = self.chars.count;
    
    for (NSInteger i = 0; i < (count + 2); i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.tag = i;
        btn.layer.cornerRadius = 4;
        btn.layer.masksToBounds = YES;
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:20.0f];
        [btn addTarget:self action:@selector(keyBoardCharButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        
        // 安全模式下 没有点击效果
        if (_isSafety) {
            // 大写和删除按钮
            if (i > (count-1)) {
                [btn setBackgroundColor:_btnBgColor];
            }
            else{
                // 普通的英文按钮
                [btn setBackgroundColor:[UIColor whiteColor]];
            }
        }
        else {
            // 非安全模式，设置点击效果
            if (i > (count-1)) {
                [btn setBackgroundImage:_normalImage forState:UIControlStateSelected];
                [btn setBackgroundImage:_normalImage forState:UIControlStateHighlighted];
                [btn setBackgroundImage:_highlightImage forState:UIControlStateNormal];
            }
            else{
                [btn setBackgroundImage:_highlightImage forState:UIControlStateHighlighted];
                [btn setBackgroundImage:_normalImage forState:UIControlStateNormal];
            }
        }
        
        if (i == count) {
            // 大小写按钮
            btn.frame = CGRectMake(_spaceX,y3,sBtnW,_btnH);
            [btn setImage:[UIImage imageNamed:@"upper_low"] forState:UIControlStateNormal];
            [btn setImage:[UIImage imageNamed:@"upper_up"] forState:UIControlStateSelected];
            btn.imageEdgeInsets = UIEdgeInsetsMake(_btnH*0.5-12, sBtnW*0.5-12, _btnH*0.5-12, sBtnW*0.5-12);
        }
        else if (i == (count+1)){
            // 删除
            btn.frame = CGRectMake(_viewW - _spaceX - sBtnW,y3,sBtnW,_btnH);
            [btn setImage:[UIImage imageNamed:@"delete"] forState:UIControlStateNormal];
            btn.imageEdgeInsets = UIEdgeInsetsMake(_btnH*0.5-12, sBtnW*0.5-12, _btnH*0.5-12, sBtnW*0.5-12);
        }
        else{
            // 英文字符
            [btn setTitle:self.chars[i] forState:UIControlStateNormal];
            if (i < 10) {
                btn.frame = CGRectMake(_spaceX + (_btnW+_spaceX)*i,y1,_btnW,_btnH);
            }
            else if (i > 9 && i < 19){
                btn.frame = CGRectMake(x2 + (_btnW+_spaceX)*(i-10),y2,_btnW,_btnH);
            }
            else{
                btn.frame = CGRectMake(x3 + (_btnW+_spaceX)*(i-19),y3,_btnW,_btnH);
            }
        }
        
        [self.charsView addSubview:btn];
        [self.charsBtns addObject:btn];
    }
}


/**
 添加特殊字符
 */
- (void)addSymbolButton
{
    CGFloat y1 = floorf(_spaceY*0.5);
    CGFloat y2 = floorf(_spaceY*1.5+_btnH);
    
    CGFloat sBtnW = floorf((_btnW*2.5+_spaceX*2)/2);
    CGFloat x3 = floorf(sBtnW+_btnW*0.5+_spaceX);
    CGFloat y3 = floorf(_spaceY*2.5+_btnH*2);
    
    // 键盘两行20个可变的+5个不变的，
    NSInteger count = 25;
    
    // + 2 是更多字符切换和删除按钮
    for (NSInteger i = 0; i < (count + 2); i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.tag = i;
        btn.layer.cornerRadius = 4;
        btn.layer.masksToBounds = YES;
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:20.0f];
        [btn addTarget:self action:@selector(keyBoardSymbolsButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        
        // 安全模式下 没有点击效果
        if (_isSafety) {
            if (i > (count-1)) {
                [btn setBackgroundColor:_btnBgColor];
            }
            else{
                [btn setBackgroundColor:[UIColor whiteColor]];
            }
        }
        else {
            // 非安全模式，设置点击效果
            if (i > (count-1)) {
                [btn setBackgroundImage:_normalImage forState:UIControlStateSelected];
                [btn setBackgroundImage:_normalImage forState:UIControlStateHighlighted];
                [btn setBackgroundImage:_highlightImage forState:UIControlStateNormal];
            }
            else{
                [btn setBackgroundImage:_highlightImage forState:UIControlStateHighlighted];
                [btn setBackgroundImage:_normalImage forState:UIControlStateNormal];
            }
        }
        
        if (i == count) {
            // 更多字符切换按钮
            btn.titleLabel.font = [UIFont systemFontOfSize:17.0f];
            btn.frame = CGRectMake(_spaceX,y3,sBtnW,_btnH);
            [btn setTitle:@"$<¥" forState:UIControlStateNormal];
        }
        else if (i == (count+1)){
            // 删除按钮
            btn.titleLabel.font = [UIFont systemFontOfSize:17.0f];
            btn.frame = CGRectMake(_viewW - _spaceX - sBtnW,y3,sBtnW,_btnH);
            [btn setImage:[UIImage imageNamed:@"delete"] forState:UIControlStateNormal];
            btn.imageEdgeInsets = UIEdgeInsetsMake(_btnH*0.5-12, sBtnW*0.5-12, _btnH*0.5-12, sBtnW*0.5-12);
        }
        else{
            // 特殊字符按钮
            if (i < 10) {
                btn.frame = CGRectMake(_spaceX + (_btnW+_spaceX)*i,y1,_btnW,_btnH);
                [btn setTitle:self.numbers[i] forState:UIControlStateNormal];
            }
            else if (i > 9 && i < 20){
                [btn setTitle:self.symbols[0][i-10] forState:UIControlStateNormal];
                btn.frame = CGRectMake(_spaceX + (_btnW+_spaceX)*(i-10),y2,_btnW,_btnH);
            }
            else{
                [btn setTitle:self.symbols[1][i-20] forState:UIControlStateNormal];
                btn.frame = CGRectMake(x3 + (sBtnW+_spaceX)*(i-20),y3,sBtnW,_btnH);
            }
        }
        
        [self.symbolView addSubview:btn];
        [self.symbolsBtns addObject:btn];
    }
}

// 全键盘底部功能按钮
- (void)addKeyBoardBottomButton
{
    CGFloat offsetY = _spaceY*0.5;
    CGFloat y = _viewH - offsetY - _btnH;
    CGFloat normalBtnW = floorf((_btnW*2.5+_spaceX*2)/2);
    CGFloat spaceBtnW = floorf(_viewW - normalBtnW*4 -_spaceX*5);
    
    NSArray *btnTitles = @[@"123",@"+/=",@"空格",@"完成"];
    NSArray *btnHTitles = @[@"ABC",@"ABC",@"空格",@"完成"];
    
    for (NSInteger i = 0; i < 4; i ++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.tag = 10 + i;
        btn.layer.cornerRadius = 4;
        btn.layer.masksToBounds = YES;
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:17.0f];
        [btn addTarget:self action:@selector(keyBoardBottomButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [btn setTitle:btnTitles[i] forState:UIControlStateNormal];
        [btn setTitle:btnHTitles[i] forState:UIControlStateSelected];
        [btn setSelected:NO];
        
        // 设置点击效果
        if (i == 2) {
            if (_isSafety) {
                [btn setBackgroundColor:[UIColor whiteColor]];
            }
            else {
                [btn setBackgroundImage:_highlightImage forState:UIControlStateHighlighted];
                [btn setBackgroundImage:_normalImage forState:UIControlStateNormal];
            }
            btn.frame = CGRectMake(_spaceX + 2*normalBtnW + 2*_spaceX,y,spaceBtnW,_btnH);
        }
        else if (i == 3){
            if (_isSafety) {
                [btn setBackgroundColor:_btnBgColor];
            }
            else {
                [btn setBackgroundImage:_normalImage forState:UIControlStateHighlighted];
                [btn setBackgroundImage:_highlightImage forState:UIControlStateNormal];
            }
            btn.frame = CGRectMake(_viewW - _spaceX - normalBtnW*2,y,normalBtnW * 2,_btnH);
        }
        else{
            if (_isSafety) {
                [btn setBackgroundColor:_btnBgColor];
            }
            else {
                [btn setBackgroundImage:_normalImage forState:UIControlStateHighlighted];
                [btn setBackgroundImage:_highlightImage forState:UIControlStateNormal];
            }
            btn.frame = CGRectMake(_spaceX + i*normalBtnW + i*_spaceX,y,normalBtnW,_btnH);
        }
        
        [self.qwertyView addSubview:btn];
        [self.bottomBtns addObject:btn];
    }
}


/**
 添加数字键盘
 */
- (void)addKeyBoardForNumber
{
    CGFloat btnH = floorf((_viewH - 30 - 5*_spaceX)/4);
    CGFloat btnW = floorf((_viewW - 5*_spaceX)/4);
    CGFloat y = 30;
    
    for (NSInteger i = 0; i < 4; i ++) {
        for (NSInteger j = 0; j < 4; j ++) {
            if (i < 3) {
                // 数字区域
                UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
                btn.frame = CGRectMake(_spaceX*(i?(i+1):1) + btnW*i, y + _spaceX*(j?(j+1):1) + btnH*j, btnW, btnH);
                btn.layer.cornerRadius = 4;
                btn.layer.masksToBounds = YES;
                btn.tag = j*3 + i+1;
                [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                btn.titleLabel.font = [UIFont systemFontOfSize:18.0f];
                [btn addTarget:self action:@selector(numberButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
                
                // 设置点击效果
                if (_isSafety) {
                    [btn setBackgroundColor:_btnBgColor];
                }
                else{
                    [btn setBackgroundImage:_normalImage forState:UIControlStateHighlighted];
                    [btn setBackgroundImage:_highlightImage forState:UIControlStateNormal];
                }
                
                if (j == 3) {
                    if (i == 0){
                        if (!_isOnlyNumber) {
                            [btn setTitle:@"ABC" forState:UIControlStateNormal];
                        }
                    }
                    else if (i == 1) {
                        [btn setTitle:self.numbers.lastObject forState:UIControlStateNormal];
                    }
                    else if (i == 2){
                        [btn setTitle:@"." forState:UIControlStateNormal];
                    }
                }
                else{
                    [btn setTitle:self.numbers[btn.tag-1] forState:UIControlStateNormal];
                }
                
                [self.numbersView addSubview:btn];
            }
            else{
                // 删除和完成按钮
                if (j < 2) {
                    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
                    btn.layer.cornerRadius = 4;
                    btn.layer.masksToBounds = YES;
                    btn.frame = CGRectMake(_viewW - btnW - _spaceX, y + _spaceX*(j+1) + (btnH*2+_spaceX)*j, btnW, btnH*2+_spaceX);
                    
                    if (_isSafety) {
                        [btn setBackgroundColor:_btnBgColor];
                    }
                    else {
                        [btn setBackgroundImage:_normalImage forState:UIControlStateHighlighted];
                        [btn setBackgroundImage:_highlightImage forState:UIControlStateNormal];
                    }
                    
                    if (j == 0) {
                        btn.tag = 13;
                        [btn setImage:[UIImage imageNamed:@"delete"] forState:UIControlStateNormal];
                        btn.imageEdgeInsets = UIEdgeInsetsMake(btnH - 13, btnW*0.5-13, btnH - 13, btnW*0.5-13);
                    }
                    else{
                        btn.tag = 14;
                        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                        btn.titleLabel.font = [UIFont systemFontOfSize:18.0f];
                        [btn setTitle:@"完成" forState:UIControlStateNormal];
                    }
                    
                    [btn addTarget:self action:@selector(numberButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
                    [self.numbersView addSubview:btn];
                }
            }
        }
    }
}


#pragma mark -
#pragma mark --- Setter & Getter

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, _viewW-40, 30)];
        _titleLabel.textColor = [UIColor blackColor];
        _titleLabel.textAlignment = NSTextAlignmentLeft;
        _titleLabel.font = [UIFont systemFontOfSize:13.0f];
        _titleLabel.text = @"安全输入";
    }
    return _titleLabel;
}


/**
 显示安全输入logo
 
 @return safetyImageV
 */
- (UIImageView *)safetyImageV
{
    if (!_safetyImageV) {
        _safetyImageV = [[UIImageView alloc] initWithFrame:CGRectMake(_viewW - 30, 5, 20, 20)];
        [_safetyImageV setImage:[UIImage imageNamed:@"safetyLogo"]];
    }
    return _safetyImageV;
}

- (NSMutableArray<UIButton *> *)bottomBtns
{
    if (!_bottomBtns) {
        _bottomBtns = [NSMutableArray arrayWithCapacity:4];
    }
    return _bottomBtns;
}

- (NSMutableArray<UIButton *> *)charsBtns
{
    if (!_charsBtns) {
        _charsBtns = [NSMutableArray arrayWithCapacity:self.chars.count];
    }
    return _charsBtns;
}

- (NSMutableArray<UIButton *> *)symbolsBtns
{
    if (!_symbolsBtns) {
        _symbolsBtns = [NSMutableArray arrayWithCapacity:25];
    }
    return _symbolsBtns;
}

- (NSArray<NSString *> *)chars
{
    if (!_chars) {
        _chars = [self getQWERTYSource];
    }
    return _chars;
}

- (NSArray<NSString *> *)numbers
{
    if (!_numbers) {
        _numbers = [self getNumberSource];
    }
    return _numbers;
}

- (NSArray *)symbols
{
    if (!_symbols) {
        _symbols = [self getSymbolSource];
    }
    return _symbols;
}

- (NSMutableString *)secureText
{
    if (!_secureText) {
        _secureText = [[NSMutableString alloc] initWithCapacity:1];
    }
    return _secureText;
}


- (UIView *)numbersView
{
    if (!_numbersView) {
        _numbersView = [[UIView alloc] initWithFrame:self.bounds];
        _numbersView.backgroundColor = [UIColor clearColor];
        [self addKeyBoardForNumber];
    }
    return _numbersView;
}

- (UIView *)qwertyView
{
    if (!_qwertyView) {
        _qwertyView = [[UIView alloc] initWithFrame:self.bounds];
        _qwertyView.backgroundColor = [UIColor clearColor];
        [self.qwertyView addSubview:self.charsView];
        [self addKeyBoardBottomButton];
    }
    return _qwertyView;
}


- (UIView *)charsView
{
    if (!_charsView) {
        _charsView = [[UIView alloc] initWithFrame:CGRectMake(0, 30, _viewW, _viewH - _spaceY*0.5 - _btnH - 30)];
        _charsView.backgroundColor = [UIColor clearColor];
        [self addCharsButton];
    }
    return _charsView;
}


- (UIView *)symbolView
{
    if (!_symbolView) {
        _symbolView = [[UIView alloc] initWithFrame:CGRectMake(0, 30, _viewW, _viewH - _spaceY*0.5 - _btnH - 30)];
        _symbolView.backgroundColor = [UIColor clearColor];
        [self addSymbolButton];
    }
    return _symbolView;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:LRColorFromRGB(0xd1d6dc)];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
