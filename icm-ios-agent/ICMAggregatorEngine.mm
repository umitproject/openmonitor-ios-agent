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
#import "NSData+CDBase64.h"

#include "messages.pb.h"

@implementation ICMAggregatorEngine

@synthesize agentId = _agentId;
@synthesize delegate;

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
    NSString * host = [[NSUserDefaults standardUserDefaults] objectForKey:NSDEFAULT_AGGR_HOST_KEY];
    if ([host length] < 4) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert" 
                                                        message:@"Invalid aggregator host! Please input a valid host in Settings."
                                                       delegate:nil 
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    
    if (self = [super initWithHostName:host customHeaderFields:nil]) {
        NSString * agentid = [[NSUserDefaults standardUserDefaults] objectForKey:NSDEFAULT_AGENT_ID_KEY];
        if (agentid != nil) {
            self.agentId = agentid;
        } else {
            self.agentId = nil;
        }
        crypto = [SecKeyWrapper sharedWrapper];
        [crypto prepareKeys];
        managedObjectContext = [ICMAppDelegate GetContext];
    }
    return self;
}

- (bool)isLoggedIn
{
    if (self.agentId != nil) {
        return YES;
    }
    return NO;
}

#pragma mark -
#pragma mark REST API methods
#pragma mark -
#pragma mark Login methods

- (void)registerAgentWithUsername:(NSString *)name password:(NSString*)pass
{
    // prepare key
    NSData* aeskey = [crypto getSymmetricKeyBytes];
    NSLog(@"aes key: %@", aeskey);
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
        NSData* respdata = [NSData dataWithBase64EncodedString:resp];
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
        [self.delegate agentLoggedInWithError:error];
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
        [self.delegate agentLoggedInWithError:error];
    }];
    
    [self enqueueOperation:op];
}

