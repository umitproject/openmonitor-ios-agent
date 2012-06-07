//
//  Crypto.m
//  iOSKuapay
//
//  Created by Patrick Hogan on 5/13/11.
//  Copyright 2011 Kuapay LLC. All rights reserved.
//

#import "Exception.h"
#import "Global.h"
#import <CommonCrypto/CommonDigest.h>  
#import <CommonCrypto/CommonCryptor.h>
#import <Security/Security.h>
#import "NSData+Base64.h"

#import "Crypto.h"


@interface Crypto ()

size_t encodeLength(unsigned char * buf, size_t length);

@end


static unsigned char oidSequence[] = { 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00 };

static NSString *x509PublicHeader = @"-----BEGIN PUBLIC KEY-----";
static NSString *x509PublicFooter = @"-----END PUBLIC KEY-----";
static NSString *pKCS1PublicHeader = @"-----BEGIN RSA PUBLIC KEY-----";
static NSString *pKCS1PublicFooter = @"-----END RSA PUBLIC KEY-----";
static NSString *pemPrivateHeader = @"-----BEGIN RSA PRIVATE KEY-----";
static NSString *pemPrivateFooter = @"-----END RSA PRIVATE KEY-----";


@implementation Crypto


#pragma mark - Encryption/Decryption Methods:
+(NSString *)decryptRSA:(NSString *)cipherString key:(NSString *)key
{
 NSString *privateKeyIdentifier = [NSString stringWithFormat:@"%@.privatekey",[[NSBundle mainBundle] bundleIdentifier]];
 
 [Crypto setPrivateKey:key tag:(NSString *)privateKeyIdentifier];
 
 size_t plainBufferSize;;
 uint8_t *plainBuffer;
 
 SecKeyRef privateKey = NULL;
 
 NSData *privateTag = [privateKeyIdentifier dataUsingEncoding:NSUTF8StringEncoding];
 
 NSMutableDictionary *queryPrivateKey = [[[NSMutableDictionary alloc] init] autorelease];
 [queryPrivateKey setObject:(id)kSecClassKey forKey:(id)kSecClass];
 [queryPrivateKey setObject:privateTag forKey:(id)kSecAttrApplicationTag];
 [queryPrivateKey setObject:(id)kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
 [queryPrivateKey setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecReturnRef];
 
 SecItemCopyMatching((CFDictionaryRef)queryPrivateKey, (CFTypeRef *)&privateKey);
 
 if (!privateKey)
 {
  if(privateKey) CFRelease(privateKey);

  [Exception raise:FAILURE function:__PRETTY_FUNCTION__ line:__LINE__ description:@"Could not decrypt.  Packet too large."];
 }

 plainBufferSize = SecKeyGetBlockSize(privateKey);
 plainBuffer = malloc(plainBufferSize);
 
 NSData *incomingData = [NSData dataFromBase64String:cipherString];
 uint8_t *cipherBuffer = (uint8_t*)[incomingData bytes];
 size_t cipherBufferSize = SecKeyGetBlockSize(privateKey);
 
 // Ordinarily, you would split the data up into blocks
 // equal to plainBufferSize, with the last block being
 // shorter. For simplicity, this example assumes that
 // the data is short enough to fit.
 if (plainBufferSize < cipherBufferSize)
 {   
  if(privateKey) CFRelease(privateKey);
  
  [Exception raise:FAILURE function:__PRETTY_FUNCTION__ line:__LINE__ description:@"Could not decrypt.  Packet too large."];
 }
 
 SecKeyDecrypt(privateKey, kSecPaddingPKCS1, cipherBuffer, cipherBufferSize, plainBuffer, &plainBufferSize); 
 
 NSData *decryptedData = [NSData dataWithBytes:plainBuffer length:plainBufferSize];
 NSString *decryptedString = [[[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding] autorelease];
 
 if(privateKey) CFRelease(privateKey);
 
 return decryptedString;
}


+(NSString *)encryptRSA:(NSString *)plainTextString key:(NSString *)key
{
 NSString *publicKeyIdentifier = [NSString stringWithFormat:@"%@.publickey",[[NSBundle mainBundle] bundleIdentifier]];

 [Crypto setPublicKey:key tag:(NSString *)publicKeyIdentifier];
 
 SecKeyRef publicKey = NULL;
 NSData * publicTag = [publicKeyIdentifier dataUsingEncoding:NSUTF8StringEncoding];
 NSMutableDictionary *queryPublicKey = [[[NSMutableDictionary alloc] init] autorelease];
 [queryPublicKey setObject:(id)kSecClassKey forKey:(id)kSecClass];
 [queryPublicKey setObject:publicTag forKey:(id)kSecAttrApplicationTag];
 [queryPublicKey setObject:(id)kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
 [queryPublicKey setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecReturnRef];
 
 SecItemCopyMatching((CFDictionaryRef)queryPublicKey, (CFTypeRef *)&publicKey);
 
 if (!publicKey)
 {
  if(publicKey) CFRelease(publicKey);

  [Exception raise:FAILURE function:__PRETTY_FUNCTION__ line:__LINE__ description:@"Could not decrypt."];
 }

 size_t cipherBufferSize = SecKeyGetBlockSize(publicKey);
 uint8_t *cipherBuffer = malloc(cipherBufferSize);
 
 DLog(@"Cipher buffer size: %lu",cipherBufferSize);
 
 uint8_t *nonce = (uint8_t *)[plainTextString UTF8String];
 
 // Ordinarily, you would split the data up into blocks
 // equal to cipherBufferSize, with the last block being
 // shorter. For simplicity, this example assumes that
 // the data is short enough to fit.
 if (cipherBufferSize < sizeof(nonce))
 {
  if(publicKey) CFRelease(publicKey);
  free(cipherBuffer);
  
  [Exception raise:FAILURE function:__PRETTY_FUNCTION__ line:__LINE__ description:@"Could not encrypt.  Packet too large."];
 }
 
 SecKeyEncrypt(publicKey, kSecPaddingPKCS1, nonce, strlen( (char*)nonce ) + 1, &cipherBuffer[0], &cipherBufferSize);
 
 NSData *encryptedData = [NSData dataWithBytes:cipherBuffer length:cipherBufferSize];
 
 DLog(@"Base 64 Encrypted String:\n%@",[encryptedData base64EncodedString]);
 
 if(publicKey) CFRelease(publicKey);
 free(cipherBuffer);
 
 return [encryptedData base64EncodedString];
}


#pragma mark - Public/Private Key Import Methods:
+(void)setPrivateKey:(NSString *)pemPrivateKeyString tag:(NSString *)tag
{
 NSData *privateTag = [tag dataUsingEncoding:NSUTF8StringEncoding];
 
 NSMutableDictionary *privateKey = [[[NSMutableDictionary alloc] init] autorelease];
 [privateKey setObject:(id) kSecClassKey forKey:(id)kSecClass];
 [privateKey setObject:(id) kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
 [privateKey setObject:privateTag forKey:(id)kSecAttrApplicationTag];
 SecItemDelete((CFDictionaryRef)privateKey);
 
 NSString *strippedKey = nil;
 if (([pemPrivateKeyString rangeOfString:pemPrivateHeader].location != NSNotFound) && ([pemPrivateKeyString rangeOfString:pemPrivateFooter].location != NSNotFound))
 {
  strippedKey = [[pemPrivateKeyString stringByReplacingOccurrencesOfString:pemPrivateHeader withString:@""] stringByReplacingOccurrencesOfString:pemPrivateFooter withString:@""];
  strippedKey = [[strippedKey stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""];
 }
 else
  [Exception raise:FAILURE function:__PRETTY_FUNCTION__ line:__LINE__ description:@"Could not set private key."];
 
 NSData *strippedPrivateKeyData = [NSData dataFromBase64String:strippedKey];
 
 DLog(@"Stripped Private Key Base 64:\n%@",strippedKey);
 
 CFTypeRef persistKey = nil;
 [privateKey setObject:strippedPrivateKeyData forKey:(id)kSecValueData];
 [privateKey setObject:(id) kSecAttrKeyClassPrivate forKey:(id)kSecAttrKeyClass];
 [privateKey setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecReturnPersistentRef];
 
 OSStatus secStatus = SecItemAdd((CFDictionaryRef)privateKey, &persistKey);
 
 if (persistKey != nil) CFRelease(persistKey);
 
 if ((secStatus != noErr) && (secStatus != errSecDuplicateItem))
  [Exception raise:FAILURE function:__PRETTY_FUNCTION__ line:__LINE__ description:@"Could not set private key."];
 
 SecKeyRef keyRef = nil;
 [privateKey removeObjectForKey:(id)kSecValueData];
 [privateKey removeObjectForKey:(id)kSecReturnPersistentRef];
 [privateKey setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecReturnRef];
 [privateKey setObject:(id) kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
 
 SecItemCopyMatching((CFDictionaryRef)privateKey,(CFTypeRef *)&keyRef);
  
 if (!keyRef)
  [Exception raise:FAILURE function:__PRETTY_FUNCTION__ line:__LINE__ description:@"Could not set private key."]; 
 
 if (keyRef) CFRelease(keyRef);
}


+(void)setPublicKey:(NSString *)pemPublicKeyString tag:(NSString *)tag
{
 NSData *publicTag = [tag dataUsingEncoding:NSUTF8StringEncoding];
 
 NSMutableDictionary *publicKey = [[[NSMutableDictionary alloc] init] autorelease];
 [publicKey setObject:(id) kSecClassKey forKey:(id)kSecClass];
 [publicKey setObject:(id) kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
 [publicKey setObject:publicTag forKey:(id)kSecAttrApplicationTag];
 SecItemDelete((CFDictionaryRef)publicKey);
 
 BOOL isX509 = NO;
 
 NSString *strippedKey = nil;
 if (([pemPublicKeyString rangeOfString:x509PublicHeader].location != NSNotFound) && ([pemPublicKeyString rangeOfString:x509PublicFooter].location != NSNotFound))
 {
  strippedKey = [[pemPublicKeyString stringByReplacingOccurrencesOfString:x509PublicHeader withString:@""] stringByReplacingOccurrencesOfString:x509PublicFooter withString:@""];
  strippedKey = [[strippedKey stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""];
  
  isX509 = YES;
 }
 else if (([pemPublicKeyString rangeOfString:pKCS1PublicHeader].location != NSNotFound) && ([pemPublicKeyString rangeOfString:pKCS1PublicFooter].location != NSNotFound))
 {
  strippedKey = [[pemPublicKeyString stringByReplacingOccurrencesOfString:pKCS1PublicHeader withString:@""] stringByReplacingOccurrencesOfString:pKCS1PublicFooter withString:@""];
  strippedKey = [[strippedKey stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""];
  
  isX509 = NO;
 }
 else
  [Exception raise:FAILURE function:__PRETTY_FUNCTION__ line:__LINE__ description:@"Could not set public key."]; 
 
 NSData *strippedPublicKeyData = [NSData dataFromBase64String:strippedKey];
 
 if (isX509)
 {
  unsigned char * bytes = (unsigned char *)[strippedPublicKeyData bytes];
  size_t bytesLen = [strippedPublicKeyData length];
  
  size_t i = 0;
  if (bytes[i++] != 0x30)
   [Exception raise:FAILURE function:__PRETTY_FUNCTION__ line:__LINE__ description:@"Could not set public key."]; 
  
  /* Skip size bytes */
  if (bytes[i] > 0x80)
   i += bytes[i] - 0x80 + 1;
  else
   i++;
  
  if (i >= bytesLen)
   [Exception raise:FAILURE function:__PRETTY_FUNCTION__ line:__LINE__ description:@"Could not set public key."]; 
  
  if (bytes[i] != 0x30)
   [Exception raise:FAILURE function:__PRETTY_FUNCTION__ line:__LINE__ description:@"Could not set public key."]; 
  
  /* Skip OID */
  i += 15;
  
  if (i >= bytesLen - 2)
   [Exception raise:FAILURE function:__PRETTY_FUNCTION__ line:__LINE__ description:@"Could not set public key."]; 
  
  if (bytes[i++] != 0x03)
   [Exception raise:FAILURE function:__PRETTY_FUNCTION__ line:__LINE__ description:@"Could not set public key."]; 
  
  /* Skip length and null */
  if (bytes[i] > 0x80)
   i += bytes[i] - 0x80 + 1;
  else
   i++;
  
  if (i >= bytesLen)
   [Exception raise:FAILURE function:__PRETTY_FUNCTION__ line:__LINE__ description:@"Could not set public key."]; 
  
  if (bytes[i++] != 0x00)
   [Exception raise:FAILURE function:__PRETTY_FUNCTION__ line:__LINE__ description:@"Could not set public key."]; 
  
  if (i >= bytesLen)
   [Exception raise:FAILURE function:__PRETTY_FUNCTION__ line:__LINE__ description:@"Could not set public key."]; 
  
  strippedPublicKeyData = [NSData dataWithBytes:&bytes[i] length:bytesLen - i];
 }
 
 DLog(@"X.509 Formatted Public Key bytes:\n%@",[strippedPublicKeyData description]);
 
 if (strippedPublicKeyData == nil)
  [Exception raise:FAILURE function:__PRETTY_FUNCTION__ line:__LINE__ description:@"Could not set public key."]; 
 
 DLog(@"Stripped Public Key Bytes:\n%@",[strippedPublicKeyData description]);
 
 CFTypeRef persistKey = nil;
 [publicKey setObject:strippedPublicKeyData forKey:(id)kSecValueData];
 [publicKey setObject:(id) kSecAttrKeyClassPublic forKey:(id)kSecAttrKeyClass];
 [publicKey setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecReturnPersistentRef];
 
 OSStatus secStatus = SecItemAdd((CFDictionaryRef)publicKey, &persistKey);
 
 if (persistKey != nil) CFRelease(persistKey);
 
 if ((secStatus != noErr) && (secStatus != errSecDuplicateItem))
  [Exception raise:FAILURE function:__PRETTY_FUNCTION__ line:__LINE__ description:@"Could not set public key."]; 
 
 SecKeyRef keyRef = nil;
 [publicKey removeObjectForKey:(id)kSecValueData];
 [publicKey removeObjectForKey:(id)kSecReturnPersistentRef];
 [publicKey setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecReturnRef];
 [publicKey setObject:(id) kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
 
 SecItemCopyMatching((CFDictionaryRef)publicKey,(CFTypeRef *)&keyRef);
  
 if (!keyRef)
  [Exception raise:FAILURE function:__PRETTY_FUNCTION__ line:__LINE__ description:@"Could not set public key."]; 

 if (keyRef) CFRelease(keyRef);
}


+(void)removeKey:(NSString *)tag
{
 NSData *keyTag = [tag dataUsingEncoding:NSUTF8StringEncoding];
 
 NSMutableDictionary *privateKey = [[[NSMutableDictionary alloc] init] autorelease];
 [privateKey setObject:(id) kSecClassKey forKey:(id)kSecClass];
 [privateKey setObject:(id) kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
 [privateKey setObject:keyTag forKey:(id)kSecAttrApplicationTag];
 OSStatus secStatus = SecItemDelete((CFDictionaryRef)privateKey);
 
 if ((secStatus != noErr) && (secStatus != errSecDuplicateItem))
  [Exception raise:FAILURE function:__PRETTY_FUNCTION__ line:__LINE__ description:@"Could not remove key."]; 
}


#pragma mark - Key pair generation method:
+(void)generateKeyPairWithPublicTag:(NSString *)publicTagString privateTag:(NSString *)privateTagString
{
 NSMutableDictionary *privateKeyAttr = [[NSMutableDictionary alloc] init];
 NSMutableDictionary *publicKeyAttr = [[NSMutableDictionary alloc] init];
 NSMutableDictionary *keyPairAttr = [[NSMutableDictionary alloc] init];
 
 NSData *publicTag = [publicTagString dataUsingEncoding:NSUTF8StringEncoding];
 NSData *privateTag = [privateTagString dataUsingEncoding:NSUTF8StringEncoding];
 
 NSMutableDictionary *privateKeyDictionary = [[NSMutableDictionary alloc] init];
 [privateKeyDictionary setObject:(id) kSecClassKey forKey:(id)kSecClass];
 [privateKeyDictionary setObject:(id) kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
 [privateKeyDictionary setObject:privateTag forKey:(id)kSecAttrApplicationTag];
 SecItemDelete((CFDictionaryRef)privateKeyDictionary);
 
 NSMutableDictionary *publicKeyDictionary = [[NSMutableDictionary alloc] init];
 [publicKeyDictionary setObject:(id) kSecClassKey forKey:(id)kSecClass];
 [publicKeyDictionary setObject:(id) kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
 [publicKeyDictionary setObject:publicTag forKey:(id)kSecAttrApplicationTag];
 SecItemDelete((CFDictionaryRef)publicKeyDictionary);
 
 [privateKeyDictionary release];
 [publicKeyDictionary release];
 
 SecKeyRef publicKey = NULL;
 SecKeyRef privateKey = NULL;
 
 [keyPairAttr setObject:(id)kSecAttrKeyTypeRSA
                 forKey:(id)kSecAttrKeyType];
 [keyPairAttr setObject:[NSNumber numberWithInt:1024]
                 forKey:(id)kSecAttrKeySizeInBits];
 
 
 [privateKeyAttr setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecAttrIsPermanent];
 [privateKeyAttr setObject:privateTag forKey:(id)kSecAttrApplicationTag];
 
 [publicKeyAttr setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecAttrIsPermanent];
 [publicKeyAttr setObject:publicTag forKey:(id)kSecAttrApplicationTag];
 
 [keyPairAttr setObject:privateKeyAttr forKey:(id)kSecPrivateKeyAttrs];
 [keyPairAttr setObject:publicKeyAttr forKey:(id)kSecPublicKeyAttrs];
 
 OSStatus err = SecKeyGeneratePair((CFDictionaryRef)keyPairAttr, &publicKey, &privateKey);
 
 if (err != noErr)
  [Exception raise:FAILURE function:__PRETTY_FUNCTION__ line:__LINE__ description:@"Could not generate key pair."]; 

 if(privateKeyAttr) [privateKeyAttr release];
 if(publicKeyAttr) [publicKeyAttr release];
 if(keyPairAttr) [keyPairAttr release];
 if(publicKey) CFRelease(publicKey);
 if(privateKey) CFRelease(privateKey);
}


+(NSString *)getPEMFormattedPrivateKey:(NSString *)tag
{ 
 NSData *privateTag = [tag dataUsingEncoding:NSUTF8StringEncoding];
 
 NSMutableDictionary * queryPrivateKey = [[[NSMutableDictionary alloc] init] autorelease];
 [queryPrivateKey setObject:(id)kSecClassKey forKey:(id)kSecClass];
 [queryPrivateKey setObject:privateTag forKey:(id)kSecAttrApplicationTag];
 [queryPrivateKey setObject:(id)kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
 [queryPrivateKey setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecReturnData];
 
 NSData * privateKeyBits;
 OSStatus err = SecItemCopyMatching((CFDictionaryRef)queryPrivateKey,(CFTypeRef *)&privateKeyBits);
 
 if (err != noErr)
  [Exception raise:FAILURE function:__PRETTY_FUNCTION__ line:__LINE__ description:@"Could not get private key.  Tag may be bad."]; 
 
 NSMutableData * encKey = [[NSMutableData alloc] init];
 
 DLog(@"Private Key Bits:\n%@",[[NSData dataWithBytes:privateKeyBits length:[privateKeyBits length]] description]);
 
 [encKey appendData:privateKeyBits];
 [privateKeyBits release];
 
 NSString *returnString = [NSString stringWithFormat:@"%@\n",pemPrivateHeader];
 returnString = [returnString stringByAppendingString:[encKey base64EncodedString]];
 returnString = [returnString stringByAppendingFormat:@"\n%@",pemPrivateFooter];
 
 DLog(@"PEM formatted key:\n%@",returnString);
 
 [encKey release];
 return returnString;
}


+(NSString *)getX509FormattedPublicKey:(NSString *)tag
{ 
 NSData *publicTag = [tag dataUsingEncoding:NSUTF8StringEncoding];
 
 NSMutableDictionary * queryPublicKey = [[[NSMutableDictionary alloc] init] autorelease];
 [queryPublicKey setObject:(id)kSecClassKey forKey:(id)kSecClass];
 [queryPublicKey setObject:publicTag forKey:(id)kSecAttrApplicationTag];
 [queryPublicKey setObject:(id)kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
 [queryPublicKey setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecReturnData];
 
 NSData * publicKeyBits;
 OSStatus err = SecItemCopyMatching((CFDictionaryRef)queryPublicKey,(CFTypeRef *)&publicKeyBits);
   
 if (err != noErr)
  [Exception raise:FAILURE function:__PRETTY_FUNCTION__ line:__LINE__ description:@"Could get public key."]; 
 
 unsigned char builder[15];
 NSMutableData *encKey = [[NSMutableData alloc] init];
 int bitstringEncLength;
 if  ([publicKeyBits length ] + 1  < 128 )
  bitstringEncLength = 1 ;
 else
  bitstringEncLength = (([publicKeyBits length ] +1 ) / 256) + 2 ; 
 
 builder[0] = 0x30;
 size_t i = sizeof(oidSequence) + 2 + bitstringEncLength + [publicKeyBits length];
 size_t j = encodeLength(&builder[1], i);
 [encKey appendBytes:builder length:j +1];
 
 [encKey appendBytes:oidSequence length:sizeof(oidSequence)];
 
 builder[0] = 0x03;
 j = encodeLength(&builder[1], [publicKeyBits length] + 1);
 builder[j+1] = 0x00;
 [encKey appendBytes:builder length:j + 2];
 [encKey appendData:publicKeyBits];

 NSString *returnString = [NSString stringWithFormat:@"%@\n%@\n%@", x509PublicHeader, [encKey base64EncodedString], x509PublicFooter];
 DLog(@"PEM formatted key:\n%@",returnString);

 [encKey release];
 [publicKeyBits release];
   
 return returnString;
}


#pragma mark - Public Key Import/Export convenience method
size_t encodeLength(unsigned char * buf, size_t length)
{ 
 if (length < 128)
 {
  buf[0] = length;
  return 1;
 }
 
 size_t i = (length / 256) + 1;
 buf[0] = i + 0x80;
 for (size_t j = 0 ; j < i; ++j)
 {        
  buf[i - j] = length & 0xFF;  
  length = length >> 8;
 }
 
 return i + 1;
}


@end
