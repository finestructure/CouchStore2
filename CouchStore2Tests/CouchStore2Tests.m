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
    // first, make sure there are no left overt things in the db
    //[CouchStore dropDatabase:[NSURL URLWithString: @"http://ucouchbase.local:5984"]];

    model = [[NSManagedObjectModel alloc] init];
    
    entity = [[NSEntityDescription alloc] init];
    [entity setName:@"testData"];
    [entity setManagedObjectClassName:@"testData"];
    NSMutableArray *testProperties = [NSMutableArray array];
    
    /*
    // fails with "invalid type in JSON write..."
    NSAttributeDescription *testDataAttribute = [[NSAttributeDescription alloc] init];	
	[testProperties addObject:testDataAttribute];	
	[testDataAttribute setName:@"binaryValue"];
	[testDataAttribute setAttributeType:NSBinaryDataAttributeType];
	[testDataAttribute setOptional:NO];
    */
    
    NSAttributeDescription *testBoolAttribute = [[NSAttributeDescription alloc] init];	
	[testProperties addObject:testBoolAttribute];	
	[testBoolAttribute setName:@"boolValue"];
	[testBoolAttribute setAttributeType:NSBooleanAttributeType];
	[testBoolAttribute setOptional:YES];

    NSAttributeDescription *testStringAttribute = [[NSAttributeDescription alloc] init];	
	[testProperties addObject:testStringAttribute];	
	[testStringAttribute setName:@"stringValue"];
	[testStringAttribute setAttributeType:NSStringAttributeType];
	[testStringAttribute setOptional:YES];
   
    /*
    // fails with "invalid type in JSON write..."
    NSAttributeDescription *testDateAttribute = [[NSAttributeDescription alloc] init];	
	[testProperties addObject:testDateAttribute];	
	[testDateAttribute setName:@"dateValue"];
	[testDateAttribute setAttributeType:NSDateAttributeType];
	[testDateAttribute setOptional:YES];
     */

    NSAttributeDescription *testDecimalAttribute = [[NSAttributeDescription alloc] init];	
	[testProperties addObject:testDecimalAttribute];	
	[testDecimalAttribute setName:@"decimalValue"];
	[testDecimalAttribute setAttributeType:NSDecimalAttributeType];
	[testDecimalAttribute setOptional:YES];
    
    NSAttributeDescription *testDoubleAttribute = [[NSAttributeDescription alloc] init];	
	[testProperties addObject:testDoubleAttribute];	
	[testDoubleAttribute setName:@"doubleValue"];
	[testDoubleAttribute setAttributeType:NSDoubleAttributeType];
	[testDoubleAttribute setOptional:YES];
    
    
    NSAttributeDescription *testFloatAttribute = [[NSAttributeDescription alloc] init];	
    [testProperties addObject:testFloatAttribute];	
    [testFloatAttribute setName:@"floatValue"];
    [testFloatAttribute setAttributeType:NSFloatAttributeType];
    [testFloatAttribute setOptional:YES];

    NSAttributeDescription *testIntAttribute = [[NSAttributeDescription alloc] init];	
	[testProperties addObject:testIntAttribute];	
	[testIntAttribute setName:@"intValue"];
	[testIntAttribute setAttributeType:NSInteger16AttributeType];
	[testIntAttribute setOptional:YES];

    NSAttributeDescription *testLongAttribute = [[NSAttributeDescription alloc] init];	
	[testProperties addObject:testLongAttribute];	
	[testLongAttribute setName:@"longValue"];
	[testLongAttribute setAttributeType:NSInteger64AttributeType];
	[testLongAttribute setOptional:YES];

    NSAttributeDescription *testShortAttribute = [[NSAttributeDescription alloc] init];	
	[testProperties addObject:testShortAttribute];	
	[testShortAttribute setName:@"shortValue"];
	[testShortAttribute setAttributeType:NSInteger16AttributeType];
	[testShortAttribute setOptional:YES];

    [entity setProperties:testProperties];
    
    [model setEntities:[NSArray arrayWithObject:entity]];

    
    [NSPersistentStoreCoordinator registerStoreClass:[CouchStore class] forStoreType:@"CouchStore"];
    coord = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    NSError *error=nil;
    store = [coord addPersistentStoreWithType:@"CouchStore"
                                configuration:nil
                                          URL:[NSURL URLWithString: @"http://ucouchbase.local:5984"]
                                      options:nil
                                        error:&error];
    
    ctx =[[NSManagedObjectContext alloc] init];
    [ctx setPersistentStoreCoordinator:coord];
    
}

- (void)tearDown
{
    ctx=nil;
    NSError *error = nil;
    STAssertTrue([coord removePersistentStore: store error: &error],
                 @"couldn't remove persistent store: %@",error);
    store = nil;
    coord = nil;
    model = nil;
    
    [CouchStore dropDatabase:[NSURL URLWithString: @"http://ucouchbase.local:5984"]];
    
    [super tearDown];
}

