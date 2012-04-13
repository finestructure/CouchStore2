//
//  CouchStore2Tests.m
//  CouchStore2Tests
//
//  Created by Martin Wache on 12.04.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "CouchStore2Tests.h"
#import "CouchStore2.h"

@implementation CouchStore2Tests

- (void)setUp
{
    [super setUp];
    //model = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];
    //model = [NSManagedObjectModel mergedModelFromBundles:nil];
    model = [[NSManagedObjectModel alloc] init];
    
    //NSEntityDescription *entity = [NSEntityDescription entityForName:@"TypeTestingEntity" inManagedObjectContext:ctx];
    entity = [[NSEntityDescription alloc] init];
    [entity setName:@"testData"];
    [entity setManagedObjectClassName:@"testData"];
    NSMutableArray *testProperties = [NSMutableArray array];
    
    NSAttributeDescription *testDataAttribute = [[NSAttributeDescription alloc] init];	
	[testProperties addObject:testDataAttribute];	
	[testDataAttribute setName:@"binaryValue"];
	[testDataAttribute setAttributeType:NSStringAttributeType];
	[testDataAttribute setOptional:NO];
    
    NSAttributeDescription *testBoolAttribute = [[NSAttributeDescription alloc] init];	
	[testProperties addObject:testBoolAttribute];	
	[testDataAttribute setName:@"boolValue"];
	[testDataAttribute setAttributeType:NSStringAttributeType];
	[testDataAttribute setOptional:NO];
    
    [model setEntities:[NSArray arrayWithObject:entity]];

    
    NSLog(@"model %@", model);
    [NSPersistentStoreCoordinator registerStoreClass:[CouchStore class] forStoreType:@"CouchStore"];
    coord = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    NSError *error=nil;
    store = [coord addPersistentStoreWithType:@"CouchStore"
     configuration:nil
     URL:[NSURL URLWithString: @"http://ucouchbase.local:5984/storeunittests"]
     options:nil
     error:&error];
    NSLog(@"error %@", error);
    NSLog(@"store %@", store);
   
     ctx =[[NSManagedObjectContext alloc] init];
    [ctx setPersistentStoreCoordinator:coord];
    
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

- (void)testBasicRead {
//[self addTestStoreToCoordinator:coord];
//NSManagedObjectContext *context = [[NSManagedObjectContext alloc] init];
//[context setPersistentStoreCoordinator:coord];

  NSFetchRequest *request = [[NSFetchRequest alloc] init];
  [request setEntity:entity];

NSArray *results = [ctx executeFetchRequest:request error:nil];
STAssertTrue(([results count] == 0), @"Exactly zero TypeTestingEntities should have been fetched");

id testObject = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:ctx];

NSData *testData = [@"binary test data" dataUsingEncoding:NSASCIIStringEncoding];
[testObject setValue:testData forKey:@"binaryValue"];

NSNumber *testBoolValue = [NSNumber numberWithBool:1];
[testObject setValue:testBoolValue forKey:@"boolValue"];
/*
NSDate *testDateValue = [NSDate dateWithNaturalLanguageString:@"10/10/2006"];
[testObject setValue:testDateValue forKey:@"dateValue"];

NSDecimalNumber *testDecimal = [NSDecimalNumber decimalNumberWithString:@"10.5"];
[testObject setValue:testDecimal forKey:@"decimalValue"];

NSNumber *testDoubleValue = [NSNumber numberWithDouble:5.005];
[testObject setValue:testDoubleValue forKey:@"doubleValue"];

NSNumber *testFloatValue = [NSNumber numberWithFloat:0.005];
[testObject setValue:testFloatValue forKey:@"floatValue"];

NSNumber *testIntValue = [NSNumber numberWithInt:50];
[testObject setValue:testIntValue forKey:@"intValue"];

NSNumber *testLongValue = [NSNumber numberWithLong:500];
[testObject setValue:testLongValue forKey:@"longValue"];

NSNumber *testShortValue = [NSNumber numberWithShort:5];
[testObject setValue:testShortValue forKey:@"shortValue"];

NSNumber *testStringValue = @"test string value";
[testObject setValue:testStringValue forKey:@"stringValue"];

[testObject setValue:@"test transient string value" forKey:@"transientString"];
*/
NSError *error = nil;
STAssertTrue([ctx save:&error], @"Couldn't save test object because of %@", error);

//
// bring up a second stack to check what we saved
//
NSPersistentStoreCoordinator *stack2 = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
//[self addTestStoreToCoordinator:stack2];
NSManagedObjectContext *context2 = [[NSManagedObjectContext alloc] init];
[context2 setPersistentStoreCoordinator:stack2];

NSArray *results2 = [context2 executeFetchRequest:request error:nil];
STAssertTrue(([results2 count] == 1), @"Exactly 1 TypeTestingEntities should have been fetched");
id testObject2 = [results2 objectAtIndex:0];

STAssertEqualObjects([testObject2 valueForKey:@"binaryValue"], testData, @"Stored and retreived data not equal");
STAssertEqualObjects([testObject2 valueForKey:@"boolValue"], testBoolValue, @"Stored and retreived boolValue not equal");
/*STAssertEqualObjects([testObject2 valueForKey:@"dateValue"], testDateValue, @"Stored and retreived dateValue not equal");
STAssertEqualObjects([testObject2 valueForKey:@"decimalValue"], testDecimal, @"Stored and retreived decimalValue not equal");
STAssertEqualObjects([testObject2 valueForKey:@"doubleValue"], testDoubleValue, @"Stored and retreived doubleValue not equal");
STAssertEqualObjects([testObject2 valueForKey:@"floatValue"], testFloatValue, @"Stored and retreived floatValue not equal");
STAssertEqualObjects([testObject2 valueForKey:@"intValue"], testIntValue, @"Stored and retreived intValue not equal");
STAssertEqualObjects([testObject2 valueForKey:@"longValue"], testLongValue, @"Stored and retreived longValue not equal");
STAssertEqualObjects([testObject2 valueForKey:@"shortValue"], testShortValue, @"Stored and retreived shortValue not equal");
STAssertEqualObjects([testObject2 valueForKey:@"stringValue"], testStringValue, @"Stored and retreived stringValue not equal");
STAssertTrue(([testObject2 valueForKey:@"transientString"] == nil), @"transient string value should not have been stored");        
*/
[context2 deleteObject:testObject2];
STAssertTrue([context2 save:&error], @"Couldn't save deletion of test object because of %@", error);

//[context2 release];
//[stack2 release];

}

- (void)testExample
{
   // STFail(@"Unit tests are not implemented yet in CouchStore2Tests");
}

@end
