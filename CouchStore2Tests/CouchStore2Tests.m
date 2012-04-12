//
//  CouchStore2Tests.m
//  CouchStore2Tests
//
//  Created by Martin Wache on 12.04.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "CouchStore2Tests.h"

@implementation CouchStore2Tests

- (void)setUp
{
    [super setUp];
    //model = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];
    model = [NSManagedObjectModel mergedModelFromBundles:nil];
    NSLog(@"model %@", model);
    coord = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    /*store = [coord addPersistentStoreWithType:@"CouchStore"
     configuration:nil
     URL: [NSURL URLWithString: @"http://ucouchbase.local:5984/storetests"]
     options:nil
     error:NULL];
     */
    // ctx =[[NSManagedObjectContext alloc] init];
    //[ctx setPersistentStoreCoordinator:coord];
    
}

- (void)tearDown
{
    //[ctx release];
    ctx=nil;
    NSError *error = nil;
    STAssertTrue([coord removePersistentStore: store error: &error],
                 @"couldn't remove persistent store: %@",error);
    store = nil;
    //[coord release];
    coord = nil;
    //[model release];
    model = nil;
    //[super tearDown];
    
    [super tearDown];
}

- (void)testExample
{
    STFail(@"Unit tests are not implemented yet in CouchStore2Tests");
}

@end
