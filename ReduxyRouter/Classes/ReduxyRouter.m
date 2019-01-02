//
//  ReduxyRouter.m
//  Reduxy_Example
//
//  Created by yjkim on 02/05/2018.
//  Copyright © 2018 skyofdwarf. All rights reserved.
//

#import "ReduxyRouter.h"
#import <objc/runtime.h>

static const NSInteger routePathAssoociationKey = 0;
static const NSInteger routePathInfoAssoociationKey = 0;
static const NSInteger routableTagAssoociationKey = 0;
static const NSInteger routableNameAssoociationKey = 0;

#pragma mark - routable association value

void associateValueToObject(id obj, id value, const void * _Nonnull key) {
    NSCParameterAssert(obj);
    NSCParameterAssert(value);
    
    objc_setAssociatedObject(obj, key, value, OBJC_ASSOCIATION_COPY);
}

id associatedValueToObject(id obj, const void * _Nonnull key) {
    NSCParameterAssert(obj);
    
    return objc_getAssociatedObject(obj, key);
}

void setRoutableName(id<ReduxyRoutable> routable, NSString *name) {
    associateValueToObject(routable, name, &routableNameAssoociationKey);
}

NSString * getRoutableName(id<ReduxyRoutable> routable) {
    id v = associatedValueToObject(routable, &routableNameAssoociationKey);
    if (v) {
        return v;
    }
    else {
        return routable.description;
    }
}

void setRoutableTag(id<ReduxyRoutable>routable, NSString *tag) {
    associateValueToObject(routable, tag, &routableTagAssoociationKey);
}

NSString * getRoutableTag(id<ReduxyRoutable> routable) {
    id r = associatedValueToObject(routable, &routableTagAssoociationKey);
    if (r) {
        return r;
    }
    else {
        NSString *tag = [NSString stringWithFormat:@"%p", routable];
        setRoutableTag(routable, tag);
        return tag;
    }
}

void setRoutablePath(id<ReduxyRoutable>routable, NSString *path) {
    associateValueToObject(routable, path, &routePathAssoociationKey);
}

NSString * getRoutablePath(id<ReduxyRoutable> routable) {
    return associatedValueToObject(routable,  &routePathAssoociationKey);
}

void setRoutablePathInfo(id<ReduxyRoutable>routable, NSDictionary *info) {
    associateValueToObject(routable, info, &routePathInfoAssoociationKey);
}

NSDictionary * getRoutablePathInfo(id<ReduxyRoutable> routable) {
    return associatedValueToObject(routable,  &routePathInfoAssoociationKey);
}

#pragma mark - Array

@interface NSArray<__covariant ObjectType> (util)

- (id)reduce:(id (^)(id acc, ObjectType obj))block initValue:(id)initValue;
- (NSArray *)map:(id (^)(ObjectType obj, NSInteger idx))block;
- (NSInteger)findIndex:(BOOL (^)(id obj, NSInteger idx))block;
@end

@implementation NSArray (util)

- (id)reduce:(id (^)(id acc, id obj))block initValue:(id)initValue {
    id acc = initValue;
    for (id v in self) {
        acc = block(acc, v);
    }
    
    return acc;
}

- (NSArray *)map:(id (^)(id obj, NSInteger idx))block {
    NSMutableArray *ma = @[].mutableCopy;
    
    for (NSInteger i = 0; i < self.count; ++i) {
        id obj = block(self[i], i);
        [ma addObject:obj];
    }
    
    return ma.copy;
}

- (NSInteger)findIndex:(BOOL (^)(id obj, NSInteger idx))block {
    for (NSInteger i = 0; i < self.count; ++i) {
        if (block(self[i], i)) {
            return i;
        }
    }
    return NSNotFound;
}

@end

@interface ReduxyRouter (swizzle)
- (void)viewController:(UIViewController<ReduxyRoutable> *)vc willMoveToParentViewController:(UIViewController *)parent;
- (void)viewController:(UIViewController<ReduxyRoutable> *)vc didMoveToParentViewController:(UIViewController *)parent;
@end

#pragma mark - UIWindow (ReduxyRoutable)

@interface UIWindow (ReduxyRoutable) <ReduxyRoutable>
@end

@implementation UIWindow (ReduxyRoutable)

- (UIView *)window {
    return self;
}

- (UIView *)view {
    return self;
}

@end

