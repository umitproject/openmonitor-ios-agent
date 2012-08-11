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
#import "NSData+Conversion.h"
#import "MF_Base64Additions.h"

#include "messages.pb.h"
#include "Base64Transcoder.h"
#include <fstream>

@implementation ICMAggregatorEngine

@synthesize agentId = _agentId;

static ICMAggregatorEngine * __sharedEngine = nil;

+ (ICMAggregatorEngine *)sharedEngine {
    @synchronized(self) {
        if (__sharedEngine == nil) {
            __sharedEngine = [[ICMAggregatorEngine alloc] init];
        }
    }
    return __sharedEngine;
}

- (ICMAggregatorEngine*)init
{
    if (self = [super initWithHostName:AGGREGATOR_URL customHeaderFields:nil]) {
        NSString * agentid = [[NSUserDefaults standardUserDefaults] objectForKey:NSDEFAULT_AGENT_ID_KEY];
        if (agentid != nil) {
            self.agentId = agentid;
        } else {
            self.agentId = nil;
        }
        crypto = [SecKeyWrapper sharedWrapper];
        [crypto prepareKeys];
    }
    return self;
}

#pragma mark -
#pragma mark REST API methods
#pragma mark -
#pragma mark Login methods

- (void)registerAgentWithUsername:(NSString *)name password:(NSString*)pass
{
	//return [self _sendRequestWithMethod:nil path:AGGR_REGISTER_AGENT queryParameters:nil body:nil 
    //                        requestType:MGTwitterPublicTimelineRequest 
    //                       responseType:MGTwitterStatuses];
    
    // prepare key
    NSData* aeskey = [crypto getSymmetricKeyBytes];
    //NSString* t = [NSString stringWithUTF8String:(const char *)[aeskey bytes]];
    NSLog(@"aes key: %@", aeskey);
    //NSLog(@"aes key str: %@", t);
    NSString* aeskeyb64 = [aeskey base64EncodedString];
    NSLog(@"aes key b64 str: %@", aeskeyb64);
    NSData* aeskyb64data = [aeskeyb64 dataUsingEncoding:NSUTF8StringEncoding];
    NSData* encryptedkey = [crypto wrapSymmetricKey:aeskyb64data
                                             keyRef:crypto.aggregatorPublicKeyRef];
    NSString* finalKeyb64 = [encryptedkey base64EncodedString];
    
    // prepare msg
    org::umit::icm::mobile::proto::RegisterAgent ra;
    ra.set_ip([@"192.168.1.18" UTF8String]);
    ra.set_agenttype([@"MOBILE" UTF8String]);
    ra.set_versionno(1);
    
    org::umit::icm::mobile::proto::LoginCredentials* cred = ra.mutable_credentials();
    cred->set_username([name UTF8String]);
    cred->set_password([pass UTF8String]);
    
    NSString* pubKeyModString = [[crypto getPublicKeyMod] hexadecimalString];
    NSString* pubKeyExpString = [[crypto getPublicKeyExp] hexadecimalString];
    NSLog(@"mod=%@", pubKeyModString);
    NSLog(@"exp=%@", pubKeyExpString); //should be '0x010001' = 65537
    org::umit::icm::mobile::proto::RSAKey* rsaKey = ra.mutable_agentpublickey();
    const char* pkcs = [pubKeyModString UTF8String];
    rsaKey->set_mod(pkcs);
    rsaKey->set_exp([RSAKEY_EXP UTF8String]);
    
    std::string raStr = ra.SerializeAsString();
    /*
    org::umit::icm::mobile::proto::RegisterAgent ra2;
    ra2.ParseFromString(raStr);
    std::string ip2 = ra2.ip();
    std::string agenttype2 = ra2.agenttype();
    
    NSLog(@"%s %s", ip2.c_str(), agenttype2.c_str());*/
    
    NSData * encrypted = [crypto encryptData:[NSData dataWithBytes:raStr.c_str() length:raStr.size()]];
    //NSLog(@"encrypted: %d %@", [encrypted length], encrypted);
    NSString* finalMsgb64 = [encrypted base64EncodedString];
    
    /*
    NSData * decrypted = [crypto decryptData:encrypted];
    NSString* decryptedStr = [[NSString alloc] initWithData:decrypted encoding:NSASCIIStringEncoding];
    NSLog(@"decrypted: %d %d %@ %@\n\n", [decrypted length], [decryptedStr length], decryptedStr, [[decryptedStr dataUsingEncoding:NSUTF8StringEncoding] description]);*/
    
    //NSLog(@"finalMsgb64:%@", finalMsgb64);
    //NSLog(@"finalKeyb64:%@", finalKeyb64);
    
    MKNetworkOperation *op = [self operationWithPath:AGGR_REGISTER_AGENT
                                              params:[NSDictionary dictionaryWithObjectsAndKeys:                                     finalMsgb64, AGGR_MSG_KEY,                                           finalKeyb64, AGGR_KEY_KEY, nil]
                                          httpMethod:@"POST"];
    
    [op onCompletion:^(MKNetworkOperation *operation) {
        
        DLog(@"%@", operation);
        NSString *resp = [operation responseString];
        NSData* respdata = [MF_Base64Codec dataFromBase64String:resp];
        //NSLog(@"respdata=%@", respdata);
        respdata = [respdata subdataWithRange:NSMakeRange(0,[respdata length]-1)];
        //NSLog(@"respdata=%@", respdata);
        NSData * decrypted = [crypto decryptData:respdata];
        //NSLog(@"decrypted=%s", [decrypted bytes]);
        
        org::umit::icm::mobile::proto::RegisterAgentResponse rar;
        rar.ParsePartialFromArray([decrypted bytes], [decrypted length]);
        std::string aid = rar.agentid();
        NSLog(@"register succeeded! got agent id: %s", aid.c_str());
        
        self.agentId = [NSString stringWithCString:aid.c_str() encoding:NSUTF8StringEncoding];
        NSLog(@"saving agentid: %@", self.agentId);
        [[NSUserDefaults standardUserDefaults] setObject:self.agentId forKey:NSDEFAULT_AGENT_ID_KEY];
        
        [self loginStep1];
        
    } onError:^(NSError *error) {
        
        DLog(@"%@", error);
    }];
    
    [self enqueueOperation:op];
}