- (void)loginStep2:(NSString*)prevRespStr
{
    NSData* prevRespdata = [NSData dataWithBase64EncodedString:prevRespStr];

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
        NSData* respdata = [NSData dataWithBase64EncodedString: respStr];
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
        
        [self.delegate agentLoggedInWithError:nil];
        [self checkNewTests];
        
    } onError:^(NSError *error) {
        
        DLog(@"%@", error);
        [self.delegate agentLoggedInWithError:error];
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
        NSData* respdata = [NSData dataWithBase64EncodedString: respStr];
        NSLog(@"decoded data: %@", respdata);
        org::umit::icm::mobile::proto::LogoutResponse resp;
        resp.ParseFromArray((const void*)[respdata bytes], [respdata length]);
        std::string status = resp.status();
        NSString* statusStr = [NSString stringWithCString:status.c_str() encoding:NSUTF8StringEncoding];
        NSLog(@"Logout Status: %@", statusStr);
        self.agentId = nil;
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:NSDEFAULT_AGENT_ID_KEY];
        [self.delegate agentLoggedOutWithError:nil];
        
    } onError:^(NSError *error) {
        
        DLog(@"%@", error);
        [self.delegate agentLoggedOutWithError:error];
        
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
    loc->set_latitude(41.05918);
    loc->set_longitude(28.95015);//41.05918, 28.95015
    
    loc = ge.add_locations();
    loc->set_latitude(41.00918);
    loc->set_longitude(28.90015);
    
    loc = ge.add_locations();
    loc->set_latitude(41.10918);
    loc->set_longitude(28.99015);
    
    loc = ge.mutable_agentlocation();
    loc->set_latitude(41.05918);
    loc->set_longitude(28.95015);
    
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
        NSData* respdata = [NSData dataWithBase64EncodedString: resp];
        NSLog(@"decoded data: %@", respdata);
        NSData * decrypted = [crypto decryptData:respdata];
        NSLog(@"decrypted data: %@", decrypted);
        org::umit::icm::mobile::proto::GetEventsResponse rar;
        rar.ParseFromArray((const void*)[decrypted bytes], [decrypted length]);
        
        if (rar.has_header()) {
            NSLog(@"GetEventsResponse has header.");
        } else {
            NSLog(@"GetEventsResponse has NO header.");
        }
        org::umit::icm::mobile::proto::ResponseHeader header = rar.header();
        NSLog(@"GetEventsResponse: curversionno=%d curtestversiono=%d", header.currentversionno(), header.currenttestversionno());
        
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
    header->set_testid([site.uid UTF8String]); //TODO 1 for Website test, 2 for Service test, 3 for Throttling test
    header->set_agentid([self.agentId cStringUsingEncoding:NSUTF8StringEncoding]);
    header->set_timezone(8);
    //header->set_reportid([self generateUuidCString]);
    header->set_timeutc([site.lastcheck timeIntervalSince1970]);
    header->add_passednode([self.agentId cStringUsingEncoding:NSUTF8StringEncoding]);
    org::umit::icm::mobile::proto::TraceRoute* route = header->mutable_traceroute();
    route->set_target("152.168.1.1");
    route->set_hops(1);
    route->set_packetsize(1);
    org::umit::icm::mobile::proto::Trace* trace = route->add_traces();
    trace->set_hop(1);
    trace->set_ip("152.168.1.1");
    trace->add_packetstiming(2);
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
    
    MKNetworkOperation *op = [self operationWithPath:AGGR_SEND_WEBSITE_REPORT
                                              params:[NSDictionary dictionaryWithObjectsAndKeys:
                                                      finalMsgb64, AGGR_MSG_KEY,
                                                      [NSString stringWithFormat:@"%@", self.agentId], AGGR_AGENT_ID_KEY,
                                                      nil]
                                          httpMethod:@"POST"];
    
    [op onCompletion:^(MKNetworkOperation *operation) {
        
        DLog(@"%@", operation);
        NSString *resp = [operation responseString];
        NSData* respdata = [NSData dataWithBase64EncodedString: resp];
        NSLog(@"decoded data: %@", respdata);
        NSData * decrypted = [crypto decryptData:respdata];
        NSLog(@"decrypted data: %@", decrypted);
        org::umit::icm::mobile::proto::SendReportResponse rar;
        rar.ParseFromArray((const void*)[decrypted bytes], [decrypted length]);
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
    header->set_testid([service.uid UTF8String]); //TODO 1 for Website test, 2 for Service test, 3 for Throttling test
    header->set_agentid([self.agentId cStringUsingEncoding:NSUTF8StringEncoding]);
    header->set_timezone(8);
    //header->set_reportid([self generateUuidCString]);
    header->set_timeutc([service.lastcheck timeIntervalSince1970]);
    header->add_passednode([self.agentId cStringUsingEncoding:NSUTF8StringEncoding]);
    org::umit::icm::mobile::proto::TraceRoute* route = header->mutable_traceroute();
    route->set_target("112.168.1.1");
    route->set_hops(1);
    route->set_packetsize(1);
    org::umit::icm::mobile::proto::Trace* trace = route->add_traces();
    trace->set_hop(1);
    trace->set_ip("112.168.1.1");
    trace->add_packetstiming(2);
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
    
    MKNetworkOperation *op = [self operationWithPath:AGGR_SEND_SERVICE_REPORT
                                              params:[NSDictionary dictionaryWithObjectsAndKeys:
                                                      finalMsgb64, AGGR_MSG_KEY,
                                                      [NSString stringWithFormat:@"%@", self.agentId], AGGR_AGENT_ID_KEY,
                                                      nil]
                                          httpMethod:@"POST"];
    
    [op onCompletion:^(MKNetworkOperation *operation) {
        
        DLog(@"%@", operation);
        NSString *resp = [operation responseString];
        NSData* respdata = [NSData dataWithBase64EncodedString: resp];
        NSLog(@"decoded data: %@", respdata);
        NSData * decrypted = [crypto decryptData:respdata];
        NSLog(@"decrypted data: %@", decrypted);
        org::umit::icm::mobile::proto::SendReportResponse rar;
        rar.ParseFromArray((const void*)[decrypted bytes], [decrypted length]);
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
    newTests.set_currenttestversionno(0);//TODO
    
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
        NSData* respdata = [NSData dataWithBase64EncodedString: resp];
        NSLog(@"decoded data: %@", respdata);
        NSData * decrypted = [crypto decryptData:respdata];
        NSLog(@"decrypted data: %@", decrypted);
        org::umit::icm::mobile::proto::NewTestsResponse rar;
        rar.ParseFromArray((const void*)[decrypted bytes], [decrypted length]);
        NSLog(@"Got NewTestsResponse: curtestversiono=%d", rar.testversionno());
        
        int es = rar.tests_size();
        NSLog(@"got %d tests", es);
        for (int i = 0; i < es; i++) {
            org::umit::icm::mobile::proto::Test e = rar.tests(i);
            std::string testid = e.testid();
            __int64_t timeutc = e.executeattimeutc();
            int testtype = e.testtype();
            if (testtype == kWebsiteTest) {
                // WEB
                org::umit::icm::mobile::proto::Website site = e.website();
                std::string url = site.url();
                NSLog(@"web %s", url.c_str());
                ICMWebsite* icmsite = [NSEntityDescription insertNewObjectForEntityForName:@"ICMWebsite"
                                                                 inManagedObjectContext:managedObjectContext];
                [icmsite initWithUrl:[NSString stringWithCString:url.c_str() encoding:NSUTF8StringEncoding]
                                name:[NSString stringWithCString:url.c_str() encoding:NSUTF8StringEncoding]
                             enabled:true
                                 uid:[NSString stringWithCString:testid.c_str() encoding:NSUTF8StringEncoding]];
            } else if (testtype == kServiceTest) {
                // SERVICE
                org::umit::icm::mobile::proto::Service service = e.service();
                std::string name = service.name();
                std::string ip = service.ip();
                int port = service.port();
                NSLog(@"service %s %s %d", name.c_str(), ip.c_str(), port);
                ICMService* icmservice = [NSEntityDescription insertNewObjectForEntityForName:@"ICMService"
                                                                    inManagedObjectContext:managedObjectContext];
                [icmservice initWithHost:[NSString stringWithCString:ip.c_str() encoding:NSUTF8StringEncoding]
                                    port:port
                                    name:[NSString stringWithCString:name.c_str() encoding:NSUTF8StringEncoding]
                                 enabled:YES
                                     uid:[NSString stringWithCString:testid.c_str() encoding:NSUTF8StringEncoding]];
            }
            
            NSLog(@"got test: %lld %d %s", timeutc, testtype, testid.c_str());
        }
        [ICMAppDelegate SaveContext];
        //TODO save the test version
        
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
        NSData* respdata = [NSData dataWithBase64EncodedString: resp];
        NSLog(@"decoded data: %@", respdata);
        NSData * decrypted = [crypto decryptData:respdata];
        NSLog(@"decrypted data: %@", decrypted);
        org::umit::icm::mobile::proto::TestSuggestionResponse rar;
        rar.ParseFromArray((const void*)[decrypted bytes], [decrypted length]);
        org::umit::icm::mobile::proto::ResponseHeader header = rar.header();
        NSLog(@"Got report response: curversionno=%d curtestversiono=%d", header.currentversionno(), header.currenttestversionno());
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Suggest Website" 
                                                        message:@"Website suggestion added successfully! Make sure you subscribe to receive the site status once it is tested."
                                                       delegate:nil 
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        
    } onError:^(NSError *error) {
        
        DLog(@"%@", error);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Suggest Website" 
                                                        message:error.localizedDescription
                                                       delegate:nil 
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
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
        NSData* respdata = [NSData dataWithBase64EncodedString: resp];
        NSLog(@"decoded data: %@", respdata);
        NSData * decrypted = [crypto decryptData:respdata];
        NSLog(@"decrypted data: %@", decrypted);
        org::umit::icm::mobile::proto::TestSuggestionResponse rar;
        rar.ParseFromArray((const void*)[decrypted bytes], [decrypted length]);
        org::umit::icm::mobile::proto::ResponseHeader header = rar.header();
        NSLog(@"Got report response: curversionno=%d curtestversiono=%d", header.currentversionno(), header.currenttestversionno());
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Suggest Service" 
                                                        message:@"Service suggestion added successfully! Make sure you subscribe to receive the service status once it is tested."
                                                       delegate:nil 
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        
    } onError:^(NSError *error) {
        
        DLog(@"%@", error);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Suggest Service" 
                                                        message:error.localizedDescription
                                                       delegate:nil 
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
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
        NSData* respdata = [NSData dataWithBase64EncodedString: resp];
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
        NSData* respdata = [NSData dataWithBase64EncodedString: resp];
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
