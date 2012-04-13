//
//  CouchStore2.m
//  CouchStore2
//
//  Created by Martin Wache on 12.04.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "CouchStore2.h"

#import "AtomicStoreCacheNodeSubclass.h"

@interface CouchDatabase (drop)
- (RESTOperation*) drop;
@end

@implementation CouchDatabase (drop)

- (RESTOperation*) drop {
    return [[self DELETE] start];
}
@end

@implementation CouchStore
+ (BOOL) dropDatabase: (NSURL *)url
{
    CouchServer *server = [[CouchServer alloc] initWithURL:url];
    CouchDatabase *database = [server databaseNamed: @"storeunittest"];
    
    // drop database?
    RESTOperation *op1=[database drop];
    if (![op1 wait]) 
    {
        NSLog( @"Error creating database: %@", op1.error);
    };
    return YES;
}

- (id)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator configurationName:(NSString *)configurationName URL:(NSURL *)url options:(NSDictionary *)options
{
    NSLog(@"initWithPersistentStoreCoordinator");
    self = [super initWithPersistentStoreCoordinator:coordinator configurationName:configurationName URL:url options:options];
    
    // create a dummy file :-(
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *fileURL = [self URL];
	NSString *filePath = [fileURL path];
#if 0
	BOOL success = [fileManager createFileAtPath:filePath contents:nil attributes:nil];
	if (!success) {
		return Nil;
	}
#endif
    
    //CouchServer *server = [[CouchServer alloc] initWithURL:[NSURL URLWithString:@"http://ucouchbase.local:5984"]];
    CouchServer *server = [[CouchServer alloc] initWithURL:url];
    database = [server databaseNamed: @"storeunittest"];
    
    // drop database?
#if 0
    RESTOperation *op1=[database drop];
    if (![op1 wait]) 
    {
        NSLog( @"Error creating database: %@", op1.error);
    };
#endif
    RESTOperation *op=[database create];
    if (![op wait]) 
    {
        NSLog( @"Error creating database: %@", op.error);
    };
    
    [self setMetadata: [NSDictionary dictionaryWithObject: [NSNumber numberWithInteger: 0] forKey: @"lastReferenceObject"]];
    return self;
}

// load:
- (BOOL) load:(NSError **)error
{
    NSLog(@"load");
    NSMutableSet *cacheNodes = [NSMutableSet set];
    NSDictionary *entities = [[[self persistentStoreCoordinator] managedObjectModel] entitiesByName];
    
    CouchQuery *docQuery=[database getAllDocuments];
    for (CouchQueryRow *row in docQuery.rows)
    {
        CouchDocument *couchDoc = row.document;
        NSLog(@"couchDoc %@", couchDoc);
        NSDictionary *props = [couchDoc properties];
        NSEntityDescription *entity = [entities valueForKey:[props valueForKey:@"entity"]];
        NSString *refereceStr = [props valueForKey:@"_id"];
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init ];
        [f setNumberStyle:NSNumberFormatterDecimalStyle];
        NSNumber *referenceId = [f numberFromString:refereceStr];
        NSManagedObjectID *objectID = [self objectIDForEntity: entity referenceObject:referenceId];
        NSLog(@"objectID %@", objectID);
        //NSLog(@"entity %@ refdata %@: %@", [entities valueForKey:[props valueForKey:@"entity"]], referenceId, objectID );
        AtomicStoreCacheNodeSubclass *newNode = [[AtomicStoreCacheNodeSubclass alloc] initWithObjectID:objectID];
        NSMutableDictionary *setProps = [NSMutableDictionary dictionary];
        [setProps addEntriesFromDictionary:[props valueForKey:@"values"]];
        [setProps addEntriesFromDictionary:[props valueForKey:@"relations"]];
        [newNode setPropertyCacheData: setProps];
        NSLog(@"props %@", props);
        [newNode setRevId:[props valueForKey:@"_rev"]];
		[cacheNodes addObject: newNode];
    }
    [self addCacheNodes: cacheNodes];
    NSError *localError = nil;
	for (AtomicStoreCacheNodeSubclass *node in cacheNodes) {
		[node resolvePropertyValues: &localError];
		if (nil != localError) {
			*error = localError;
			return NO;
		}
	}
	
    return YES;
}