- (NSManagedObjectContext*) generateStack
{
   NSPersistentStoreCoordinator *stack2 = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
   NSManagedObjectContext *context2 = [[NSManagedObjectContext alloc] init];
   [context2 setPersistentStoreCoordinator:stack2];
   [stack2 addPersistentStoreWithType:@"CouchStore"
                        configuration:nil
                                  URL:[NSURL URLWithString: @"http://ucouchbase.local:5984"]
                              options:nil
                                error:nil];
   
    return context2;
}

- (void)testBasicRead {    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    
    NSArray *results = [ctx executeFetchRequest:request error:nil];
    STAssertTrue(([results count] == 0), @"Exactly zero TypeTestingEntities should have been fetched");
    
    id testObject = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:ctx];
    
    /*
    NSData *testData = [@"binary test data" dataUsingEncoding:NSASCIIStringEncoding];
    [testObject setValue:testData forKey:@"binaryValue"];
     */
    
    NSNumber *testBoolValue = [NSNumber numberWithBool:1];
    [testObject setValue:testBoolValue forKey:@"boolValue"];

    /*
    NSDate *testDateValue = [NSDate dateWithNaturalLanguageString:@"10/10/2006"];
    [testObject setValue:testDateValue forKey:@"dateValue"];
     */
    
    NSDecimalNumber *testDecimal = [NSDecimalNumber decimalNumberWithString:@"10.00000000005"];
    [testObject setValue:testDecimal forKey:@"decimalValue"];
    
    NSNumber *testDoubleValue = [NSNumber numberWithDouble:5.000000001];
    [testObject setValue:testDoubleValue forKey:@"doubleValue"];
    
    NSNumber *testFloatValue = [NSNumber numberWithFloat:5.000005];
    [testObject setValue:testFloatValue forKey:@"floatValue"];
    
    NSNumber *testIntValue = [NSNumber numberWithInt:5000];
    [testObject setValue:testIntValue forKey:@"intValue"];
    
    NSNumber *testLongValue = [NSNumber numberWithLong:5000000];
    [testObject setValue:testLongValue forKey:@"longValue"];
    
    NSNumber *testShortValue = [NSNumber numberWithShort:5];
    [testObject setValue:testShortValue forKey:@"shortValue"];

    NSString *testStringValue = @"test string value";
    [testObject setValue:testStringValue forKey:@"stringValue"];
    /*
     [testObject setValue:@"test transient string value" forKey:@"transientString"];
     */
    NSError *error = nil;
    STAssertTrue([ctx save:&error], @"Couldn't save test object because of %@", error);
    
    //
    // bring up a second stack to check what we saved
    //
#if 1
    NSLog(@"bring up a second stack");
    /*
    NSPersistentStoreCoordinator *stack2 = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    NSManagedObjectContext *context2 = [[NSManagedObjectContext alloc] init];
    [context2 setPersistentStoreCoordinator:stack2];
    [stack2 addPersistentStoreWithType:@"CouchStore"
                                configuration:nil
                                          URL:[NSURL URLWithString: @"http://ucouchbase.local:5984"]
                                      options:nil
                                        error:nil];
     */
    NSManagedObjectContext *context2=[self generateStack];
    
    NSArray *results2 = [context2 executeFetchRequest:request error:nil];
    STAssertTrue(([results2 count] == 1), @"Exactly 1 TypeTestingEntities should have been fetched");
    id testObject2 = [results2 objectAtIndex:0];
    
    //STAssertEqualObjects([testObject2 valueForKey:@"binaryValue"], testData, @"Stored and retreived data not equal");
    
    STAssertEqualObjects([testObject2 valueForKey:@"boolValue"], testBoolValue, @"Stored and retreived boolValue not equal");
    // STAssertEqualObjects([testObject2 valueForKey:@"dateValue"], testDateValue, @"Stored and retreived dateValue not equal");
    STAssertEqualObjects([testObject2 valueForKey:@"decimalValue"], testDecimal, @"Stored and retreived decimalValue not equal");
    STAssertEqualObjects([testObject2 valueForKey:@"doubleValue"], testDoubleValue, @"Stored and retreived doubleValue not equal");
    STAssertEqualObjects([testObject2 valueForKey:@"floatValue"], testFloatValue, @"Stored and retreived floatValue not equal");
    STAssertEqualObjects([testObject2 valueForKey:@"intValue"], testIntValue, @"Stored and retreived intValue not equal");
    STAssertEqualObjects([testObject2 valueForKey:@"longValue"], testLongValue, @"Stored and retreived longValue not equal");
    STAssertEqualObjects([testObject2 valueForKey:@"shortValue"], testShortValue, @"Stored and retreived shortValue not equal");
    STAssertEqualObjects([testObject2 valueForKey:@"stringValue"], testStringValue, @"Stored and retreived stringValue not equal");
    /*
     STAssertTrue(([testObject2 valueForKey:@"transientString"] == nil), @"transient string value should not have been stored");        
     */
    [context2 deleteObject:testObject2];
    STAssertTrue([context2 save:&error], @"Couldn't save deletion of test object because of %@", error);
#endif
}

