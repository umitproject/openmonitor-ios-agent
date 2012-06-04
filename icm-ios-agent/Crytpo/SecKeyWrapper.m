/*
 
 File: SecKeyWrapper.m
 Abstract: Core cryptographic wrapper class to exercise most of the Security 
 APIs on the iPhone OS. Start here if all you are interested in are the 
 cryptographic APIs on the iPhone OS.
 
 Version: 1.2
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc.
 ("Apple") in consideration of your agreement to the following terms, and your
 use, installation, modification or redistribution of this Apple software
 constitutes acceptance of these terms.  If you do not agree with these terms,
 please do not use, install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject
 to these terms, Apple grants you a personal, non-exclusive license, under
 Apple's copyrights in this original Apple software (the "Apple Software"), to
 use, reproduce, modify and redistribute the Apple Software, with or without
 modifications, in source and/or binary forms; provided that if you redistribute
 the Apple Software in its entirety and without modifications, you must retain
 this notice and the following text and disclaimers in all such redistributions
 of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may be used
 to endorse or promote products derived from the Apple Software without specific
 prior written permission from Apple.  Except as expressly stated in this notice,
 no other rights or licenses, express or implied, are granted by Apple herein,
 including but not limited to any patent rights that may be infringed by your
 derivative works or by other works in which the Apple Software may be
 incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
 WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
 WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
 COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR
 DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF
 CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF
 APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2008-2009 Apple Inc. All Rights Reserved.
 
 */

#import "SecKeyWrapper.h"
#import <Security/Security.h>

@implementation SecKeyWrapper

@synthesize symmetricKeyRef;

#if DEBUG
	#define LOGGING_FACILITY(X, Y)	\
					NSAssert(X, Y);	

	#define LOGGING_FACILITY1(X, Y, Z)	\
					NSAssert1(X, Y, Z);	
#else
	#define LOGGING_FACILITY(X, Y)	\
				if (!(X)) {			\
					NSLog(Y);		\
				}					

	#define LOGGING_FACILITY1(X, Y, Z)	\
				if (!(X)) {				\
					NSLog(Y, Z);		\
				}						
#endif

// (See cssmtype.h and cssmapple.h on the Mac OS X SDK.)

enum {
	CSSM_ALGID_NONE =					0x00000000L,
	CSSM_ALGID_VENDOR_DEFINED =			CSSM_ALGID_NONE + 0x80000000L,
	CSSM_ALGID_AES
};

static SecKeyWrapper * __sharedKeyWrapper = nil;

/* Begin method definitions */

+ (SecKeyWrapper *)sharedWrapper {
    @synchronized(self) {
        if (__sharedKeyWrapper == nil) {
            __sharedKeyWrapper = [[self alloc] init];
        }
    }
    return __sharedKeyWrapper;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (__sharedKeyWrapper == nil) {
            __sharedKeyWrapper = [super allocWithZone:zone];
            return __sharedKeyWrapper;
        }
    }
    return nil;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

-(id)init {
	 if (self = [super init])
	 {
		 // Tag data to search for keys.
	 }
	
	return self;
}

- (void)deleteAsymmetricKeys {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kPublicKeyTag];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kPrivateKeyTag];
}

- (void)deleteSymmetricKey {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:kSymmetricKeyTag];
}