- (void)loginStep1
{
    // prepare msg
    org::umit::icm::mobile::proto::Login msg;
    msg.set_agentid([self.agentId cStringUsingEncoding:NSUTF8StringEncoding]);
    msg.set_port(5555);//TODO port
    msg.set_challenge("iOS agent challenge");
    
    std::string msgStr = msg.SerializeAsString();
    NSData* msgData = [NSData dataWithBytes:msgStr.c_str() length:msgStr.size()];
    //NSData * encrypted = [crypto encryptData:msgData];
    //NSLog(@"encrypted: %@", encrypted);
    NSString* finalMsgb64 = [msgData base64EncodedString];
    NSLog(@"finalMsgb64:%@", finalMsgb64);
    
    MKNetworkOperation *op = [self operationWithPath:AGGR_LOGIN
                                              params:[NSDictionary dictionaryWithObjectsAndKeys:
                                                      finalMsgb64, AGGR_MSG_KEY,
                                                      [NSString stringWithFormat:@"%@", self.agentId], AGGR_AGENT_ID_KEY,
                                                      nil]
                                          httpMethod:@"POST"];
    
    [op onCompletion:^(MKNetworkOperation *operation) {
        
        DLog(@"%@", operation);
        NSString *respStr = [operation responseString];
        [self loginStep2:respStr];
        
    } onError:^(NSError *error) {
        
        DLog(@"%@", error);
    }];
    
    [self enqueueOperation:op];
}

