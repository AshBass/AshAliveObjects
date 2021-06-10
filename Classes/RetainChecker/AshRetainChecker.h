//
//  AshRetainChecker.h
//  FlexTest
//
//  Created by crimsonho on 2021/3/26.
//

#import "AshRetainCheckerModel.h"

@interface AshRetainChecker : NSObject

- (NSArray*)findRetainWithObjectModel:(AshRetainCheckerObjectModel*)objectModel className:(NSString*)className;

@end