#pragma mark - UIViewController (ReduxyRoutable)

@implementation UIViewController (ReduxyRoutable)

- (UIViewController *)vc {
    return self;
}

- (void)reduxyrouter_willMoveToParentViewController:(UIViewController *)parent {
    if ([self conformsToProtocol:@protocol(ReduxyRoutable)]) {
        UIViewController<ReduxyRoutable> *routable = (UIViewController<ReduxyRoutable> *)self;
        [ReduxyRouter.shared viewController:routable willMoveToParentViewController:parent];
    }
}

- (void)reduxyrouter_didMoveToParentViewController:(UIViewController *)parent {
    if ([self conformsToProtocol:@protocol(ReduxyRoutable)]) {
        UIViewController<ReduxyRoutable> *routable = (UIViewController<ReduxyRoutable> *)self;
        [ReduxyRouter.shared viewController:routable didMoveToParentViewController:parent];
    }
}

@end


#pragma mark - ReduxyRouter

@interface ReduxyRouter () <ReduxyStoreSubscriber>
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) id<ReduxyStore> store;

@property (strong, nonatomic) NSMutableDictionary<NSString */*name*/, RouterTargetCreator> *targets;
@property (strong, nonatomic) NSMutableDictionary<NSString */*path*/, id> *paths;

@property (strong, nonatomic) NSMutableArray<NSDictionary *> *pathStack;

@property (strong, nonatomic) NSHashTable *routables;

@end

@implementation ReduxyRouter

static NSString * const _stateKey = @"reduxy.routes";

+ (NSString *)stateKey {
    return _stateKey;
}

+ (void)load {
    raction_add(router.route);
    raction_add(router.unroute);
    
    raction_add(router.route.by-state);
    raction_add(router.unroute.by-state);
    
    [self swizzle];
}

+ (void)swizzle {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method willMoveToParentViewController = class_getInstanceMethod(UIViewController.self, @selector(willMoveToParentViewController:));
        Method reduxyrouter_willMoveToParentViewController = class_getInstanceMethod(UIViewController.self, @selector(reduxyrouter_willMoveToParentViewController:));
        
        if (willMoveToParentViewController && reduxyrouter_willMoveToParentViewController) {
            method_exchangeImplementations(willMoveToParentViewController, reduxyrouter_willMoveToParentViewController);
        }
        
        Method didMoveToParentViewController = class_getInstanceMethod(UIViewController.self, @selector(didMoveToParentViewController:));
        Method reduxyrouter_didMoveToParentViewController = class_getInstanceMethod(UIViewController.self, @selector(reduxyrouter_didMoveToParentViewController:));
        
        if (didMoveToParentViewController && reduxyrouter_didMoveToParentViewController) {
            method_exchangeImplementations(didMoveToParentViewController, reduxyrouter_didMoveToParentViewController);
        }
    });
}

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    static ReduxyRouter *instance;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
        
        self.targets = @{}.mutableCopy;
        self.paths = @{}.mutableCopy;
        self.pathStack = @[].mutableCopy;
        
        self.routables = [NSHashTable weakObjectsHashTable];
        
        self.routesAutoway = NO;
    }
    return self;
}

#pragma mark - store

- (void)attachStore:(id<ReduxyStore>)store {
    if (self.store) {
        [self.store unsubscribe:self];
    }
    
    self.store = store;
    [store subscribe:self];
}

- (ReduxyReducer)reducer {
    return ^ReduxyState (ReduxyState state, ReduxyAction action) {
        if ([action is:ratype(router.route)]) {
            NSString *path = action.payload[@"path"];
            NSAssert(path, @"No path to route in payload of action");
            if (path) {
                NSMutableArray *mstate = [NSMutableArray arrayWithArray:(state ?: @[])];
                [mstate addObject:action.payload];
                
                return mstate.copy;
            }
        }
        else if ([action is:ratype(router.unroute)]) {
            NSString *pathToUnroute = action.payload[@"path"];
            NSString *targetTagToUnroute = action.payload[@"target-tag"];
            
            NSAssert(pathToUnroute, @"No path to unroute in payload of action");
            NSAssert(targetTagToUnroute, @"No tag to unroute in payload of action");
            
            NSInteger foundIndex = [state findIndex:^BOOL(NSDictionary *info, NSInteger idx) {
                if ([info[@"path"] isEqualToString:pathToUnroute]) {
                    NSArray *tags = [info[@"targets"] valueForKey:@"tag"];
                    if ([tags containsObject:targetTagToUnroute]) {
                        return YES;
                    }
                };
                return NO;
            }];
            
            if (foundIndex != NSNotFound) {
                NSMutableArray *mstate = [NSMutableArray arrayWithArray:(state ?: @[])];
                
                [mstate removeObjectsInRange:NSMakeRange(foundIndex, mstate.count - foundIndex)];
                return mstate.copy;
            }
            else {
                @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                               reason:[NSString stringWithFormat:@"No path '%@', to unroute in state", pathToUnroute]
                                             userInfo:nil];
            }
        }
        
        return (state? state: @[]);
    };
}