- (void)loginStep2:(NSString*)prevRespStr
{
    NSData* prevRespdata = [NSData dataWithBase64String:prevRespStr];
    org::umit::icm::mobile::proto::LoginStep1 prevResp;
    prevResp.ParseFromArray((const void*)[prevRespdata bytes], [prevRespdata length]);
    //TODO resp.cipheredchallenge() should be equal to the string we set in step 1
    std::string challenge = prevResp.challenge();
    NSLog(@"challenge base64: %s", challenge.c_str());
    std::string processID = prevResp.processid();
    
    // prepare msg
    org::umit::icm::mobile::proto::LoginStep2 msg;
    msg.set_processid(processID);
    // cipheredchallenge
    NSData* ccData = [crypto getSignatureBytes:[NSData dataWithBytes:challenge.c_str() length:challenge.size()]];
    NSString* ccStr = [ccData base64EncodedString];
    NSLog(@"challenge signed b64: %@", ccStr);
    
    msg.set_cipheredchallenge([ccStr cStringUsingEncoding:NSASCIIStringEncoding]);
    
    std::string msgStr = msg.SerializeAsString();
    NSData* msgData = [NSData dataWithBytes:msgStr.c_str() length:msgStr.size()];
    NSString* finalMsgb64 = [msgData base64EncodedString];
    NSLog(@"finalMsgb64:%@", finalMsgb64);
    
    MKNetworkOperation *op = [self operationWithPath:AGGR_LOGIN2
                                              params:[NSDictionary dictionaryWithObjectsAndKeys:
                                                      finalMsgb64, AGGR_MSG_KEY,
                                                      [NSString stringWithFormat:@"%@", self.agentId], AGGR_AGENT_ID_KEY,
                                                      nil]
                                          httpMethod:@"POST"];
    
    [op onCompletion:^(MKNetworkOperation *operation) {
        
        DLog(@"%@", operation);
        NSString *respStr = [operation responseString];
        NSData* respdata = [NSData dataWithBase64String: respStr];
        NSLog(@"decoded data: %@", respdata);
        org::umit::icm::mobile::proto::LoginResponse resp;
        resp.ParseFromArray((const void*)[respdata bytes], [respdata length]);
        
        if (resp.has_header()) {
            NSLog(@"LoginResponse has header.");
        } else {
            NSLog(@"LoginResponse has NO header.");
        }
        
        org::umit::icm::mobile::proto::ResponseHeader header = resp.header();
        NSLog(@"Got report response: curversionno=%d curtestversiono=%d", header.currentversionno(), header.currenttestversionno());
        
        [self checkNewTests];
        
    } onError:^(NSError *error) {
        
        DLog(@"%@", error);
    }];
    
    [self enqueueOperation:op];
}

- (void)logoutAgent
{
    // prepare msg
    org::umit::icm::mobile::proto::Logout msg;
    msg.set_agentid([self.agentId cStringUsingEncoding:NSUTF8StringEncoding]);
    
    std::string msgStr = msg.SerializeAsString();
    NSData * encrypted = [crypto encryptData:[NSData dataWithBytes:msgStr.c_str() length:msgStr.size()]];
    NSLog(@"encrypted: %d %@", [encrypted length], encrypted);
    NSString* finalMsgb64 = [encrypted base64EncodedString];
    NSLog(@"finalMsgb64:%@", finalMsgb64);
    
    MKNetworkOperation *op = [self operationWithPath:AGGR_LOGOUT
                                              params:[NSDictionary dictionaryWithObjectsAndKeys:
                                                      finalMsgb64, AGGR_MSG_KEY,
                                                      [NSString stringWithFormat:@"%@", self.agentId], AGGR_AGENT_ID_KEY,
                                                      nil]
                                          httpMethod:@"POST"];
    
    [op onCompletion:^(MKNetworkOperation *operation) {
        
        DLog(@"%@", operation);
        NSString *respStr = [operation responseString];
        NSData* respdata = [NSData dataWithBase64String: respStr];
        NSLog(@"decoded data: %@", respdata);
        org::umit::icm::mobile::proto::LogoutResponse resp;
        resp.ParseFromArray((const void*)[respdata bytes], [respdata length]);
        std::string status = resp.status();
        NSString* statusStr = [NSString stringWithCString:status.c_str() encoding:NSUTF8StringEncoding];
        NSLog(@"Logout Status: %@", statusStr);
        
    } onError:^(NSError *error) {
        
        DLog(@"%@", error);
    }];
    
    [self enqueueOperation:op];
}

