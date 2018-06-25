//
//  LRSafetyKeyboard.m
//  LRSafetyKeyboard
//
//  Created by luris on 2018/6/22.
//  Copyright © 2018年 luris. All rights reserved.
//

#import "LRSafetyKeyboard.h"

#define LRColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define LRSCREEN_WIDTH   ([UIScreen mainScreen].bounds.size.width)
#define LRSCREEN_HEIGHT ([UIScreen mainScreen].bounds.size.height)
#define iPhoneX ((LRSCREEN_WIDTH == 375.0f) && (LRSCREEN_HEIGHT == 812.0f))

#define SPACE_Y (10) // 键盘按键纵向间距
#define SPACE_X (6)  // 键盘按钮横向间距
#define KEYBOARD_H (260) // 键盘高度

#define QWERTY_SOURCES (@[@"q",@"w",@"e",@"r",@"t",@"y",@"u",@"i",@"o",@"p",@"a",@"s",@"d",@"f",@"g",@"h",@"j",@"k",@"l",@"z",@"x",@"c",@"v",@"b",@"n",@"m"])

#define SYMBOL_SOURCES (@[@[@"~",@"+",@"-",@"*",@"/",@"=",@"#",@"%",@"^",@"&"],@[@".",@"@",@"?",@"!",@"_"],@[@"\\",@"|",@"[",@"]",@"{",@"}",@"(",@")",@"<",@">"],@[@":",@",",@";",@"\"",@"'",@"¥",@"$",@"€",@"£",@"•"]])

#define NUMBER_SOURCES (@[@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9",@"0"])


@interface LRSafetyKeyboard ()
{
@private
    CGFloat     _btnH;
    CGFloat     _btnW;
   
    UIColor    *_btnBgColor;
    
    BOOL        _isUpper;
    BOOL        _isMoreSymbol;
}


/**
 键盘类型
 */
@property(nonatomic, assign)LRSafetyKeyboardType type;

/**
 两个回调Block
 */
@property(nonatomic, copy)TextBlock        resultBlock;
@property(nonatomic, copy)TextBlock        changeBlock;

/**
 添加键盘的view
 */
@property(nonatomic, weak)UIView            *inputSource;

/**
 键盘头部标题
 */
@property(nonatomic, strong)UILabel         *titleLabel;

/**
 数字键盘视图
 */
@property(nonatomic, strong)UIView          *numbersView;

/**
 全键盘背景视图
 */
@property(nonatomic, strong)UIView          *qwertyView;

/**
 英文字符视图
 */
@property(nonatomic, strong)UIView          *charsView;

/**
 特殊符号视图
 */
@property(nonatomic, strong)UIView          *symbolView;

/**
 英文字符
 */
@property(nonatomic, strong)NSArray<NSString *> *chars;

/**
 数字
 */
@property(nonatomic, strong)NSArray<NSString *> *numbers;

/**
 特殊符号
 */
@property(nonatomic, strong)NSArray<NSString *> *symbols;

/**
 保存输入的字符串
 */
@property(nonatomic, strong)NSMutableString   *secureText;

@end


@implementation LRSafetyKeyboard