#pragma mark - target

- (NSArray<NSString *> *)targetsForPath:(NSString *)path {
    return self.paths[path][@"targets"];
}

- (id<ReduxyRoutable>)createTarget:(NSString *)name tag:(NSString *)tag from:(id<ReduxyRoutable>)from context:(NSDictionary *)context {
    RouterTargetCreator creator = self.targets[name];
    id<ReduxyRoutable> routable = creator(from, context);
    
    setRoutableName(routable, name);
    setRoutableTag(routable, tag ?: [self generateTagForTarget:name]);
    
    return routable;
}

- (NSDictionary *)createTargetsForPath:(NSString *)path from:(id<ReduxyRoutable>)from context:(NSDictionary *)context {
    NSDictionary *pathInfo = self.paths[path];
    NSArray<NSString *> *targetNames = pathInfo[@"targets"];
    NSString *fromTag = getRoutableTag(from);
    
    NSDictionary *routables = [targetNames reduce:^id(NSMutableDictionary *acc, NSString *name) {
        id<ReduxyRoutable> routable = [self createTarget:name tag:nil from:from context:context];
        
        setRoutablePath(routable, path);
        [acc setObject:routable forKey:name];
        
        return acc;
    } initValue:@{}.mutableCopy];
    
    NSArray *targets = [targetNames reduce:^id(NSMutableArray *acc, NSString *name) {
        id<ReduxyRoutable> routable = routables[name];
        
        [acc addObject:@{ @"name": name,
                          @"tag": getRoutableTag(routable),
                         }];
        return acc;
    } initValue:@[].mutableCopy];
    
    [routables.allValues enumerateObjectsUsingBlock:^(id  _Nonnull routable, NSUInteger idx, BOOL * _Nonnull stop) {
        setRoutablePathInfo(routable, @{ @"path": path,
                                         @"from-tag": fromTag ?: @"",
                                         @"targets": targets,
                                         });
    }];
    
    return routables.copy;
}

#pragma mark - add

- (void)addTarget:(NSString *)name creator:(RouterTargetCreator)creator {
    self.targets[name] = creator;
}

- (void)removeTarget:(NSString *)name {
    [self.targets removeObjectForKey:name];
}


- (void)addPath:(NSString *)path
         target:(NSString *)target
          route:(RouterRoute)route
        unroute:(RouterUnroute)unroute
{
    [self addPath:path targets:@[ target ] route:route unroute:unroute];
}

- (void)addPath:(NSString *)path
        targets:(NSArray<NSString *> *)targets
          route:(RouterRoute)route
        unroute:(RouterUnroute)unroute
{
    self.paths[path] = @{ @"targets": targets,
                          @"route": route,
                          @"unroute": unroute,
                          };
}

- (void)removePath:(NSString *)path {
    [self.paths removeObjectForKey:path];
}

#pragma mark - route

- (NSString *)generateTagForTarget:(NSString *)target {
    NSTimeInterval ti = [NSDate timeIntervalSinceReferenceDate];
    NSString *tag = [NSString stringWithFormat:@"%@-%f", target, ti];
    return tag;
}


- (UIWindow *)startWithPath:(NSString *)path {
    NSDictionary *pathInfo = self.paths[path];
    NSArray<NSString *> *targets = pathInfo[@"targets"];
    NSMutableDictionary *tags = @{}.mutableCopy;
    
    for (NSString *target in targets) {
        tags[target] = [NSString stringWithFormat:@"%@-main", target];
    }
    
    [self.window makeKeyAndVisible];
    
    [self routePath:path from:self.window context:nil tags:tags.copy];
    
    return self.window;
}

