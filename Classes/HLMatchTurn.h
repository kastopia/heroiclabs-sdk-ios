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

#import <Foundation/Foundation.h>
#import "HLJSONSerialisableProtocol.h"

/**
 Represents a response containing Heroic Labs global and/or server instance info.
 */
@interface HLMatchTurn : NSObject <HLJSONSerialisableProtocol>

/** Turn type */
@property(readonly) NSString* type;

/** Current turn number */
@property(readonly) NSNumber* turnNumber;

/** Name of gamer for this turn */
@property(readonly) NSString* gamer;

/** Data stored for this turn */
@property(readonly) NSString* data;

/** When the match was created */
@property(readonly) NSNumber* createdAt;

@end