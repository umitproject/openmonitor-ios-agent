//
//  ICMAggregatorEngine.m
//  icm-ios-agent
//
//  Created by shinysky on 12-5-24.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "ICMAggregatorEngine.h"

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
    
    MKNetworkOperation *op = [self operationWithPath:AGGR_REGISTER_AGENT
                                              params:[NSDictionary dictionaryWithObjectsAndKeys:                                                      base64NSStr, AGGR_MSG_KEY, nil]
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