- (void)routePath:(NSString *)path from:(id<ReduxyRoutable>)from context:(NSDictionary *)context {
    [self routePath:path from:from context:context tags:@{}];
}

- (void)routePath:(NSString *)path from:(id<ReduxyRoutable>)from context:(NSDictionary *)context tags:(NSDictionary *)predefinedTags {
    NSDictionary *pathInfo = self.paths[path];
    NSArray<NSString *> *targetNames = pathInfo[@"targets"];
    NSString *fromTag = getRoutableTag(from);
    
    [self addRoutable:from];
    
    // generate tags for targets in advance of creation of them
    NSArray *targets = [targetNames map:^id(NSString *name, NSInteger idx) {
        NSString * tag = predefinedTags[name];
        return @{ @"name": name,
                  @"tag": tag?: [self generateTagForTarget:name],
                  };
    }];
    
    [self.store dispatch:ratype(router.route)
                 payload:@{ @"path": path,
                            @"from-tag": fromTag ?: @"",
                            @"context": context ?: @{},
                            @"targets": targets,
                            }
     ];
}

- (void)routeTargets:(NSArray *)targets {
    NSString *path = getRoutablePath(targets.firstObject);
    NSDictionary *pathInfo = getRoutablePathInfo(targets.firstObject);
    NSString *fromTag = pathInfo[@"from-tag"];
    
    NSAssert(path, @"No path associated with target");
    NSAssert(pathInfo, @"No path info associated with target");
    NSAssert(fromTag, @"No from-tag associated with target");
    
    NSArray *payloadTargets = [targets map:^id(id target, NSInteger idx) {
        [self addRoutable:target];
        
        return @{ @"name": getRoutableName(target),
                  @"tag": getRoutableTag(target),
                  };
    }];
    
    [self.store dispatch:ratype(router.route)
                 payload:@{ @"path": path,
                            @"from-tag": fromTag ?: @"",
                            @"context": @{},
                            @"targets": payloadTargets,
                            }
     ];
}

- (void)unroutePathFrom:(id<ReduxyRoutable>)from {
    NSString *path = getRoutablePath(from);
    NSString *targetTag = getRoutableTag(from);
    
    [self.store dispatch:ratype(router.unroute)
                 payload:@{ @"path": path,
                            @"target-tag": targetTag,
                            }
     ];
}


#pragma mark - route payload

- (void)routePayload:(NSDictionary *)payload {
    NSString *path = payload[@"path"];
    NSString *fromTag = payload[@"from-tag"];
    NSDictionary *context = payload[@"context"];
    NSArray *targets = [payload valueForKeyPath:@"targets"];
    
    NSDictionary *pathInfo = self.paths[path];
    
    RouterRoute route = pathInfo[@"route"];
    
    NSMutableDictionary *to = @{}.mutableCopy;
    id<ReduxyRoutable> from = [self findRoutableWithTag:fromTag];
    
    for (NSDictionary *target in targets) {
        NSString *name = target[@"name"];
        NSString *tag = target[@"tag"];
        
        id<ReduxyRoutable> routable = [self findRoutableWithTag:tag];
        
        if (routable) {
            to[name] = routable;
        }
        else {
            id<ReduxyRoutable> routable = [self createTarget:name tag:tag from:from context:context];
            
            [self addRoutable:routable];
            
            to[name] = routable;
            
            setRoutablePath(routable, path);
            setRoutablePathInfo(routable, @{ @"path": path,
                                             @"from-tag": fromTag ?: @"",
                                             @"targets": targets,
                                             });
        }
    }
    
    [self pushPath:@{ @"path": path,
                      @"from-tag": fromTag ?: @"__NONE__",
                      @"targets": targets,
                      }];
    
    route(from, to, context);
}

- (void)unroutePayload:(NSDictionary *)payload {
    NSString *path = payload[@"path"];
    NSString *fromTag = payload[@"from-tag"];
    
    NSAssert(path, @"No path to unroute");
    NSAssert(fromTag, @"No from-tag to unroute");
    
    id<ReduxyRoutable> from = [self findRoutableWithTag:fromTag];
    if (from) {
        [self popPath:@{ @"path": path,
                         @"from-tag": fromTag }];
        
        NSDictionary *pathInfo = self.paths[path];
        RouterUnroute unroute = pathInfo[@"unroute"];
        
        unroute(from);
    }
}