#pragma mark -
#pragma mark Report/Event methods

- (void)getEvents
{
    // prepare msg
    org::umit::icm::mobile::proto::GetEvents ge;
    org::umit::icm::mobile::proto::Location* loc = ge.add_locations();
    loc->set_latitude(41);
    loc->set_longitude(29);
    
    std::string geStr = ge.SerializeAsString();
    NSData* geData = [NSData dataWithBytes:geStr.c_str() length:geStr.size()];
    NSData * encrypted = [crypto encryptData:geData];
    NSLog(@"encrypted: %@", encrypted);
    NSString* finalMsgb64 = [encrypted base64EncodedString];
    NSLog(@"finalMsgb64:%@", finalMsgb64);
    
    MKNetworkOperation *op = [self operationWithPath:AGGR_GET_EVENTS
                                              params:[NSDictionary dictionaryWithObjectsAndKeys:
                                                      finalMsgb64, AGGR_MSG_KEY,
                                                      [NSString stringWithFormat:@"%@", self.agentId], AGGR_AGENT_ID_KEY,
                                                      nil]
                                          httpMethod:@"POST"];
    
    [op onCompletion:^(MKNetworkOperation *operation) {
        
        DLog(@"%@", operation);
        NSString *resp = [operation responseString];
        NSData* respdata = [NSData dataWithBase64String: resp];
        NSLog(@"decoded data: %@", respdata);
        org::umit::icm::mobile::proto::GetEventsResponse rar;
        rar.ParseFromArray((const void*)[respdata bytes], [respdata length]);
        int es = rar.events_size();
        NSLog(@"got %d events", es);
        for (int i = 0; i < es; i++) {
            org::umit::icm::mobile::proto::Event e = rar.events(i);
            std::string ttStr = e.testtype();
            std::string etStr = e.eventtype();
            int t = e.timeutc();
            int st = e.sincetimeutc();
            
            NSString* ttNSStr = [NSString stringWithCString:ttStr.c_str() encoding:NSUTF8StringEncoding];
            NSString* etNSStr = [NSString stringWithCString:etStr.c_str() encoding:NSUTF8StringEncoding];
            
            NSLog(@"got event: %d %d %@ %@", t, st, ttNSStr, etNSStr);
        }
        
    } onError:^(NSError *error) {
        
        DLog(@"%@", error);
    }];
    
    [self enqueueOperation:op];
}

