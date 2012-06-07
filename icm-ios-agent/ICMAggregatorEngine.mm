//
//  ICMAggregatorEngine.m
//  icm-ios-agent
//
//  Created by shinysky on 12-5-24.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "ICMAggregatorEngine.h"
#import "SecKeyWrapper.h"
#import "CryptoCommon.h"

#include "messages.pb.h"
#include "Base64Transcoder.h"

@implementation ICMAggregatorEngine

#pragma mark -
#pragma mark REST API methods
#pragma mark -

#pragma mark Login methods

- (NSString *)registerAgent
{
	//return [self _sendRequestWithMethod:nil path:AGGR_REGISTER_AGENT queryParameters:nil body:nil 
    //                        requestType:MGTwitterPublicTimelineRequest 
    //                       responseType:MGTwitterStatuses];
    
    org::umit::icm::mobile::proto::RegisterAgent ra;
    ra.set_ip([@"localhost" UTF8String]);
    ra.set_agenttype([@"MOBILE" UTF8String]);
    ra.set_versionno(1);
    
    org::umit::icm::mobile::proto::LoginCredentials* cred = ra.mutable_credentials();
    cred->set_username([@"test" UTF8String]);
    cred->set_password([@"pass" UTF8String]);
    
    org::umit::icm::mobile::proto::RSAKey* rsaKey = ra.mutable_agentpublickey();
    rsaKey->set_mod([RSAKEY_MOD UTF8String]);
    rsaKey->set_exp([RSAKEY_EXP UTF8String]);
    
    std::string raStr = ra.SerializeAsString();
    //NSString* raNSStr = [NSString stringWithCString:raStr.c_str() encoding:NSUTF8StringEncoding];
    char base64Str[1000];
    size_t base64StrSize = 1000;
    Base64EncodeData(raStr.c_str(), raStr.length(), base64Str, &base64StrSize);
    base64Str[base64StrSize] = 0;

    NSLog(@"origin: %@", [NSString stringWithCString:raStr.c_str() encoding:NSUTF8StringEncoding]);
    NSString* base64NSStr = [NSString stringWithCString:base64Str encoding:NSASCIIStringEncoding];
    NSLog(@"base64: %@", base64NSStr);
    
    SecKeyWrapper * crypto = [SecKeyWrapper sharedWrapper];
    [crypto prepareKeys];
    
    // prepare key
    NSData* aeskey = [crypto getSymmetricKeyBytes];
    NSString* t = [NSString stringWithUTF8String:(const char *)[aeskey bytes]];
    NSLog(@"aes key: %@", aeskey);
    NSLog(@"aes key str: %@", t);
    NSString* aeskeyb64 = [aeskey base64EncodedString];
    NSLog(@"aes key b64 str: %@", aeskeyb64);
    NSData* aeskyb64data = [aeskeyb64 dataUsingEncoding:NSUTF8StringEncoding];
    NSData* encryptedkey = [crypto wrapSymmetricKey:aeskyb64data
                                             keyRef:crypto.aggregatorPublicKeyRef];
    NSString* finalKeyb64 = [encryptedkey base64EncodedString];
    
    // prepare msg
    // FIXME
    //base64NSStr = [[@"test msg" dataUsingEncoding:NSASCIIStringEncoding] base64EncodedString];
    base64NSStr = [NSString stringWithCString:raStr.c_str() encoding:NSUTF8StringEncoding];
    NSLog(@"msg b64: %@", base64NSStr);
    // Get the padding PKCS#7 flag.
    CCOptions pad = 0;
    NSData * encrypted = [crypto doCipher:[base64NSStr dataUsingEncoding:NSUTF8StringEncoding]
                                      key:crypto.symmetricKeyRef
                                  context:kCCEncrypt
                                  padding:&pad];
    NSLog(@"encrypted: %@", encrypted);
    NSString* finalMsgb64 = [encrypted base64EncodedString];
    /*
    NSData * decrypted = [crypto doCipher:encrypted
                                     key:crypto.symmetricKeyRef
                                 context:kCCDecrypt
                                 padding:&pad];
    NSString* decryptedStr = [NSString stringWithUTF8String:(const char*)[decrypted bytes]];
    NSLog(@"decrypted: %@", decryptedStr);*/

    
    MKNetworkOperation *op = [self operationWithPath:AGGR_REGISTER_AGENT
                                              params:[NSDictionary dictionaryWithObjectsAndKeys:                                     finalMsgb64, AGGR_MSG_KEY,                                           finalKeyb64, AGGR_KEY_KEY, nil]
                                          httpMethod:@"POST"];
    
    [op onCompletion:^(MKNetworkOperation *operation) {
        
        DLog(@"%@", operation);
        char decoded[1000];
        size_t decodedSize = 1000;
        NSString *resp = [operation responseString];
        Base64DecodeData([resp cStringUsingEncoding:NSUTF8StringEncoding], resp.length, decoded, &decodedSize);
        NSString* decodedNSStr = [NSString stringWithCString:decoded encoding:NSUTF8StringEncoding];
        NSLog(@"decoded: %@", decodedNSStr);
        
    } onError:^(NSError *error) {
        
        DLog(@"%@", error);
    }];
    
    [self enqueueOperation:op];
    
    return @"";
}

@end