- (instancetype)initWithInputSource:(UIView *)view
                       keyboardType:(LRSafetyKeyboardType)type
{
    self = [super initWithFrame:CGRectMake(0, 0, LRSCREEN_WIDTH, iPhoneX?290:260)];
    if (self) {
        self.inputSource = view;
        [self configValue];
        self.backgroundColor = [UIColor whiteColor];
        // 添加标题
        [self addSubview:self.titleLabel];
        // 根据类型添加键盘
        [self addSafetyKeyboardWithType:type];
        [self addNotification];
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

- (void)secureTextDidEndEditing:(TextBlock)callback
{
    self.resultBlock = callback;
}

- (void)secureTextDidChange:(TextBlock)callback
{
    self.changeBlock = callback;
}

#pragma mark -
#pragma mark --- Config Value
- (void)configValue
{
    // 键盘按钮高度
    _btnH = floorf((KEYBOARD_H - 30 - SPACE_Y*4)/4);
    // 键盘按钮宽度
    _btnW = floorf((LRSCREEN_WIDTH - SPACE_X*10)/10);
    // 键盘按钮背景色
    _btnBgColor = LRColorFromRGB(0xacb3be);

    // 安全输入
    _secureEntry = YES;
    // 是否大写
    _isUpper = NO;
    // 是否更多特殊字符
    _isMoreSymbol = NO;
}

- (void)addSafetyKeyboardWithType:(LRSafetyKeyboardType)type
{
    if (type == LRSafetyKeyboardTypeSafetyQWERTY) {
        self.type = type;
        [self addSubview:self.qwertyView];
        [self addKeyBoardBottomButton];
        return ;
    }

    self.type = type;
    [self addSubview:self.numbersView];
}

#pragma mark -
#pragma mark --- Notification

- (void)addNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:UIKeyboardWillShowNotification];
    [self removeObserver:self forKeyPath:UIKeyboardDidHideNotification];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    if ([self.inputSource isKindOfClass:[UITextField class]]) {
        UITextField *tf = (UITextField *)self.inputSource;
        [self.secureText setString:tf.text];
    }
    
    if ([self.inputSource isKindOfClass:[UITextView class]]) {
        UITextView *tv = (UITextView *)self.inputSource;
        [self.secureText setString:tv.text];
    }
    
    
    self.numbers = [self getRandomSource:NUMBER_SOURCES];

    if (self.type == LRSafetyKeyboardTypeSafetyQWERTY) {
        self.chars = [self getRandomSource:QWERTY_SOURCES];
        [self setCharsForQWERTY];
        return ;
    }

    [self setNumberForNumberPad];
}

- (void)keyboardDidHide:(NSNotification *)notification
{
    self.chars = nil;
    self.numbers = nil;
    [self.secureText setString:@""];
}

#pragma mark -
#pragma mark --- Add Subview

/**
 添加英文字符按钮
 */
