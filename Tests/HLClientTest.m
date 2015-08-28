/*
 Copyright 2014-2015 Heroic Labs
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <Expecta/Expecta.h>
#import "HLClient.h"
#import "HLSessionClient.h"
#import "HLPing.h"
#import "HLServer.h"
#import "HLGame.h"
#import "HLAchievement.h"
#import "HLLeaderboard.h"

@interface HLClientTest : XCTestCase
@end

@implementation HLClientTest
{
    XCTestExpectation* expectation;
    void (^errorHandler)(NSError *error);
}
id apikey = @"";
id deviceId = @"";
id heroicEmail = @"";
id heroicPassword = @"";
id heroicName = @"";
id leaderboardId = @"5141dd1c31354741967e77f409ce755e";
id achievementId = @"ec6764eadd274b9298887de9f5da0a5e";

+ (void)setUp {
    [HLClient setApiKey:apikey];
}

- (void)checkError:(NSError*) error
{
    XCTAssertTrue(error == nil, @"%@", [self convertErrorToString:error]);
}

- (id)convertErrorToString:(NSError*) error
{
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:[[error userInfo] objectForKey:@"com.alamofire.serialization.response.error.data"]
                                                         options:kNilOptions
                                                           error:nil];
    
    return [NSString stringWithFormat:@"%@ %@: %@ %@", [json objectForKey:@"status"], [json objectForKey:@"message"], [[json objectForKey:@"request"] objectForKey:@"method"], [[error userInfo] objectForKey:@"NSErrorFailingURLKey"]];
}

- (void)setUp {
    [super setUp];
    expectation = [self expectationWithDescription:@"expectation"];
    
    __block HLClientTest *blockSelf = self;
    errorHandler = ^(NSError *error) {
        [blockSelf checkError:error];
    };
}

- (void)checkPromise:(PMKPromise*)promise
           withBlock:(void(^)(id data))testBlock
      withErrorBlock:(void(^)(NSError *error))errorBlock
{
    promise.then(^(id data) {
        expect(data).toNot.beNil();
        return data;
    }).then(testBlock).catch(errorBlock).finally(^() {
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void)testPing {
    NSTimeInterval currentTimestamp = [[NSDate date] timeIntervalSince1970];
    [self checkPromise:[HLClient ping] withBlock:(^(HLPing* data) {
        expect([data time]).toNot.beLessThan(currentTimestamp);
        expect([data time]).to.beGreaterThan(currentTimestamp);
    }) withErrorBlock:errorHandler];
}

- (void)testServerInfo {
    NSTimeInterval currentTimestamp = [[NSDate date] timeIntervalSince1970];
    [self checkPromise:[HLClient getServerInfo] withBlock:(^(HLServer* data) {
        expect([data time]).to.beGreaterThan(currentTimestamp);
    }) withErrorBlock:errorHandler];
}

- (void)testGameDetails {
    [self checkPromise:[HLClient getGameDetails] withBlock:(^(HLGame* data) {
        expect([data name]).to.match(@"Integration Test Game");
        expect([data desc]).to.match(@"Test Game for Integration Test Suites");
        expect([data createdAt]).to.equal(1442057489062);
        expect([data updatedAt]).to.beGreaterThanOrEqualTo(1442057489062);
    }) withErrorBlock:errorHandler];
}

- (void)AllAchievements {
    [self checkPromise:[HLClient getAchievements] withBlock:(^(NSArray* data) {
        expect([data count]).to.beGreaterThan(0);
        HLAchievement* a = [data objectAtIndex:0];
        expect([a publicId]).to.match(@"XERAxEvON");
        expect([a name]).to.match(@"Achievement Test");
        expect([a desc]).to.match(@"Achievement Test Description");
        expect([a type]).to.equal(INCREMENTAL);
        expect([a points]).to.equal(20);
        expect([a state]).to.equal(SECRET);
        expect([a requiredCount]).to.equal(5);
    }) withErrorBlock:errorHandler];
}

- (void)testAllLeaderboards {
    [self checkPromise:[HLClient getLeaderboards] withBlock:(^(NSArray* data) {
        expect([data count]).to.equal(1);
    }) withErrorBlock:errorHandler];
}

- (void)testLeaderboardData {
    [self checkPromise:[HLClient getLeaderboardWithId:leaderboardId] withBlock:(^(HLLeaderboard* l) {
        expect([l leaderboardId]).to.match(leaderboardId);
        expect([l name]).to.match(@"Test Leaderboard");
        expect([l publicId]).to.match(@"lkp7AW2oe");
        expect([l sort]).to.equal(DESCENDING);
        expect([l type]).to.equal(RANKING);
        expect([l displayHint]).to.match(@"Display Hint");
        expect([l tags]).to.beSupersetOf(@[@"score", @"tag", @"test"]);
        expect([l scoreLimit]).to.equal(99);
        
        HLLeaderboardReset* r = [l reset];
        expect([r type]).to.equal(MONTHLY);
        expect([r utcHour]).to.equal(10);
        expect([r dayOfMonth]).to.equal(5);
        
    }) withErrorBlock:errorHandler];
}

- (void)testLoginAnonymously {
    [self checkPromise:[HLClient loginAnonymouslyWith:deviceId] withBlock:(^(HLSessionClient* session) {
        expect([session getGamerToken]).toNot.beNil;
    }) withErrorBlock:errorHandler];
}

- (void)testLoginOrCreateHeroicLabsProfileWith {
    [HLClient loginAnonymouslyWith:deviceId].then(^(HLSessionClient* anonymousSession) {
        [HLClient loginWithEmail:heroicEmail andPassword:heroicPassword andLink:anonymousSession].then(^(HLSessionClient* newSession) {
            expect([newSession getGamerToken]).toNot.beNil;
            [expectation fulfill];
        }).catch(^(NSError* error) {
            NSLog(@"Error Login in Heroic Labs Gamer: %@", [self convertErrorToString: error]);
            NSLog(@"Trying to create a new user");
            
            [HLClient createProfileWithEmail:heroicEmail andPassword:heroicPassword andConfirm:heroicPassword andName:heroicName andLink:anonymousSession].then(^(HLSessionClient* newSession) {
                expect([newSession getGamerToken]).toNot.beNil;
                [expectation fulfill];
            }).catch(^(NSError* error) {
                [self checkError:error];
                [expectation fulfill];
            });
        });
    }).catch(^(NSError* error) {
        [self checkError:error];
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

@end