//- (BOOL) loadMetadata:(NSError **)error
//{
//    NSLog(@"loadMetadata");
//    return NO;
//}

- (id)newReferenceObjectForManagedObject:(NSManagedObject *)managedObject
{
    NSLog(@"newReferenceObjectForManagedObject");
    static int count=0;
    count++;
    NSNumber *refObject = [NSNumber numberWithInt:count];
    return refObject;
}

- (NSDictionary *) nodeToDocProperty:(id)node
{
    
    NSMutableDictionary *props= [NSMutableDictionary dictionary];
    
    NSString *rev=[node revId];
    if (rev != nil)
    {
        [props setValue:rev forKey:@"_rev"];
    }
    
    [props setValue:[[node entity] name] forKey:@"entity"];
    
    NSMutableDictionary *values= [NSMutableDictionary dictionary];
    NSDictionary *attributeDescriptions = [[node entity] attributesByName];
    for (NSString *name in attributeDescriptions)
    {
        NSLog(@"attribute name %@", name);
        id value = [node valueForKey:name];
        
        // FIXME type conversions?
        [values setValue:value forKey:name];
    }
    [props setValue:values forKey:@"values"];
    
    NSMutableDictionary *rels= [NSMutableDictionary dictionary];
    NSDictionary *relationships = [[node entity] relationshipsByName];
    for (NSString *relName in relationships)
    {
        NSLog(@"relationship name %@", relName);
        id dest = [node valueForKey:relName];
        NSRelationshipDescription *desc = [relationships valueForKey:relName];
        if ([desc isToMany])
        {
            NSLog(@"toMany relation");
            NSMutableArray *many= [NSMutableArray array];
            for (NSManagedObject *manyDest in [node valueForKey:relName])
            {
                [many addObject:[NSArray arrayWithObjects:[[manyDest entity] name], [self referenceObjectForObjectID:[manyDest objectID]], nil]];
            }
            [rels setValue:many forKey:relName];
        }
        else
        {
            NSLog(@"single relation");
            NSMutableArray *destInfo =[NSMutableArray array];
            if (dest != nil)
            {
                
                [destInfo addObject:[NSArray arrayWithObjects:[[dest entity] name], [self referenceObjectForObjectID:[dest objectID]], nil]];
                [rels setValue: destInfo forKey:relName];
            }
            else
                [rels setValue:destInfo forKey:relName];
        }
    }
    [props setValue:rels forKey:@"relations"];
    
    return props;
}

// save:
- (BOOL) save:(NSError **)error
{
    NSLog(@"save");
    NSSet *cacheNodes = [ self cacheNodes ];
    for (AtomicStoreCacheNodeSubclass *node in cacheNodes) {
        NSLog(@"save cacheNode: ");
        NSNumber *refObj = [self referenceObjectForObjectID:[node objectID]];
        
        CouchDocument *doc=[database documentWithID:[refObj stringValue]];
        RESTOperation *op=[doc putProperties:[self nodeToDocProperty:node]];
        if (![op wait])
        {
            NSLog(@"error saving %@: %@", refObj, op.error);
        }
        
    }
    return YES; //FIXME report errors
}

- (NSAtomicStoreCacheNode *)newCacheNodeForManagedObject:(NSManagedObject *)managedObject;
{
    NSLog(@"newCacheNodeForManagedObject ");
    AtomicStoreCacheNodeSubclass *newNode = [[AtomicStoreCacheNodeSubclass alloc] initWithObjectID: [managedObject objectID]];
	[newNode setPropertyCacheData: [self getPropertyCacheDataForKVCCompliantObject: managedObject]];
	return newNode;
}