- (void)sendWebsiteReport:(ICMWebsite*)site
{
    org::umit::icm::mobile::proto::SendWebsiteReport sendReport;
    org::umit::icm::mobile::proto::WebsiteReport* report = sendReport.mutable_report();
    org::umit::icm::mobile::proto::ICMReport* header = report->mutable_header();
    header->set_testid(1); //TODO 1 for Website test, 2 for Service test, 3 for Throttling test
    header->set_agentid([self.agentId cStringUsingEncoding:NSUTF8StringEncoding]);
    header->set_timezone(8);
    header->set_reportid([self generateUuidCString]);
    header->set_timeutc([site.lastcheck timeIntervalSince1970]);
    org::umit::icm::mobile::proto::WebsiteReportDetail* detail = report->mutable_report();
    detail->set_websiteurl([site.url cStringUsingEncoding:NSASCIIStringEncoding]);
    if ([site.status intValue] == 200) {
        detail->set_statuscode(kStatusNormal); //1 - Normal, 2 - Down, 3 - Content changed
    } else {
        detail->set_statuscode(kStatusDown); //1 - Normal, 2 - Down, 3 - Content changed
    }
    std::string geStr = sendReport.SerializeAsString();
    NSData* geData = [NSData dataWithBytes:geStr.c_str() length:geStr.size()];
    NSData * encrypted = [crypto encryptData:geData];
    NSLog(@"encrypted: %@", encrypted);
    NSString* finalMsgb64 = [encrypted base64EncodedString];
    NSLog(@"finalMsgb64:%@", finalMsgb64);
    
    MKNetworkOperation *op = [self operationWithPath:AGGR_GET_EVENTS
                                              params:[NSDictionary dictionaryWithObjectsAndKeys:
                                                      finalMsgb64, AGGR_MSG_KEY,
                                                      [NSString stringWithFormat:@"%@", self.agentId], AGGR_AGENT_ID_KEY,
                                                      nil]
                                          httpMethod:@"POST"];
    
    [op onCompletion:^(MKNetworkOperation *operation) {
        
        DLog(@"%@", operation);
        NSString *resp = [operation responseString];
        NSData* respdata = [NSData dataWithBase64String: resp];
        NSLog(@"decoded data: %@", respdata);
        org::umit::icm::mobile::proto::SendReportResponse rar;
        rar.ParseFromArray((const void*)[respdata bytes], [respdata length]);
        org::umit::icm::mobile::proto::ResponseHeader header = rar.header();
        NSLog(@"Got report response: curversionno=%d curtestversiono=%d", header.currentversionno(), header.currenttestversionno());
        
    } onError:^(NSError *error) {
        
        DLog(@"%@", error);
    }];
    
    [self enqueueOperation:op];
}

- (void)sendServiceReport:(ICMService*)service
{
    org::umit::icm::mobile::proto::SendServiceReport sendReport;
    org::umit::icm::mobile::proto::ServiceReport* report = sendReport.mutable_report();
    org::umit::icm::mobile::proto::ICMReport* header = report->mutable_header();
    header->set_testid(2); // 1 for Website test, 2 for Service test, 3 for Throttling test
    header->set_agentid([self.agentId cStringUsingEncoding:NSUTF8StringEncoding]);
    header->set_timezone(8);
    header->set_reportid([self generateUuidCString]);
    header->set_timeutc([service.lastcheck timeIntervalSince1970]);
    org::umit::icm::mobile::proto::ServiceReportDetail* detail = report->mutable_report();
    detail->set_servicename([service.name cStringUsingEncoding:NSASCIIStringEncoding]);
    detail->set_port([service.port intValue]);
    detail->set_statuscode([service.status intValue]); //1 - Normal, 2 - Down
    
    std::string geStr = sendReport.SerializeAsString();
    NSData* geData = [NSData dataWithBytes:geStr.c_str() length:geStr.size()];
    NSData * encrypted = [crypto encryptData:geData];
    NSLog(@"encrypted: %@", encrypted);
    NSString* finalMsgb64 = [encrypted base64EncodedString];
    NSLog(@"finalMsgb64:%@", finalMsgb64);
    
    MKNetworkOperation *op = [self operationWithPath:AGGR_GET_EVENTS
                                              params:[NSDictionary dictionaryWithObjectsAndKeys:
                                                      finalMsgb64, AGGR_MSG_KEY,
                                                      [NSString stringWithFormat:@"%@", self.agentId], AGGR_AGENT_ID_KEY,
                                                      nil]
                                          httpMethod:@"POST"];
    
    [op onCompletion:^(MKNetworkOperation *operation) {
        
        DLog(@"%@", operation);
        NSString *resp = [operation responseString];
        NSData* respdata = [NSData dataWithBase64String: resp];
        NSLog(@"decoded data: %@", respdata);
        org::umit::icm::mobile::proto::SendReportResponse rar;
        rar.ParseFromArray((const void*)[respdata bytes], [respdata length]);
        org::umit::icm::mobile::proto::ResponseHeader header = rar.header();
        NSLog(@"Got report response: curversionno=%d curtestversiono=%d", header.currentversionno(), header.currenttestversionno());
        
    } onError:^(NSError *error) {
        
        DLog(@"%@", error);
    }];
    
    [self enqueueOperation:op];
}

