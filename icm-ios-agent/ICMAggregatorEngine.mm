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

@synthesize agentId = _agentId;

static ICMAggregatorEngine * __sharedEngine = nil;

+ (ICMAggregatorEngine *)sharedEngine {
    @synchronized(self) {
        if (__sharedEngine == nil) {
            __sharedEngine = [[ICMAggregatorEngine alloc] initWithHostName:AGGREGATOR_URL customHeaderFields:nil];
            NSNumber * agentid = [[NSUserDefaults standardUserDefaults] objectForKey:AGENT_ID_KEY];
            if (agentid != nil) {
                __sharedEngine.agentId = [agentid intValue];
            } else {
                __sharedEngine.agentId = -1;
            }
        }
    }
    return __sharedEngine;
}

#pragma mark -
#pragma mark REST API methods
#pragma mark -

#pragma mark Login methods

- (void)registerAgent
{
	//return [self _sendRequestWithMethod:nil path:AGGR_REGISTER_AGENT queryParameters:nil body:nil 
    //                        requestType:MGTwitterPublicTimelineRequest 
    //                       responseType:MGTwitterStatuses];
    
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
    org::umit::icm::mobile::proto::RegisterAgent ra;
    ra.set_ip([@"162.111.1.18" UTF8String]);
    ra.set_agenttype([@"MOBILE" UTF8String]);
    ra.set_versionno(1);
    
    org::umit::icm::mobile::proto::LoginCredentials* cred = ra.mutable_credentials();
    cred->set_username([@"test" UTF8String]);
    cred->set_password([@"pass" UTF8String]);
    
    org::umit::icm::mobile::proto::RSAKey* rsaKey = ra.mutable_agentpublickey();
    rsaKey->set_mod([RSAKEY_MOD UTF8String]);
    rsaKey->set_exp([RSAKEY_EXP UTF8String]);
    
    std::string raStr = ra.SerializeAsString();
    NSString* raNSStr = [NSString stringWithCString:raStr.c_str() encoding:NSASCIIStringEncoding];
    NSLog(@"origin msg: %lu %d %@\n\n", raStr.length(), [raNSStr length], [[raNSStr dataUsingEncoding:NSASCIIStringEncoding] description]);
    
    NSData * encrypted = [crypto encryptData:[raNSStr dataUsingEncoding:NSASCIIStringEncoding]];
    NSLog(@"encrypted: %@", encrypted);
    NSString* finalMsgb64 = [encrypted base64EncodedString];
    
    NSData * decrypted = [crypto decryptData:encrypted];
    NSString* decryptedStr = [NSString stringWithUTF8String:(const char*)[decrypted bytes]];
    NSLog(@"decrypted: %d %@ %@\n\n", [decryptedStr length], decryptedStr, [[decryptedStr dataUsingEncoding:NSASCIIStringEncoding] description]);
    
    MKNetworkOperation *op = [self operationWithPath:AGGR_REGISTER_AGENT
                                              params:[NSDictionary dictionaryWithObjectsAndKeys:                                     finalMsgb64, AGGR_MSG_KEY,                                           finalKeyb64, AGGR_KEY_KEY, nil]
                                          httpMethod:@"POST"];
    NSLog(@"finalMsgb64:%@", finalMsgb64);
    NSLog(@"finalKeyb64:%@", finalKeyb64);
    
    [op onCompletion:^(MKNetworkOperation *operation) {
        
        DLog(@"%@", operation);
        NSString *resp = [operation responseString];
        NSData* respdata = [NSData dataFromBase64String: resp];
        NSLog(@"decoded data: %@", respdata);
        org::umit::icm::mobile::proto::RegisterAgentResponse rar;
        rar.ParseFromArray((const void*)[respdata bytes], [respdata length]);
        int aid = rar.agentid();
        NSLog(@"register succeeded! got agent id: %d", aid);
        
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:aid] forKey:AGENT_ID_KEY];
        self.agentId = aid;
        
    } onError:^(NSError *error) {
        
        DLog(@"%@", error);
    }];
    
    [self enqueueOperation:op];
}

- (void)getEvents
{
    // prepare msg
    org::umit::icm::mobile::proto::GetEvents ge;
    org::umit::icm::mobile::proto::Location* loc = ge.add_locations();
    loc->set_latitude(34);
    loc->set_longitude(108);
    
    std::string geStr = ge.SerializeAsString();
    NSData* geData = [NSData dataWithBytes:geStr.c_str() length:geStr.size()];
    NSString* finalMsgb64 = [geData base64EncodedString];

    MKNetworkOperation *op = [self operationWithPath:AGGR_GET_EVENTS
                                              params:[NSDictionary dictionaryWithObjectsAndKeys:
                                                      finalMsgb64, AGGR_MSG_KEY,
                                                      [NSString stringWithFormat:@"%d", self.agentId], AGGR_AGENT_ID_KEY,
                                                      nil]
                                          httpMethod:@"POST"];
    NSLog(@"finalMsgb64:%@", finalMsgb64);
    
    [op onCompletion:^(MKNetworkOperation *operation) {
        
        DLog(@"%@", operation);
        NSString *resp = [operation responseString];
        NSData* respdata = [NSData dataFromBase64String: resp];
        NSLog(@"decoded data: %@", respdata);
        org::umit::icm::mobile::proto::GetEventsResponse rar;
        rar.ParseFromArray((const void*)[respdata bytes], [respdata length]);
        int es = rar.events_size();
        for (int i = 0; i < es; i++) {
            org::umit::icm::mobile::proto::Event e = rar.events(i);
            std::string ttStr = e.testtype();
            std::string etStr = e.eventtype();
            int t = e.timeutc();
            int st = e.sincetimeutc();
            
            NSString* ttNSStr = [NSString stringWithCString:ttStr.c_str() encoding:ttStr.size()];
            NSString* etNSStr = [NSString stringWithCString:etStr.c_str() encoding:etStr.size()];
            
            NSLog(@"got event: %d %d %@ %@", t, st, ttNSStr, etNSStr);
        }

        
    } onError:^(NSError *error) {
        
        DLog(@"%@", error);
    }];
    
    [self enqueueOperation:op];
}

- (void)sendwebsitereport
{
    
}


@end
