//
//  CouchStore2.h
//  CouchStore2
//
//  Created by Martin Wache on 12.04.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CouchCocoa/CouchCocoa.h>

@interface CouchStore : NSAtomicStore {
    NSString *store_identifier;
    CouchDatabase *database;
    
}
- (id)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator configurationName:(NSString *)configurationName URL:(NSURL*)url options:(NSDictionary *)options;

// required overrides from NSAtomicStore
- (BOOL) load:(NSError **)error;
- (BOOL) save:(NSError **)error;

- (id) newReferenceObjectForManagedObject:(NSManagedObject *)managedObject;
- (NSAtomicStoreCacheNode *)newCacheNodeForManagedObject:(NSManagedObject *)managedObject;
- (void)updateCacheNode:(NSAtomicStoreCacheNode *)node fromManagedObject:(NSManagedObject *)managedObject;

// required overrides from NSPersistentStore
- (NSString *) type;
- (NSString *) identifier;
- (void) setIdentifier:(NSString *)identifier;
//- (NSDictionary *)metadata;
+ (NSDictionary *)metadataForPersistentStoreWithURL:(NSURL *)url error:(NSError **)error;
+ (BOOL)setMetadata:(NSDictionary *)metadata forPersistentStoreWithURL:(NSURL *)url error:(NSError **)error;


- (NSDictionary *)getPropertyCacheDataForKVCCompliantObject:(id)somethingRespondingToValueForKey;
@end