#pragma mark -
#pragma mark Tests methods

- (void)checkNewTests
{
    org::umit::icm::mobile::proto::NewTests newTests;
    newTests.set_currenttestversionno(1);//TODO
    
    std::string geStr = newTests.SerializeAsString();
    NSData* geData = [NSData dataWithBytes:geStr.c_str() length:geStr.size()];
    NSData * encrypted = [crypto encryptData:geData];
    NSLog(@"encrypted: %@", encrypted);
    NSString* finalMsgb64 = [encrypted base64EncodedString];
    NSLog(@"finalMsgb64:%@", finalMsgb64);
    
    MKNetworkOperation *op = [self operationWithPath:AGGR_CHECK_TESTS
                                              params:[NSDictionary dictionaryWithObjectsAndKeys:
                                                      finalMsgb64, AGGR_MSG_KEY,
                                                      [NSString stringWithFormat:@"%@", self.agentId], AGGR_AGENT_ID_KEY,
                                                      nil]
                                          httpMethod:@"POST"];
    
    [op onCompletion:^(MKNetworkOperation *operation) {
        
        DLog(@"%@", operation);
        NSString *resp = [operation responseString];
        NSData* respdata = [NSData dataWithBase64String: resp];
        NSLog(@"decoded data: %@", respdata);
        org::umit::icm::mobile::proto::NewTestsResponse rar;
        rar.ParseFromArray((const void*)[respdata bytes], [respdata length]);
        NSLog(@"Got NewTestsResponse: curtestversiono=%d", rar.testversionno());
        
        int es = rar.tests_size();
        NSLog(@"got %d tests", es);
        for (int i = 0; i < es; i++) {
            org::umit::icm::mobile::proto::Test e = rar.tests(i);
            std::string testid = e.testid();
            //std::string ttStr = e.testtype();
            //std::string etStr = e.eventtype();
            __int64_t t = e.executeattimeutc();
            int tt = e.testtype();
            
            //NSString* ttNSStr = [NSString stringWithCString:ttStr.c_str() encoding:NSUTF8StringEncoding];
            //NSString* etNSStr = [NSString stringWithCString:etStr.c_str() encoding:NSUTF8StringEncoding];
            
            NSLog(@"got test: %lld %d %s", t, tt, testid.c_str());
        }
        
    } onError:^(NSError *error) {
        
        DLog(@"%@", error);
    }];
    
    [self enqueueOperation:op];
}