- (void)generateKeyPair:(NSUInteger)keySize {
	OSStatus sanityCheck = noErr;
	publicKeyRef = NULL;
	privateKeyRef = NULL;
	
	LOGGING_FACILITY1( keySize == 512 || keySize == 1024 || keySize == 2048, @"%d is an invalid and unsupported key size.", keySize );
	
	// First delete current keys.
	[self deleteAsymmetricKeys];
	
	// Container dictionaries.
	NSMutableDictionary * privateKeyAttr = [[NSMutableDictionary alloc] init];
	NSMutableDictionary * publicKeyAttr = [[NSMutableDictionary alloc] init];
	NSMutableDictionary * keyPairAttr = [[NSMutableDictionary alloc] init];
	
	// Set top level dictionary for the keypair.
	[keyPairAttr setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
	[keyPairAttr setObject:[NSNumber numberWithUnsignedInteger:keySize] forKey:(__bridge id)kSecAttrKeySizeInBits];
	
	// Set the private key dictionary.
	[privateKeyAttr setObject:[NSNumber numberWithBool:NO] forKey:(__bridge id)kSecAttrIsPermanent];
	// See SecKey.h to set other flag values.
	
	// Set the public key dictionary.
	[publicKeyAttr setObject:[NSNumber numberWithBool:NO] forKey:(__bridge id)kSecAttrIsPermanent];
	// See SecKey.h to set other flag values.
	
	// Set attributes to top level dictionary.
	[keyPairAttr setObject:privateKeyAttr forKey:(__bridge id)kSecPrivateKeyAttrs];
	[keyPairAttr setObject:publicKeyAttr forKey:(__bridge id)kSecPublicKeyAttrs];
	
	// SecKeyGeneratePair returns the SecKeyRefs just for educational purposes.
	sanityCheck = SecKeyGeneratePair((__bridge CFDictionaryRef)keyPairAttr, &publicKeyRef, &privateKeyRef);
	LOGGING_FACILITY( sanityCheck == noErr && publicKeyRef != NULL && privateKeyRef != NULL, @"Something really bad went wrong with generating the key pair." );
}

- (void)generateSymmetricKey {
	OSStatus sanityCheck = noErr;
	uint8_t * symmetricKey = NULL;
	
	// First delete current symmetric key.
	[self deleteSymmetricKey];
	
	// Container dictionary
	NSMutableDictionary *symmetricKeyAttr = [[NSMutableDictionary alloc] init];
	[symmetricKeyAttr setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
	[symmetricKeyAttr setObject:[NSNumber numberWithUnsignedInt:CSSM_ALGID_AES] forKey:(__bridge id)kSecAttrKeyType];
	[symmetricKeyAttr setObject:[NSNumber numberWithUnsignedInt:(unsigned int)(kChosenCipherKeySize << 3)] forKey:(__bridge id)kSecAttrKeySizeInBits];
	[symmetricKeyAttr setObject:[NSNumber numberWithUnsignedInt:(unsigned int)(kChosenCipherKeySize << 3)]	forKey:(__bridge id)kSecAttrEffectiveKeySize];
	[symmetricKeyAttr setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecAttrCanEncrypt];
	[symmetricKeyAttr setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecAttrCanDecrypt];
	[symmetricKeyAttr setObject:(id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanDerive];
	[symmetricKeyAttr setObject:(id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanSign];
	[symmetricKeyAttr setObject:(id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanVerify];
	[symmetricKeyAttr setObject:(id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanWrap];
	[symmetricKeyAttr setObject:(id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanUnwrap];
    [symmetricKeyAttr setObject:(id)kCFBooleanFalse forKey:(__bridge id)kSecAttrIsPermanent];
	
	// Allocate some buffer space. I don't trust calloc.
	symmetricKey = malloc( kChosenCipherKeySize * sizeof(uint8_t) );
	
	LOGGING_FACILITY( symmetricKey != NULL, @"Problem allocating buffer space for symmetric key generation." );
	
	memset((void *)symmetricKey, 0x0, kChosenCipherKeySize);
	
	sanityCheck = SecRandomCopyBytes(kSecRandomDefault, kChosenCipherKeySize, symmetricKey);
	LOGGING_FACILITY1( sanityCheck == noErr, @"Problem generating the symmetric key, OSStatus == %d.", sanityCheck );
	
	self.symmetricKeyRef = [[NSData alloc] initWithBytes:(const void *)symmetricKey length:kChosenCipherKeySize];
	
	// Add the wrapped key data to the container dictionary.
	[symmetricKeyAttr setObject:self.symmetricKeyRef
					  forKey:(__bridge id)kSecValueData];
	
	// Add the symmetric key to the keychain.
	sanityCheck = SecItemAdd((__bridge CFDictionaryRef) symmetricKeyAttr, NULL);
	LOGGING_FACILITY1( sanityCheck == noErr || sanityCheck == errSecDuplicateItem, @"Problem storing the symmetric key in the keychain, OSStatus == %d.", sanityCheck );
	
	if (symmetricKey) free(symmetricKey);
}

- (SecKeyRef)addPeerPublicKey:(NSString *)peerName keyBits:(NSData *)publicKey {
	return nil;
}

- (void)removePeerPublicKey:(NSString *)peerName {
	
}

- (NSData *)wrapSymmetricKey:(NSData *)symmetricKey keyRef:(SecKeyRef)publicKey {
	OSStatus sanityCheck = noErr;
	size_t cipherBufferSize = 0;
	size_t keyBufferSize = 0;
	
	LOGGING_FACILITY( symmetricKey != nil, @"Symmetric key parameter is nil." );
	LOGGING_FACILITY( publicKey != nil, @"Key parameter is nil." );
	
	NSData * cipher = nil;
	uint8_t * cipherBuffer = NULL;
	
	// Calculate the buffer sizes.
	cipherBufferSize = SecKeyGetBlockSize(publicKey);
	keyBufferSize = [symmetricKey length];
	
	if (kTypeOfWrapPadding == kSecPaddingNone) {
		LOGGING_FACILITY( keyBufferSize <= cipherBufferSize, @"Nonce integer is too large and falls outside multiplicative group." );
	} else {
		LOGGING_FACILITY( keyBufferSize <= (cipherBufferSize - 11), @"Nonce integer is too large and falls outside multiplicative group." );
	}
	
	// Allocate some buffer space. I don't trust calloc.
	cipherBuffer = malloc( cipherBufferSize * sizeof(uint8_t) );
	memset((void *)cipherBuffer, 0x0, cipherBufferSize);
	
	// Encrypt using the public key.
	sanityCheck = SecKeyEncrypt(	publicKey,
									kTypeOfWrapPadding,
									(const uint8_t *)[symmetricKey bytes],
									keyBufferSize,
									cipherBuffer,
									&cipherBufferSize
								);
	
	LOGGING_FACILITY1( sanityCheck == noErr, @"Error encrypting, OSStatus == %d.", sanityCheck );
	
	// Build up cipher text blob.
	cipher = [NSData dataWithBytes:(const void *)cipherBuffer length:(NSUInteger)cipherBufferSize];
	
	if (cipherBuffer) free(cipherBuffer);
	
	return cipher;
}

- (NSData *)unwrapSymmetricKey:(NSData *)wrappedSymmetricKey {
	OSStatus sanityCheck = noErr;
	size_t cipherBufferSize = 0;
	size_t keyBufferSize = 0;
	
	NSData * key = nil;
	uint8_t * keyBuffer = NULL;
	
	SecKeyRef privateKey = NULL;
	
	privateKey = [self getPrivateKeyRef];
	LOGGING_FACILITY( privateKey != NULL, @"No private key found in the keychain." );
	
	// Calculate the buffer sizes.
	cipherBufferSize = SecKeyGetBlockSize(privateKey);
	keyBufferSize = [wrappedSymmetricKey length];
	
	LOGGING_FACILITY( keyBufferSize <= cipherBufferSize, @"Encrypted nonce is too large and falls outside multiplicative group." );
	
	// Allocate some buffer space. I don't trust calloc.
	keyBuffer = malloc( keyBufferSize * sizeof(uint8_t) );
	memset((void *)keyBuffer, 0x0, keyBufferSize);
	
	// Decrypt using the private key.
	sanityCheck = SecKeyDecrypt(	privateKey,
									kTypeOfWrapPadding,
									(const uint8_t *) [wrappedSymmetricKey bytes],
									cipherBufferSize,
									keyBuffer,
									&keyBufferSize
								);
	
	LOGGING_FACILITY1( sanityCheck == noErr, @"Error decrypting, OSStatus == %d.", sanityCheck );
	
	// Build up plain text blob.
	key = [NSData dataWithBytes:(const void *)keyBuffer length:(NSUInteger)keyBufferSize];
	
	if (keyBuffer) free(keyBuffer);
	
	return key;
}

- (NSData *)getHashBytes:(NSData *)plainText {
	CC_SHA1_CTX ctx;
	uint8_t * hashBytes = NULL;
	NSData * hash = nil;
	
	// Malloc a buffer to hold hash.
	hashBytes = malloc( kChosenDigestLength * sizeof(uint8_t) );
	memset((void *)hashBytes, 0x0, kChosenDigestLength);
	
	// Initialize the context.
	CC_SHA1_Init(&ctx);
	// Perform the hash.
	CC_SHA1_Update(&ctx, (void *)[plainText bytes], [plainText length]);
	// Finalize the output.
	CC_SHA1_Final(hashBytes, &ctx);
	
	// Build up the SHA1 blob.
	hash = [NSData dataWithBytes:(const void *)hashBytes length:(NSUInteger)kChosenDigestLength];
	
	if (hashBytes) free(hashBytes);
	
	return hash;
}

- (NSData *)getSignatureBytes:(NSData *)plainText {
	OSStatus sanityCheck = noErr;
	NSData * signedHash = nil;
	
	uint8_t * signedHashBytes = NULL;
	size_t signedHashBytesSize = 0;
	
	SecKeyRef privateKey = NULL;
	
	privateKey = [self getPrivateKeyRef];
	signedHashBytesSize = SecKeyGetBlockSize(privateKey);
	
	// Malloc a buffer to hold signature.
	signedHashBytes = malloc( signedHashBytesSize * sizeof(uint8_t) );
	memset((void *)signedHashBytes, 0x0, signedHashBytesSize);
	
	// Sign the SHA1 hash.
	sanityCheck = SecKeyRawSign(	privateKey, 
									kTypeOfSigPadding, 
									(const uint8_t *)[[self getHashBytes:plainText] bytes], 
									kChosenDigestLength, 
									(uint8_t *)signedHashBytes, 
									&signedHashBytesSize
								);
	
	LOGGING_FACILITY1( sanityCheck == noErr, @"Problem signing the SHA1 hash, OSStatus == %d.", sanityCheck );
	
	// Build up signed SHA1 blob.
	signedHash = [NSData dataWithBytes:(const void *)signedHashBytes length:(NSUInteger)signedHashBytesSize];
	
	if (signedHashBytes) free(signedHashBytes);
	
	return signedHash;
}

- (BOOL)verifySignature:(NSData *)plainText secKeyRef:(SecKeyRef)publicKey signature:(NSData *)sig {
	size_t signedHashBytesSize = 0;
	OSStatus sanityCheck = noErr;
	
	// Get the size of the assymetric block.
	signedHashBytesSize = SecKeyGetBlockSize(publicKey);
	
	sanityCheck = SecKeyRawVerify(	publicKey, 
									kTypeOfSigPadding, 
									(const uint8_t *)[[self getHashBytes:plainText] bytes],
									kChosenDigestLength, 
									(const uint8_t *)[sig bytes],
									signedHashBytesSize
								  );
	
	return (sanityCheck == noErr) ? YES : NO;
}

- (NSData *)doCipher:(NSData *)plainText key:(NSData *)symmetricKey context:(CCOperation)encryptOrDecrypt padding:(CCOptions *)pkcs7 {
	CCCryptorStatus ccStatus = kCCSuccess;
	// Symmetric crypto reference.
	CCCryptorRef thisEncipher = NULL;
	// Cipher Text container.
	NSData * cipherOrPlainText = nil;
	// Pointer to output buffer.
	uint8_t * bufferPtr = NULL;
	// Total size of the buffer.
	size_t bufferPtrSize = 0;
	// Remaining bytes to be performed on.
	size_t remainingBytes = 0;
	// Number of bytes moved to buffer.
	size_t movedBytes = 0;
	// Length of plainText buffer.
	size_t plainTextBufferSize = 0;
	// Placeholder for total written.
	size_t totalBytesWritten = 0;
	// A friendly helper pointer.
	uint8_t * ptr;
	
	// Initialization vector; dummy in this case 0's.
	uint8_t iv[kChosenCipherBlockSize];
	memset((void *) iv, 0x0, (size_t) sizeof(iv));
	
	LOGGING_FACILITY(plainText != nil, @"PlainText object cannot be nil." );
	LOGGING_FACILITY(symmetricKey != nil, @"Symmetric key object cannot be nil." );
	LOGGING_FACILITY(pkcs7 != NULL, @"CCOptions * pkcs7 cannot be NULL." );
	LOGGING_FACILITY([symmetricKey length] == kChosenCipherKeySize, @"Disjoint choices for key size." );
			 
	plainTextBufferSize = [plainText length];
	
	LOGGING_FACILITY(plainTextBufferSize > 0, @"Empty plaintext passed in." );
	
	// We don't want to toss padding on if we don't need to
	if (encryptOrDecrypt == kCCEncrypt) {
		if (*pkcs7 != kCCOptionECBMode) {
			if ((plainTextBufferSize % kChosenCipherBlockSize) == 0) {
				*pkcs7 = 0x0000;
			} else {
				*pkcs7 = kCCOptionPKCS7Padding;
			}
		}
	} else if (encryptOrDecrypt != kCCDecrypt) {
		LOGGING_FACILITY1( 0, @"Invalid CCOperation parameter [%d] for cipher context.", *pkcs7 );
	} 
	
	// Create and Initialize the crypto reference.
	ccStatus = CCCryptorCreate(	encryptOrDecrypt, 
								kCCAlgorithmAES128, 
								*pkcs7, 
								(const void *)[symmetricKey bytes], 
								kChosenCipherKeySize, 
								(const void *)iv, 
								&thisEncipher
							);
	
	LOGGING_FACILITY1( ccStatus == kCCSuccess, @"Problem creating the context, ccStatus == %d.", ccStatus );
	
	// Calculate byte block alignment for all calls through to and including final.
	bufferPtrSize = CCCryptorGetOutputLength(thisEncipher, plainTextBufferSize, true);
	
	// Allocate buffer.
	bufferPtr = malloc( bufferPtrSize * sizeof(uint8_t) );
	
	// Zero out buffer.
	memset((void *)bufferPtr, 0x0, bufferPtrSize);
	
	// Initialize some necessary book keeping.
	
	ptr = bufferPtr;
	
	// Set up initial size.
	remainingBytes = bufferPtrSize;
	
	// Actually perform the encryption or decryption.
	ccStatus = CCCryptorUpdate( thisEncipher,
								(const void *) [plainText bytes],
								plainTextBufferSize,
								ptr,
								remainingBytes,
								&movedBytes
							);
	
	LOGGING_FACILITY1( ccStatus == kCCSuccess, @"Problem with CCCryptorUpdate, ccStatus == %d.", ccStatus );
	
	// Handle book keeping.
	ptr += movedBytes;
	remainingBytes -= movedBytes;
	totalBytesWritten += movedBytes;
	
	// Finalize everything to the output buffer.
	ccStatus = CCCryptorFinal(	thisEncipher,
								ptr,
								remainingBytes,
								&movedBytes
							);
	
	totalBytesWritten += movedBytes;
	
	if (thisEncipher) {
		(void) CCCryptorRelease(thisEncipher);
		thisEncipher = NULL;
	}
	
	LOGGING_FACILITY1( ccStatus == kCCSuccess, @"Problem with encipherment ccStatus == %d", ccStatus );
	
	cipherOrPlainText = [NSData dataWithBytes:(const void *)bufferPtr length:(NSUInteger)totalBytesWritten];

	if (bufferPtr) free(bufferPtr);
	
	return cipherOrPlainText;
	
	/*
	 Or the corresponding one-shot call:
	 
	 ccStatus = CCCrypt(	encryptOrDecrypt,
							kCCAlgorithmAES128,
							typeOfSymmetricOpts,
							(const void *)[self getSymmetricKeyBytes],
							kChosenCipherKeySize,
							iv,
							(const void *) [plainText bytes],
							plainTextBufferSize,
							(void *)bufferPtr,
							bufferPtrSize,
							&movedBytes
						);
	 */
}

- (SecKeyRef)getPublicKeyRef {
	return nil;
}

- (NSData *)getPublicKeyBits {
    id pubkey = [[NSUserDefaults standardUserDefaults] objectForKey:kPublicKeyTag];
	return pubkey;
}

- (SecKeyRef)getPrivateKeyRef {
	return nil;
}

- (NSData *)getSymmetricKeyBytes {
	id pubkey = [[NSUserDefaults standardUserDefaults] objectForKey:kSymmetricKeyTag];
	return pubkey;
}

- (CFTypeRef)getPersistentKeyRefWithKeyRef:(SecKeyRef)keyRef {
	return nil;
}

- (SecKeyRef)getKeyRefWithPersistentKeyRef:(CFTypeRef)persistentRef {
	return nil;
}

@end
