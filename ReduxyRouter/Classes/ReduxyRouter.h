//
//  ReduxyRouter.h
//  Reduxy_Example
//
//  Created by yjkim on 02/05/2018.
//  Copyright © 2018 skyofdwarf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ReduxyRoutable.h"

@import Reduxy;


typedef id<ReduxyRoutable> (^RouterTargetCreator)(id<ReduxyRoutable> from, NSDictionary *context);
typedef void (^RouterRoute)(id<ReduxyRoutable> from, NSDictionary<NSString *, id<ReduxyRoutable>> *to, NSDictionary *context);
typedef void (^RouterUnroute)(id<ReduxyRoutable> from);

#pragma mark - Router

@interface ReduxyRouter : NSObject
@property (class, strong, nonatomic, readonly) NSString *stateKey;


/**
 routes auto-way action
 */
@property (assign, nonatomic) BOOL routesAutoway;

+ (instancetype)shared;

#pragma mark - store

- (void)attachStore:(id<ReduxyStore>)store;

#pragma mark - reducer

- (ReduxyReducer)reducer;

#pragma mark - target

- (NSArray<NSString *> *)targetsForPath:(NSString *)path;
- (NSDictionary *)createTargetsForPath:(NSString *)path from:(id<ReduxyRoutable>)from context:(NSDictionary *)context;

#pragma mark - routing

- (void)addTarget:(NSString *)name creator:(RouterTargetCreator)creator;

- (void)addPath:(NSString *)path target:(NSString *)target route:(RouterRoute)route unroute:(RouterUnroute)unroute;
- (void)addPath:(NSString *)path targets:(NSArray<NSString *> *)targets route:(RouterRoute)route unroute:(RouterUnroute)unroute;

- (void)removeTarget:(NSString *)name;
- (void)removePath:(NSString *)path;

- (UIWindow *)startWithPath:(NSString *)path;
    
- (void)routePath:(NSString *)path from:(id<ReduxyRoutable>)from context:(NSDictionary *)context;
- (void)routeTargets:(NSArray *)targets;
    
- (void)unroutePathFrom:(id<ReduxyRoutable>)from;


@end