- (void)suggestWebsiteWithName:(NSString*)name url:(NSString*)url
{
    org::umit::icm::mobile::proto::WebsiteSuggestion suggestion;
    suggestion.set_websiteurl([url cStringUsingEncoding:NSUTF8StringEncoding]);
    
    std::string geStr = suggestion.SerializeAsString();
    NSData* geData = [NSData dataWithBytes:geStr.c_str() length:geStr.size()];
    NSData * encrypted = [crypto encryptData:geData];
    NSLog(@"encrypted: %@", encrypted);
    NSString* finalMsgb64 = [encrypted base64EncodedString];
    NSLog(@"finalMsgb64:%@", finalMsgb64);
    
    MKNetworkOperation *op = [self operationWithPath:AGGR_WEBSITE_SUGGESTION
                                              params:[NSDictionary dictionaryWithObjectsAndKeys:
                                                      finalMsgb64, AGGR_MSG_KEY,
                                                      [NSString stringWithFormat:@"%@", self.agentId], AGGR_AGENT_ID_KEY,
                                                      nil]
                                          httpMethod:@"POST"];
    
    [op onCompletion:^(MKNetworkOperation *operation) {
        
        DLog(@"%@", operation);
        NSString *resp = [operation responseString];
        NSData* respdata = [NSData dataWithBase64String: resp];
        NSLog(@"decoded data: %@", respdata);
        org::umit::icm::mobile::proto::TestSuggestionResponse rar;
        rar.ParseFromArray((const void*)[respdata bytes], [respdata length]);
        org::umit::icm::mobile::proto::ResponseHeader header = rar.header();
        NSLog(@"Got report response: curversionno=%d curtestversiono=%d", header.currentversionno(), header.currenttestversionno());
        
    } onError:^(NSError *error) {
        
        DLog(@"%@", error);
    }];
    
    [self enqueueOperation:op];
}

- (void)suggestServiceWithName:(NSString*)name host:(NSString*)host ip:(NSString*)ip port:(int)port
{
    org::umit::icm::mobile::proto::ServiceSuggestion suggestion;
    suggestion.set_servicename([name cStringUsingEncoding:NSUTF8StringEncoding]);
    suggestion.set_hostname([host cStringUsingEncoding:NSUTF8StringEncoding]);
    suggestion.set_ip([ip cStringUsingEncoding:NSUTF8StringEncoding]);
    suggestion.set_port(port);
    
    std::string geStr = suggestion.SerializeAsString();
    NSData* geData = [NSData dataWithBytes:geStr.c_str() length:geStr.size()];
    NSData * encrypted = [crypto encryptData:geData];
    NSLog(@"encrypted: %@", encrypted);
    NSString* finalMsgb64 = [encrypted base64EncodedString];
    NSLog(@"finalMsgb64:%@", finalMsgb64);
    
    MKNetworkOperation *op = [self operationWithPath:AGGR_SERVICE_SUGGESTION
                                              params:[NSDictionary dictionaryWithObjectsAndKeys:
                                                      finalMsgb64, AGGR_MSG_KEY,
                                                      [NSString stringWithFormat:@"%@", self.agentId], AGGR_AGENT_ID_KEY,
                                                      nil]
                                          httpMethod:@"POST"];
    
    [op onCompletion:^(MKNetworkOperation *operation) {
        
        DLog(@"%@", operation);
        NSString *resp = [operation responseString];
        NSData* respdata = [NSData dataWithBase64String: resp];
        NSLog(@"decoded data: %@", respdata);
        org::umit::icm::mobile::proto::TestSuggestionResponse rar;
        rar.ParseFromArray((const void*)[respdata bytes], [respdata length]);
        org::umit::icm::mobile::proto::ResponseHeader header = rar.header();
        NSLog(@"Got report response: curversionno=%d curtestversiono=%d", header.currentversionno(), header.currenttestversionno());
        
    } onError:^(NSError *error) {
        
        DLog(@"%@", error);
    }];
    
    [self enqueueOperation:op];
}

#pragma mark -
#pragma mark Other methods