- (void)addCharsButton
{
    CGFloat y1 = floorf(SPACE_Y*0.5);
    CGFloat x2 = floorf(SPACE_X+_btnW*0.63);
    CGFloat y2 = floorf(SPACE_Y*1.5+_btnH);
    CGFloat x3 = floorf(x2+_btnW+SPACE_X);
    CGFloat y3 = floorf(SPACE_Y*2.5+_btnH*2);
    CGFloat sBtnW = floorf((_btnW*2.5+SPACE_X*2)/2);
    NSInteger count = 26;
    
    for (NSInteger i = 0; i < (count + 2); i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.tag = i;
        btn.layer.cornerRadius = 4;
        btn.layer.masksToBounds = YES;
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:20.0f];
        [btn addTarget:self action:@selector(keyBoardCharButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        btn.enabled = NO;
        [btn setBackgroundColor:_btnBgColor];
        
        if (i == count) {
            // 大小写按钮
            btn.frame = CGRectMake(SPACE_X,y3,sBtnW,_btnH);
            [btn setImage:[UIImage imageNamed:@"upper_low"] forState:UIControlStateNormal];
            [btn setImage:[UIImage imageNamed:@"upper_up"] forState:UIControlStateSelected];
            btn.imageEdgeInsets = UIEdgeInsetsMake(_btnH*0.5-12, sBtnW*0.5-12, _btnH*0.5-12, sBtnW*0.5-12);
        }
        else if (i == (count+1)){
            // 删除
            btn.frame = CGRectMake(LRSCREEN_WIDTH - SPACE_X - sBtnW,y3,sBtnW,_btnH);
            [btn setImage:[UIImage imageNamed:@"delete"] forState:UIControlStateNormal];
            btn.imageEdgeInsets = UIEdgeInsetsMake(_btnH*0.5-12, sBtnW*0.5-12, _btnH*0.5-12, sBtnW*0.5-12);
        }
        else{
            // 英文字符
            if (i < 10) {
                btn.frame = CGRectMake(SPACE_X + (_btnW+SPACE_X)*i,y1,_btnW,_btnH);
            }
            else if (i > 9 && i < 19){
                btn.frame = CGRectMake(x2 + (_btnW+SPACE_X)*(i-10),y2,_btnW,_btnH);
            }
            else{
                btn.frame = CGRectMake(x3 + (_btnW+SPACE_X)*(i-19),y3,_btnW,_btnH);
            }
        }
        
        [self.charsView addSubview:btn];
    }
}


/**
 添加特殊字符
 */
- (void)addSymbolButton
{
    CGFloat y1 = floorf(SPACE_X*0.5);
    CGFloat y2 = floorf(SPACE_Y*1.5+_btnH);
    
    CGFloat sBtnW = floorf((_btnW*2.5+SPACE_X*2)/2);
    CGFloat x3 = floorf(sBtnW+_btnW*0.5+SPACE_X);
    CGFloat y3 = floorf(SPACE_Y*2.5+_btnH*2);
    
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
        [btn setBackgroundColor:_btnBgColor];

        if (i == count) {
            // 更多字符切换按钮
            btn.titleLabel.font = [UIFont systemFontOfSize:17.0f];
            btn.frame = CGRectMake(SPACE_X,y3,sBtnW,_btnH);
            [btn setTitle:@"$<¥" forState:UIControlStateNormal];
        }
        else if (i == (count+1)){
            // 删除按钮
            btn.titleLabel.font = [UIFont systemFontOfSize:17.0f];
            btn.frame = CGRectMake(LRSCREEN_WIDTH - SPACE_X - sBtnW,y3,sBtnW,_btnH);
            [btn setImage:[UIImage imageNamed:@"delete"] forState:UIControlStateNormal];
            btn.imageEdgeInsets = UIEdgeInsetsMake(_btnH*0.5-12, sBtnW*0.5-12, _btnH*0.5-12, sBtnW*0.5-12);
        }
        else{
            // 特殊字符按钮
            if (i < 10) {
                btn.frame = CGRectMake(SPACE_X + (_btnW+SPACE_X)*i,y1,_btnW,_btnH);
            }
            else if (i > 9 && i < 20){
                [btn setTitle:SYMBOL_SOURCES[0][i-10] forState:UIControlStateNormal];
                btn.frame = CGRectMake(SPACE_X + (_btnW+SPACE_X)*(i-10),y2,_btnW,_btnH);
            }
            else{
                [btn setTitle:SYMBOL_SOURCES[1][i-20] forState:UIControlStateNormal];
                btn.frame = CGRectMake(x3 + (sBtnW+SPACE_X)*(i-20),y3,sBtnW,_btnH);
            }
        }
        
        [self.symbolView addSubview:btn];
    }
}

