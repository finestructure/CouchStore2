/*
 
 File: AtomicStoreCacheNodeSubclass.m
 
 Abstract: Custom cache nodes used by AtomicStoreSubclass.
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Computer, Inc. ("Apple") in consideration of your agreement to the
 following terms, and your use, installation, modification or
 redistribution of this Apple software constitutes acceptance of these
 terms.  If you do not agree with these terms, please do not use,
 install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Computer,
 Inc. may be used to endorse or promote products derived from the Apple
 Software without specific prior written permission from Apple.  Except
 as expressly stated in this notice, no other rights or licenses, express
 or implied, are granted by Apple herein, including but not limited to
 any patent rights that may be infringed by your derivative works or by
 other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright � 2007 Apple, Inc., All Rights Reserved
 
 */


#import <CoreData/NSAtomicStore.h>
#import <CoreData/NSAtomicStoreCacheNode.h>

#import "AtomicStoreCacheNodeSubclass.h"


@implementation AtomicStoreCacheNodeSubclass

- (id)initWithObjectID:(NSManagedObjectID *)moid {
	if (nil != (self = [super initWithObjectID:moid])) {
		entityDescription = [[self objectID] entity]; // Don't retain, PSC owns it
	}
	return self;
}

- (NSEntityDescription *)entity {
	return entityDescription;
}

// Check to see if we've unpacked our underlying representation; if not, do
// it now
- (id)valueForKey:(NSString *)key {
	if (nil != propertyDataCache) {
		[self resolvePropertyValues: nil];
	}
	return [super valueForKey:key];
}

- (NSString *)description {
	if (nil != propertyDataCache) {
		return [propertyDataCache description];
	}
	return [[self propertyCache] description];
}

- (void)setPropertyCacheData:(NSDictionary *)dictionary {
	if (propertyDataCache != dictionary) {
	//	[dictionary retain];
	//	[propertyDataCache release];
		propertyDataCache = dictionary;
	}
}

- (NSString*)revId
{
    return revId;
}

- (void)setRevId: (NSString*)rev
{
    //if (revId != nil)
    //    [revId release];
    revId = rev;
    //[revId retain];
}

// Unpack the propertyDataCache and set the propertyCache
- (void)resolvePropertyValues:(NSError **)error {
    NSLog(@"resolvePropertyValues");
    
    NSLog(@"propertyDataCache %@", propertyDataCache);
    
 
    
	NSMutableDictionary *newPropertyCache = [NSMutableDictionary dictionary];
	
	NSAtomicStore *store = (NSAtomicStore *)[[self objectID] persistentStore];
	NSDictionary *storeEntities = [[[store persistentStoreCoordinator] managedObjectModel] entitiesByName];
	
	NSDictionary *attributeDescriptions = [entityDescription attributesByName];
	
	for (NSString *attributeName in attributeDescriptions) {
		id attributeValue = [propertyDataCache valueForKey:attributeName];
		if (nil != attributeValue) {
			NSAttributeDescription *attributeDescription = [attributeDescriptions valueForKey:attributeName];
			if (NSTransformableAttributeType == [attributeDescription attributeType]) {
				NSString *transformerName = [attributeDescription valueTransformerName];
				attributeValue = (nil == transformerName) ? [[NSValueTransformer valueTransformerForName: NSKeyedUnarchiveFromDataTransformerName] transformedValue: attributeValue] : [[NSValueTransformer valueTransformerForName: transformerName] reverseTransformedValue: attributeValue];
			}
			[newPropertyCache setValue: attributeValue forKey:attributeName];
		}
	}
	
	NSDictionary *relationshipDescriptions = [entityDescription relationshipsByName];
	
	for (NSString *relationshipName in relationshipDescriptions) {
		NSArray *rawDestinations = [propertyDataCache valueForKey:relationshipName];
		NSMutableArray *destinationNodes = [NSMutableArray array];
		
		for (NSArray *tuple in rawDestinations) {
			if (0 == [tuple count]) {
				NSLog(@"Bad happened.");
			}
			NSString *destinationEntityName = [tuple objectAtIndex: 0];
			id refdata = [tuple objectAtIndex: 1];
			NSManagedObjectID *oid = [store objectIDForEntity:[storeEntities valueForKey: destinationEntityName] referenceObject:refdata];
			NSAtomicStoreCacheNode *destinationNode = [store cacheNodeForObjectID: oid];
			if (nil == destinationNode) {
				NSLog(@"Referential integrity error. Can't find node for ID: %@", oid);
				if (nil != error) {
					*error = [NSError errorWithDomain:@"MyAtomicStoreNodes" code:41 userInfo:[NSDictionary dictionaryWithObject:oid forKey:@"badID"]];
				}
				return;
			}
			[destinationNodes addObject: destinationNode];
		}
		if (![[relationshipDescriptions valueForKey: relationshipName] isToMany]) {
			if (0 < [destinationNodes count]) {
				[newPropertyCache setValue: [destinationNodes objectAtIndex:0] forKey:relationshipName];
			}
		} else {
			[newPropertyCache setValue: destinationNodes forKey:relationshipName];
		}
	}
	
	[self setPropertyCache:newPropertyCache];
	[self setPropertyCacheData:nil];

}

@end