- (void)getPeerList
{
    
}
- (void)getSuperPeerList
{
    
}
- (void)checkVersion
{
    org::umit::icm::mobile::proto::NewVersion pbmsg;
    pbmsg.set_agentversionno(1);
    pbmsg.set_agenttype("MOBILE");
    
    std::string geStr = pbmsg.SerializeAsString();
    NSData* geData = [NSData dataWithBytes:geStr.c_str() length:geStr.size()];
    NSData * encrypted = [crypto encryptData:geData];
    NSLog(@"encrypted: %@", encrypted);
    NSString* finalMsgb64 = [encrypted base64EncodedString];
    NSLog(@"finalMsgb64:%@", finalMsgb64);
    
    MKNetworkOperation *op = [self operationWithPath:AGGR_CHECK_VERSION
                                              params:[NSDictionary dictionaryWithObjectsAndKeys:
                                                      finalMsgb64, AGGR_MSG_KEY,
                                                      [NSString stringWithFormat:@"%@", self.agentId], AGGR_AGENT_ID_KEY,
                                                      nil]
                                          httpMethod:@"POST"];
    
    [op onCompletion:^(MKNetworkOperation *operation) {
        
        DLog(@"%@", operation);
        NSString *resp = [operation responseString];
        NSData* respdata = [NSData dataWithBase64String: resp];
        NSLog(@"decoded data: %@", respdata);
        org::umit::icm::mobile::proto::NewVersionResponse rar;
        rar.ParseFromArray((const void*)[respdata bytes], [respdata length]);
        org::umit::icm::mobile::proto::ResponseHeader header = rar.header();
        NSLog(@"Got report response: curversionno=%d curtestversiono=%d", header.currentversionno(), header.currenttestversionno());
        if (rar.has_downloadurl())
            NSLog(@"New version available");
        
    } onError:^(NSError *error) {
        
        DLog(@"%@", error);
    }];
    
    [self enqueueOperation:op];
}
- (void)checkAggregator
{
    org::umit::icm::mobile::proto::CheckAggregator pbmsg;
    pbmsg.set_agenttype("MOBILE");
    
    std::string geStr = pbmsg.SerializeAsString();
    NSData* geData = [NSData dataWithBytes:geStr.c_str() length:geStr.size()];
    NSData * encrypted = [crypto encryptData:geData];
    NSLog(@"encrypted: %@", encrypted);
    NSString* finalMsgb64 = [encrypted base64EncodedString];
    NSLog(@"finalMsgb64:%@", finalMsgb64);
    
    MKNetworkOperation *op = [self operationWithPath:AGGR_CHECK_AGGREGATOR
                                              params:[NSDictionary dictionaryWithObjectsAndKeys:
                                                      finalMsgb64, AGGR_MSG_KEY,
                                                      [NSString stringWithFormat:@"%@", self.agentId], AGGR_AGENT_ID_KEY,
                                                      nil]
                                          httpMethod:@"POST"];
    
    [op onCompletion:^(MKNetworkOperation *operation) {
        
        DLog(@"%@", operation);
        NSString *resp = [operation responseString];
        NSData* respdata = [NSData dataWithBase64String: resp];
        NSLog(@"decoded data: %@", respdata);
        org::umit::icm::mobile::proto::CheckAggregatorResponse rar;
        rar.ParseFromArray((const void*)[respdata bytes], [respdata length]);
        org::umit::icm::mobile::proto::ResponseHeader header = rar.header();
        NSLog(@"Got report response: curversionno=%d curtestversiono=%d", header.currentversionno(), header.currenttestversionno());
        std::string status = rar.status();
        NSString* nsstatus = [NSString stringWithCString:status.c_str() encoding:NSUTF8StringEncoding];
        NSLog(@"Aggregator Status: %@", nsstatus);
        
    } onError:^(NSError *error) {
        
        DLog(@"%@", error);
    }];
    
    [self enqueueOperation:op];
}
- (void)getNetList
{
    
}
- (void)getBanList
{
    
}
- (void)getBanNets
{
    
}

#pragma mark -
#pragma mark Utils

- (const char *)generateUuidCString
{
    NSString* uuidString = [self generateUuidString];
    return [uuidString cStringUsingEncoding:NSUTF8StringEncoding];
}

// return a new autoreleased UUID string
- (NSString *)generateUuidString
{
    // create a new UUID which you own
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    
    // create a new CFStringRef (toll-free bridged to NSString)
    // that you own
    NSString *uuidString = (__bridge NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
    
    // release the UUID
    CFRelease(uuid);
    
    return uuidString;
}

@end
