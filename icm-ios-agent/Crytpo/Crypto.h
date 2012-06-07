//
//  Crypto.h
//  iOSKuapay
//
//  Created by Patrick Hogan on 5/13/11.
//  Copyright 2011 Kuapay LLC. All rights reserved.
//


@interface Crypto : NSObject

+(NSString *)encryptRSA:(NSString *)plainTextString key:(NSString *)key;
+(NSString *)decryptRSA:(NSString *)cipherString key:(NSString *)key;

+(void)generateKeyPairWithPublicTag:(NSString *)publicTagString privateTag:(NSString *)privateTagString;
+(void)setPrivateKey:(NSString *)pemPrivateKeyString tag:(NSString *)tag;
+(void)setPublicKey:(NSString *)pemPublicKeyString tag:(NSString *)tag;
+(void)removeKey:(NSString *)tag;

+(NSString *)getX509FormattedPublicKey:(NSString *)tag;
+(NSString *)getPEMFormattedPrivateKey:(NSString *)tag;

@end