// 全键盘底部功能按钮
- (void)addKeyBoardBottomButton
{
    CGFloat y = KEYBOARD_H - SPACE_Y*0.5 - _btnH;
    CGFloat normalBtnW = floorf((_btnW*2.5+SPACE_X*2)/2);
    CGFloat spaceBtnW = floorf(LRSCREEN_WIDTH - normalBtnW*3 -SPACE_X*5);
    
    NSArray *btnTitles = @[@"+/=",@"空格",@"完成"];
    
    for (NSInteger i = 0; i < btnTitles.count; i ++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.tag = i;
        btn.layer.cornerRadius = 4;
        btn.layer.masksToBounds = YES;
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:17.0f];
        [btn addTarget:self action:@selector(keyBoardBottomButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [btn setTitle:btnTitles[i] forState:UIControlStateNormal];
        [btn setSelected:NO];
        
        // 设置点击效果
        if (i == 1) {
            btn.frame = CGRectMake(SPACE_X + normalBtnW + 2*SPACE_X,y,spaceBtnW,_btnH);
            [btn setBackgroundColor:[UIColor whiteColor]];
        }
        else if (i == 2){
            btn.frame = CGRectMake(LRSCREEN_WIDTH - SPACE_X - normalBtnW*2,y,normalBtnW * 2,_btnH);
            [btn setBackgroundColor:_btnBgColor];
        }
        else{
            btn.frame = CGRectMake(SPACE_X + i*normalBtnW + i*SPACE_X,y,normalBtnW,_btnH);
            [btn setBackgroundColor:_btnBgColor];
            [btn setTitle:@"ABC" forState:UIControlStateSelected];
        }
        [self.qwertyView addSubview:btn];
    }
}


/**
 添加数字键盘
 */
- (void)addKeyBoardForNumber
{
    CGFloat btnH = floorf((KEYBOARD_H - 30 - 5*SPACE_X)/4);
    CGFloat btnW = floorf((LRSCREEN_WIDTH - 5*SPACE_X)/4);
    
    for (NSInteger i = 0; i < 4; i ++) {
        for (NSInteger j = 0; j < 4; j ++) {
            if (i < 3) {
                // 数字区域
                UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
                btn.frame = CGRectMake(SPACE_X*(i?(i+1):1) + btnW*i, 30 + SPACE_X*(j?(j+1):1) + btnH*j, btnW, btnH);
                btn.layer.cornerRadius = 4;
                btn.layer.masksToBounds = YES;
                btn.tag = j*3 + i+1;
                [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                btn.titleLabel.font = [UIFont systemFontOfSize:18.0f];
                [btn addTarget:self action:@selector(numberButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
                [btn setBackgroundColor:_btnBgColor];

                if (i == 2 && j == 3) {
                    [btn setTitle:@"." forState:UIControlStateNormal];
                }
                else if (i == 0 && j == 3){
                    [btn setTitle:@"%" forState:UIControlStateNormal];
                }
                
                [self.numbersView addSubview:btn];
            }
            else{
                // 删除和完成按钮
                if (j < 2) {
                    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
                    btn.layer.cornerRadius = 4;
                    btn.layer.masksToBounds = YES;
                    btn.frame = CGRectMake(LRSCREEN_WIDTH - btnW - SPACE_X, 30 + SPACE_X*(j+1) + (btnH*2+SPACE_X)*j, btnW, btnH*2+SPACE_X);
                    [btn setBackgroundColor:_btnBgColor];

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
        case 0:{
            // 英文特殊符号切换
            [self showSymbolKeyboard];
            break;
        }
        case 1:{
            // 空格
            [self insertText:@" "];
            break;
        }
        case 2:{
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
        [self insertText:SYMBOL_SOURCES[1][tag-20]];
    }
    else{
        // 输入特殊字符
        if (tag < 10){
            if (_isMoreSymbol) {
                [self insertText:SYMBOL_SOURCES[2][tag]];
            }
            else{
                [self insertText:self.numbers[tag]];
            }
        }
        else{
            if (_isMoreSymbol) {
                [self insertText:SYMBOL_SOURCES[3][tag-10]];
            }
            else{
                [self insertText:SYMBOL_SOURCES[0][tag-10]];
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
    
    if (tag == 10) {
        [self insertText:@"%"];
        return ;
    }
    
    // 输入数字
    if (tag < 10) {
        [self insertText:self.numbers[tag-1]];
    }
    
    
    // 输入数字
    if (tag == 11) {
        [self insertText:self.numbers.lastObject];
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
 乱序数据
 @param array 入参
 */
- (NSArray *)getRandomSource:(NSArray *)array
{
    NSMutableArray *mutableArray = [array mutableCopy];
    NSInteger count = mutableArray.count;
    NSMutableArray *temp = [NSMutableArray arrayWithCapacity:count];
    for (NSInteger i = 0; i < count; i ++) {
        int number = arc4random()%(mutableArray.count);
        [temp addObject:mutableArray[number]];
        [mutableArray removeObjectAtIndex:number];
    }
    
    return  [temp copy];
}

- (void)setCharsForQWERTY
{
    for (UIButton *btn in self.charsView.subviews) {
        btn.enabled = YES;
        if (btn.tag < self.chars.count) {
            [btn setTitle:self.chars[btn.tag] forState:UIControlStateNormal];
        }
    }
}

- (void)setNumberForNumberPad
{
    for (UIButton *btn in self.numbersView.subviews) {
        if (btn.tag < 10) {
            [btn setTitle:self.numbers[btn.tag-1] forState:UIControlStateNormal];
        }
        else if (btn.tag == 11){
            [btn setTitle:self.numbers.lastObject forState:UIControlStateNormal];
        }
    }
}

/**
 设置字符大写
 */
- (void)upperCaseString
{
    _isUpper = YES;
    for (UIButton *btn in self.charsView.subviews) {
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
    for (UIButton *btn in self.charsView.subviews) {
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
    for (UIButton *btn in self.symbolView.subviews) {
        if (btn.tag < 20) {
            if (btn.tag < 10) {
                [btn setTitle:SYMBOL_SOURCES[2][btn.tag] forState:UIControlStateNormal];
            }
            else{
                [btn setTitle:SYMBOL_SOURCES[3][btn.tag-10] forState:UIControlStateNormal];
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
    for (UIButton *btn in self.symbolView.subviews) {
        if (btn.tag < 20) {
            if (btn.tag < 10) {
                [btn setTitle:self.numbers[btn.tag] forState:UIControlStateNormal];
            }
            else{
                [btn setTitle:SYMBOL_SOURCES[0][btn.tag-10] forState:UIControlStateNormal];
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
    self.charsView.hidden = !self.charsView.hidden;
    if (_symbolView) {
        self.symbolView.hidden = !self.symbolView.hidden;
    }
    else{
        [self.qwertyView addSubview:self.symbolView];
    }
    
    for (UIButton *btn in self.symbolView.subviews) {
        if (btn.tag < 10) {
            [btn setTitle:self.numbers[btn.tag] forState:UIControlStateNormal];
        }
    }
}


/**
 显示全键盘
 */
- (void)showQWERTYKeyboard
{
    self.symbolView.hidden = YES;
    self.numbersView.hidden = YES;
    self.qwertyView.hidden = NO;
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
        
        // 保存的安全字符串拼接输入内容，设置回调，同时输入框显示 •
        [self.secureText appendString:text];
        if (self.changeBlock) {
            self.changeBlock(self.secureText);
        }
        
        if (self.secureEntry) {
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
        [self.secureText appendString:text];
        if (self.changeBlock) {
            self.changeBlock(self.secureText);
        }

        if (self.secureEntry) {
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
    if (self.secureText.length>0) {
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
    if (self.resultBlock) {
        self.resultBlock(self.secureText);
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
#pragma mark --- Setter & Getter

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, LRSCREEN_WIDTH-20, 30)];
        _titleLabel.textColor = [UIColor blackColor];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont systemFontOfSize:13.0f];
        _titleLabel.text = @"安全输入";
    }
    return _titleLabel;
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
        [_qwertyView addSubview:self.charsView];
    }
    return _qwertyView;
}


- (UIView *)charsView
{
    if (!_charsView) {
        _charsView = [[UIView alloc] initWithFrame:CGRectMake(0, 30, LRSCREEN_WIDTH, KEYBOARD_H - SPACE_Y*0.5 - _btnH - 30)];
        _charsView.backgroundColor = [UIColor clearColor];
        [self addCharsButton];
    }
    return _charsView;
}


- (UIView *)symbolView
{
    if (!_symbolView) {
        _symbolView = [[UIView alloc] initWithFrame:CGRectMake(0, 30, LRSCREEN_WIDTH, KEYBOARD_H - SPACE_Y*0.5 - _btnH - 30)];
        _symbolView.backgroundColor = [UIColor clearColor];
        [self addSymbolButton];
    }
    return _symbolView;
}

- (NSMutableString *)secureText
{
    if (!_secureText) {
        _secureText = [[NSMutableString alloc] initWithCapacity:1];
    }
    return _secureText;
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