#pragma mark - path stack

- (void)pushPath:(NSDictionary *)info {
    [self.pathStack addObject:info];
}

- (NSArray *)popPath:(NSDictionary *)infoToPop {
    NSString *pathToPop = infoToPop[@"path"];
    NSString *fromTagToPop = infoToPop[@"from-tag"];
    
    NSInteger foundIndex = [self.pathStack findIndex:^BOOL(NSDictionary *info, NSInteger idx) {
        return ([info[@"path"] isEqualToString:pathToPop] &&
                [info[@"from-tag"] isEqualToString:fromTagToPop]);
    }];
    
    if (foundIndex != NSNotFound) {
        NSRange range = NSMakeRange(foundIndex, self.pathStack.count - foundIndex);
        
        NSArray *pathsToPop = [self.pathStack subarrayWithRange:range];
        
        [self.pathStack removeObjectsInRange:range];
        
        return pathsToPop;
    }
    else {
        NSAssert(NO, @"Not found path to pop from stack");
    }
    return nil;
}

- (BOOL)containsPath:(NSDictionary *)info {
    return [self.pathStack containsObject:info];
}

#pragma mark - routables

- (void)addRoutable:(id<ReduxyRoutable>)routable {
    [self.routables addObject:routable];
}

- (id<ReduxyRoutable>)findRoutableWithTag:(id)tagToFind {
    if (!tagToFind) {
        return nil;
    }
    
    for (id<ReduxyRoutable> routable in self.routables) {
        NSString *tag = getRoutableTag(routable);
        if ([tag isEqualToString:tagToFind])
            return routable;
    }
    return nil;
}

#pragma mark - event

- (void)viewController:(UIViewController<ReduxyRoutable> *)vc willMoveToParentViewController:(UIViewController *)parent {
}

- (void)viewController:(UIViewController<ReduxyRoutable> *)vc didMoveToParentViewController:(UIViewController *)parent {
    BOOL attached = (parent != nil);
    if (attached) {
        [self didRouteFrom:parent to:@[ vc ]];
    }
    else {
        [self didUnrouteFrom:vc];
    }
}

- (BOOL)didUnrouteFrom:(id<ReduxyRoutable>)from {
    NSParameterAssert(from);
    
    NSString *targetTag = getRoutableTag(from);
    NSString *path = getRoutablePath(from);
    NSDictionary *pathInfo = getRoutablePathInfo(from);
    
    NSArray *targets = pathInfo[@"targets"];
    
    BOOL singleTarget = (targets.count == 1);
    BOOL unintended = [self containsPath:pathInfo];
    
    if (unintended && singleTarget) {
        // dispatch a unroute for uninteded unrouting of one target
        
        [self popPath:pathInfo];
        
        [self.store dispatch:ratype(router.unroute)
                     payload:@{ @"path": path,
                                @"target-tag": targetTag,
                                @"implicit": @YES,
                                }];
    }
    
    return YES;
}

- (BOOL)didRouteFrom:(UIViewController *)from to:(NSArray<id<ReduxyRoutable>> *)to {
    NSParameterAssert(from);
    NSParameterAssert(to);
    
    for (id<ReduxyRoutable> routable in to) {
        NSString *tag = getRoutableTag(routable);

        NSAssert(tag, @"No tag for routable");
        
        BOOL hasToAlready = ([self findRoutableWithTag:tag] != nil);
        if (hasToAlready) {
            // from routable is already in routable pool
        }
        else {
            // unintended route
        }
    }
    
    return YES;
}

#pragma mark - ReduxyStoreSubscriber

- (void)store:(id<ReduxyStore>)store didChangeState:(ReduxyState)state byAction:(ReduxyAction)action {
    NSArray *pathsInRouter = self.pathStack;
    NSArray *pathsInState = [state valueForKeyPath:@"router.routes"];
    
    if (pathsInState.count > pathsInRouter.count) {
        // route
        
        // routing push only one step
        NSDictionary *pathToRoute = pathsInState[pathsInRouter.count];
        
        [self routePayload:pathToRoute];
        
    }
    else if (pathsInState.count < pathsInRouter.count) {
        // unroute
        
        // unrouting can pop multiple step
        NSDictionary *pathToUnroute = pathsInRouter[pathsInState.count];
        
        [self unroutePayload:pathToUnroute];
    }
}

@end
