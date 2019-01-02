//
//  ReduxyAppDelegate.m
//  ReduxyRouter
//
//  Created by skyofdwarf on 12/22/2018.
//  Copyright (c) 2018 skyofdwarf. All rights reserved.
//

#import "ReduxyAppDelegate.h"
#import "Store.h"
#import "BreedListViewController.h"
#import "AboutViewController.h"
#import "RandomDogViewController.h"

@import Reduxy;
@import ReduxyRouter;

@interface ReduxyAppDelegate ()
@property (strong, nonatomic) ReduxyStore *store;

@end


@implementation ReduxyAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [self buildTargets];
    [self buildPaths];
    
    self.window = [ReduxyRouter.shared startWithPath:@"main"];
    
    return YES;
}

#pragma mark - router

- (void)buildTargets {
    [ReduxyRouter.shared addTarget:@"breedlist" creator:^id<ReduxyRoutable>(id<ReduxyRoutable> from, NSDictionary *context) {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        BreedListViewController *dest = [sb instantiateViewControllerWithIdentifier:@"breedlist"];
        
        return dest;
    }];
    
    [ReduxyRouter.shared addTarget:@"randomdog" creator:^id<ReduxyRoutable>(id<ReduxyRoutable> from, NSDictionary *context) {
        RandomDogViewController *dest = [from.vc.storyboard instantiateViewControllerWithIdentifier:@"randomdog"];
        
        dest.store = Store.shared;
        dest.breed = context[@"breed"];
        
        return dest;
    }];
    
    [ReduxyRouter.shared addTarget:@"about" creator:^id<ReduxyRoutable>(id<ReduxyRoutable> from, NSDictionary *context) {
        AboutViewController *dest = [from.vc.storyboard instantiateViewControllerWithIdentifier:@"about"];
        return dest;
    }];
}

- (void)buildPaths {
    [ReduxyRouter.shared attachStore:Store.shared];
    
    [ReduxyRouter.shared addPath:@"main"
                         targets:@[ @"breedlist" ]
                           route:^void(id<ReduxyRoutable> from, NSDictionary<NSString *,id<ReduxyRoutable>> *to, NSDictionary *context) {
                               id<ReduxyRoutable> routable = to[@"breedlist"];
                               UINavigationController *nv = [[UINavigationController alloc] initWithRootViewController:routable.vc];
                               
                               from.window.rootViewController = nv;
                           } unroute:^void(id<ReduxyRoutable> from) {
                               from.window.rootViewController = nil;
                           }];
    
    [ReduxyRouter.shared addPath:@"randomdog"
                         targets:@[ @"randomdog" ]
                           route:^void(id<ReduxyRoutable> from, NSDictionary<NSString *,id<ReduxyRoutable>> *to, NSDictionary *context) {
                               id<ReduxyRoutable> routable = to[@"randomdog"];
                               
                               [from.vc showViewController:routable.vc sender:nil];
                           } unroute:^void(id<ReduxyRoutable> from) {
                               [from.vc.navigationController popViewControllerAnimated:YES];
                           }];
    
    [ReduxyRouter.shared addPath:@"about"
                         targets:@[ @"about" ]
                           route:^void(id<ReduxyRoutable> from, NSDictionary<NSString *,id<ReduxyRoutable>> *to, NSDictionary *context) {
                               id<ReduxyRoutable> routable = to[@"about"];
                               
                               [from.vc showViewController:routable.vc sender:nil];
                           } unroute:^void(id<ReduxyRoutable> from) {
                               [from.vc.navigationController popViewControllerAnimated:YES];
                           }];
    
    [ReduxyRouter.shared addPath:@"about-modal"
                         targets:@[ @"about" ]
                           route:^void(id<ReduxyRoutable> from, NSDictionary<NSString *,id<ReduxyRoutable>> *to, NSDictionary *context) {
                               id<ReduxyRoutable> about = to[@"about"];
                               UINavigationController *nv = [[UINavigationController alloc] initWithRootViewController:about.vc];
                               
                               [from.vc presentViewController:nv
                                                     animated:YES
                                                   completion:nil];
                           } unroute:^void(id<ReduxyRoutable> from) {
                               [from.vc dismissViewControllerAnimated:YES
                                                           completion:nil];
                           }];
}


@end
