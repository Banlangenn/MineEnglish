//
//  TextMessageTableViewCell.m
// X5
//
//  Created by yebw on 2017/8/25.
//  Copyright © 2017年 mfox. All rights reserved.
//

#import "TextMessageTableViewCell.h"

NSString * const LeftTextMessageTableViewCellId = @"LeftTextMessageTableViewCellId";
NSString * const RightTextMessageTableViewCellId = @"RightTextMessageTableViewCellId";

@interface TextMessageTableViewCell()

@property (nonatomic, weak) IBOutlet UILabel *messageTextLabel;
@property (nonatomic, weak) IBOutlet UIImageView *textBackgroundImageView;

@end

@implementation TextMessageTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    // 标签的最大宽度
#if MANAGERSIDE
        self.messageTextLabel.preferredMaxLayoutWidth = kColumnThreeWidth - 64 * 2 - 12 - 20;
#else
       self.messageTextLabel.preferredMaxLayoutWidth = [UIScreen mainScreen].bounds.size.width - 64 * 2 - 12 - 20;
#endif

}

+ (CGFloat)heightOfMessage:(AVIMTypedMessage *)message {

    static TextMessageTableViewCell *cell = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 左右计算高度都是一样的
        cell = [[[NSBundle mainBundle] loadNibNamed:@"RightTextMessageTableViewCell" owner:nil options:nil] lastObject];
    });
    
    [cell setupWithUser:nil message:message];
    
    CGSize size = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    
//    if (![message isKindOfClass:[AVIMTextMessage class]]) {
//        size.height = 95;
//    }
    return size.height + 5;
}

- (void)setupWithUser:(User *)user message:(AVIMTypedMessage *)message {
   
    [super setupWithUser:user message:message];
    NSString *backgroundImageName = message.ioType==AVIMMessageIOTypeIn?@"对话框_白色":@"对话框_蓝色";
    UIImage *image = [UIImage imageNamed:backgroundImageName];
    image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(30, 20, 10, 20) resizingMode:UIImageResizingModeStretch];
    self.textBackgroundImageView.image = image;
    
    if ([message isKindOfClass:[AVIMTextMessage class]]) {
        
        AVIMTextMessage *textMessage = (AVIMTextMessage *)(message);
        self.messageTextLabel.text = textMessage.text;
    } else {
        
        NSTextAttachment *attach = [[NSTextAttachment alloc] init];
        attach.bounds = CGRectMake(0, -3, 18, 18);
        NSMutableAttributedString * attr = [[NSMutableAttributedString alloc] init];
        NSString *text = message.text;
        if ([message.text isEqualToString:kHomeworkTaskFollowUpName]) {
            text = @"跟读任务";
        }
        NSString *title = [NSString stringWithFormat:@"     %@     ",text];
        if (message.ioType==AVIMMessageIOTypeIn) {

//            attach.image = [UIImage imageNamed:@"chat_talk3"];
            [attr appendAttributedString:[[NSAttributedString alloc] initWithString:title]];
//            [attr appendAttributedString:[NSAttributedString attributedStringWithAttachment:attach]];
        } else {
//            attach.image = [UIImage imageNamed:@"right_chat_talk3"];
//            [attr appendAttributedString:[NSAttributedString attributedStringWithAttachment:attach]];
            [attr appendAttributedString:[[NSAttributedString alloc] initWithString:title]];
        }
        [attr addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:NSMakeRange(0, attr.length)];
        self.messageTextLabel.attributedText = attr;
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    if (self.clickCallback) {
        self.clickCallback();
    }
}

@end


