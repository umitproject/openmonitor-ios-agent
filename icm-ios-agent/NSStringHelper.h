
#import <Foundation/Foundation.h>


#define IsNumeric(c)						('0' <= (c) && (c) <= '9')
#define IsAlpha(c)							('a' <= (c) && (c) <= 'z' || 'A' <= (c) && (c) <= 'Z')
#define IsAlphaNum(c)						(IsAlpha(c) || IsNumeric(c))
#define IsWordLetter(c)						(IsAlphaNum(c) || (c) == '_')
#define IsAlphaWithDiacriticalMark(c)		(0xc0 <= c && c <= 0xff && c != 0xd7 && c != 0xf7)


@interface NSString (NSStringHelper)

- (BOOL)isEqualNoCase:(NSString*)other;
- (BOOL)isEmpty;

- (BOOL)contains:(NSString*)str;
- (BOOL)containsIgnoringCase:(NSString*)str;

- (BOOL)isAlphaNumOnly;
- (BOOL)isNumericOnly;

- (NSString*)encodeURIComponent;
- (NSString*)encodeURIFragment;

@end