- (void)updateCacheNode:(NSAtomicStoreCacheNode *)node fromManagedObject:(NSManagedObject *)managedObject
{
    NSLog(@"updateCacheNode ");
    [(AtomicStoreCacheNodeSubclass *)node setPropertyCache: nil];
	[(AtomicStoreCacheNodeSubclass *)node setPropertyCacheData: [self getPropertyCacheDataForKVCCompliantObject: managedObject]];
    //    AtomicStoreCacheNodeSubclass *newNode = [[ AtomicStoreCacheNodeSubclass alloc] initWithObjectID:[managedObject objectID]];
    //    [newNode setPropertyCacheData: [self getPropertyCacheDataForKVCCompliantObject: managedObject]];
}


- (NSString *)type 
{
    NSLog(@"type");
    return @"CouchStore";
}

- (NSString *) identifier
{
    NSLog(@"identifier: %@", store_identifier);
    //return @"couch_store_test";
    return store_identifier;
}

- (void)setIdentifier:(NSString *)identifier
{
    NSLog(@"setIdentifier %@", identifier);
    store_identifier = identifier;
}


// FIXME
/*- (NSDictionary *)metadata
 {
 NSLog(@"metadata");
 NSMutableDictionary *metadata = [NSMutableDictionary dictionary];
 [metadata setObject:@"test" forKey:@"blah"];
 return metadata;
 }
 */
+ (BOOL)setMetadata:(NSDictionary *)metadata forPersistentStoreWithURL:(NSURL *)url error:(NSError **)error
{
    NSLog(@"setMetadata");
    return NO;
}

+ (NSDictionary*)metadataForPersistentStoreWithURL:(NSURL *)url error:(NSError **)error
{
    NSLog(@"metadataForPersistentStoreWithURL");
    return Nil;
}

/*
 Copied from AtomicStoreSubclass.m
 
 * getPropertyCacheDataForKVCCompliantObject:
 
 Get the external representation of an object from either a managedObject or a cacheNode.
 This takes advantage of the fact that managed objects and cache nodes are very similar:  
 both must respond to valueForKey:attributeName with a valid attribute value, and  
 both must respond to valueForKey:relationshipName with an object (or set of objects,
 in the case of a toMany relationship) which do likewise
 */
- (NSDictionary *)getPropertyCacheDataForKVCCompliantObject:(id)somethingRespondingToValueForKey {
	NSMutableDictionary *newValues = [NSMutableDictionary dictionary];
	
	NSDictionary *attributeDescriptions = [[somethingRespondingToValueForKey entity] attributesByName];
	
	for (NSString *attributeName in attributeDescriptions) {
		NSAttributeDescription *attributeDescription = [attributeDescriptions valueForKey: attributeName];
		id attributeValue = [somethingRespondingToValueForKey valueForKey: attributeName];
		if (NSTransformableAttributeType == [attributeDescription attributeType]) {
			NSString *transformerName = [attributeDescription valueTransformerName];
			attributeValue = (nil == transformerName) ? [[NSValueTransformer valueTransformerForName: NSKeyedUnarchiveFromDataTransformerName] reverseTransformedValue: attributeValue] : [[NSValueTransformer valueTransformerForName: transformerName] transformedValue: attributeValue];
		}
		[newValues setValue: attributeValue forKey: attributeName];
	}
	
	NSDictionary *relationshipDescriptions = [[somethingRespondingToValueForKey entity] relationshipsByName];
	for (NSString *relationshipName in relationshipDescriptions) {
		NSRelationshipDescription *relationshipDescription = [relationshipDescriptions valueForKey: relationshipName];
		NSMutableSet *destinationInfos = [NSMutableSet set];
		
		if (![relationshipDescription isToMany]) {
			id destinationObject = [somethingRespondingToValueForKey valueForKey: relationshipName];
			if (nil != destinationObject) {
				[destinationInfos addObject: [NSArray arrayWithObjects: [[destinationObject entity] name], [self referenceObjectForObjectID: [destinationObject objectID]], nil]];
			}
		} else {
			for (NSManagedObject *destinationObject in [somethingRespondingToValueForKey valueForKey: relationshipName]) {
				[destinationInfos addObject: [NSArray arrayWithObjects: [[destinationObject entity] name], [self referenceObjectForObjectID: [destinationObject objectID]], nil]];
			}
		}
		
		[newValues setValue: destinationInfos forKey: relationshipName];
	}
	
	return newValues;
}
@end
