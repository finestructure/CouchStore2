//
//  CouchStore2Tests.h
//  CouchStore2Tests
//
//  Created by Martin Wache on 12.04.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@interface CouchStore2Tests : SenTestCase {
  NSPersistentStoreCoordinator *coord;
  NSManagedObjectContext *ctx;
  NSManagedObjectModel *model;
  NSPersistentStore *store;
}
@end
