
#import "NSStringHelper.h"

#define LF	0xa
#define CR	0xd


@implementation NSString (NSStringHelper)

- (const UniChar*)getCharactersBuffer
{
	NSUInteger len = self.length;
	const UniChar* buffer = CFStringGetCharactersPtr((__bridge CFStringRef)self);
	if (!buffer) {
		NSMutableData* data = [NSMutableData dataWithLength:len * sizeof(UniChar)];
		if (!data) return NULL;
		[self getCharacters:[data mutableBytes]];
		buffer = [data bytes];
		if (!buffer) return NULL;
	}
	return buffer;
}

- (BOOL)isEqualNoCase:(NSString*)other
{
	return [self caseInsensitiveCompare:other] == NSOrderedSame;
}

- (BOOL)isEmpty
{
	return [self length] == 0;
}

- (BOOL)contains:(NSString*)str
{
	NSRange r = [self rangeOfString:str];
	return r.location != NSNotFound;
}

- (BOOL)containsIgnoringCase:(NSString*)str
{
	NSRange r = [self rangeOfString:str options:NSCaseInsensitiveSearch];
	return r.location != NSNotFound;
}

- (BOOL)isNumericOnly
{
	NSUInteger len = self.length;
	if (!len) return NO;
	
	const UniChar* buffer = [self getCharactersBuffer];
	if (!buffer) return NO;
	
	for (NSInteger i=0; i<len; ++i) {
		UniChar c = buffer[i];
		if (!(IsNumeric(c))) {
			return NO;
		}
	}
	return YES;
}

- (BOOL)isAlphaNumOnly
{
	NSUInteger len = self.length;
	if (!len) return NO;
	
	const UniChar* buffer = [self getCharactersBuffer];
	if (!buffer) return NO;
	
	for (NSInteger i=0; i<len; ++i) {
		UniChar c = buffer[i];
		if (!(IsAlphaNum(c))) {
			return NO;
		}
	}
	return YES;
}

- (NSString*)encodeURIComponent
{
	if (!self.length) return @"";
	
	static const char* characters = "0123456789ABCDEF";
	
	const char* src = [self UTF8String];
	if (!src) return @"";
	
	NSUInteger len = [self lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	char buf[len*4];
	char* dest = buf;
	
	for (NSInteger i=len-1; i>=0; --i) {
		unsigned char c = *src++;
		if (IsWordLetter(c) || c == '-' || c == '.' || c == '~') {
			*dest++ = c;
		}
		else {
			*dest++ = '%';
			*dest++ = characters[c / 16];
			*dest++ = characters[c % 16];
		}
	}
	
	return [[NSString alloc] initWithBytes:buf length:dest - buf encoding:NSASCIIStringEncoding];
}

- (NSString*)encodeURIFragment
{
	if (!self.length) return @"";
	
	static const char* characters = "0123456789ABCDEF";
	
	const char* src = [self UTF8String];
	if (!src) return @"";
	
	NSUInteger len = [self lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	char buf[len*4];
	char* dest = buf;
	
	for (NSInteger i=len-1; i>=0; --i) {
		unsigned char c = *src++;
		if (IsWordLetter(c)
			|| c == '#'
			|| c == '%'
			|| c == '&'
			|| c == '+'
			|| c == ','
			|| c == '-'
			|| c == '.'
			|| c == '/'
			|| c == ':'
			|| c == ';'
			|| c == '='
			|| c == '?'
			|| c == '@'
			|| c == '~') {
			*dest++ = c;
		}
		else {
			*dest++ = '%';
			*dest++ = characters[c / 16];
			*dest++ = characters[c % 16];
		}
	}
	
	return [[NSString alloc] initWithBytes:buf length:dest - buf encoding:NSASCIIStringEncoding];
}

@end