- (void)testWriteReadWrite
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    
    NSArray *results = [ctx executeFetchRequest:request error:nil];
    STAssertTrue(([results count] == 0), @"Exactly zero TypeTestingEntities should have been fetched");
    
    id testObject = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:ctx];
    
    NSString *testStringValue = @"test string value";
    [testObject setValue:testStringValue forKey:@"stringValue"];
    NSError *error = nil;
    STAssertTrue([ctx save:&error], @"Couldn't save test object because of %@", error);
    
    // read back
    NSManagedObjectContext *context2=[self generateStack];
    
    NSArray *results2 = [context2 executeFetchRequest:request error:nil];
    STAssertTrue(([results2 count] == 1), @"Exactly 1 TypeTestingEntities should have been fetched");
    id testObject2 = [results2 objectAtIndex:0];
    
    STAssertEqualObjects([testObject2 valueForKey:@"stringValue"], testStringValue, @"Stored and retreived stringValue not equal");
    
    // change and write again
    testStringValue = @"changed test string value";
    [testObject2 setValue:testStringValue forKey:@"stringValue"];
    STAssertTrue([context2 save:&error], @"Couldn't save test object because of %@", error);

    // read back once more
    NSManagedObjectContext *context3=[self generateStack];
    NSArray *results3 = [context3 executeFetchRequest:request error:nil];
    STAssertTrue(([results3 count] == 1), @"Exactly 1 TypeTestingEntities should have been fetched");
    id testObject3 = [results3 objectAtIndex:0];
    
    STAssertEqualObjects([testObject3 valueForKey:@"stringValue"], testStringValue, @"Stored and retreived stringValue not equal");
    
}

- (void)testWriteWriteRead
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    
    NSArray *results = [ctx executeFetchRequest:request error:nil];
    STAssertTrue(([results count] == 0), @"Exactly zero TypeTestingEntities should have been fetched");
    
    id testObject = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:ctx];
    
    NSString *testStringValue = @"test string value";
    [testObject setValue:testStringValue forKey:@"stringValue"];
    NSError *error = nil;
    STAssertTrue([ctx save:&error], @"Couldn't save test object because of %@", error);
    
    // read back
    NSManagedObjectContext *context2=[self generateStack];
    
    NSArray *results2 = [context2 executeFetchRequest:request error:nil];
    STAssertTrue(([results2 count] == 1), @"Exactly 1 TypeTestingEntities should have been fetched");
    id testObject2 = [results2 objectAtIndex:0];
    
    STAssertEqualObjects([testObject2 valueForKey:@"stringValue"], testStringValue, @"Stored and retreived stringValue not equal");
    
    // change and write with first context again, needs correct revision id without reading it explicitly
    testStringValue = @"changed test string value";
    [testObject setValue:testStringValue forKey:@"stringValue"];
    STAssertTrue([ctx save:&error], @"Couldn't save test object because of %@", error);
    
    // read back once more
    NSManagedObjectContext *context3=[self generateStack];
    NSArray *results3 = [context3 executeFetchRequest:request error:nil];
    STAssertTrue(([results3 count] == 1), @"Exactly 1 TypeTestingEntities should have been fetched");
    id testObject3 = [results3 objectAtIndex:0];
    
    STAssertEqualObjects([testObject3 valueForKey:@"stringValue"], testStringValue, @"Stored and retreived stringValue not equal");
    
}

- (void)testWriteAddEntityWrite
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    
    NSArray *results = [ctx executeFetchRequest:request error:nil];
    STAssertTrue(([results count] == 0), @"Exactly zero TypeTestingEntities should have been fetched");
    
    id testObject = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:ctx];
    
    NSString *testStringValue = @"test string value";
    [testObject setValue:testStringValue forKey:@"stringValue"];
    NSError *error = nil;
    STAssertTrue([ctx save:&error], @"Couldn't save test object because of %@", error);
    
    // read back
    NSManagedObjectContext *context2=[self generateStack];
    
    NSArray *results2 = [context2 executeFetchRequest:request error:nil];
    STAssertTrue(([results2 count] == 1), @"Exactly 1 TypeTestingEntities should have been fetched");
    id testObject2 = [results2 objectAtIndex:0];
    
    STAssertEqualObjects([testObject2 valueForKey:@"stringValue"], testStringValue, @"Stored and retreived stringValue not equal");
    
    // add another object
    id testSecondObject = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:ctx];

    NSString *testSecondStringValue = @"second test string value";
    [testSecondObject setValue:testSecondStringValue forKey:@"stringValue"];
    STAssertTrue([ctx save:&error], @"Couldn't save test object because of %@", error);
    
    // read back once more
    NSManagedObjectContext *context3=[self generateStack];
    NSArray *results3 = [context3 executeFetchRequest:request error:nil];
    STAssertTrue(([results3 count] == 2), @"Exactly 2 TypeTestingEntities should have been fetched");
    
    id testObject3 = [results3 objectAtIndex:0];
    STAssertEqualObjects([testObject3 valueForKey:@"stringValue"], testStringValue, @"Stored and retreived stringValue not equal");
    
    id testSecondObject3 = [results3 objectAtIndex:1];
    STAssertEqualObjects([testSecondObject3 valueForKey:@"stringValue"], testSecondStringValue, @"Stored and retreived stringValue not equal");
}
@end
