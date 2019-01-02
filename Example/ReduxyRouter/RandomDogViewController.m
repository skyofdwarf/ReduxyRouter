//
//  RandomDogViewController.m
//  Reduxy_Example
//
//  Created by yjkim on 25/04/2018.
//  Copyright © 2018 skyofdwarf. All rights reserved.
//

#import "RandomDogViewController.h"

static selector_block indicatorSelector = ^id (ReduxyState state) {
    return state[@"indicator"];
};

static selector_block imageDataSelector = ^id (ReduxyState state) {
    return state[@"randomdog"][@"data"];
};

static selector_block imageUrlSelector = ^id (ReduxyState state) {
    return state[@"randomdog"][@"url"];
};

static selector_block imageSelector = ^id (ReduxyState state) {
    return state[@"randomdog"][@"image"];
};




@interface RandomDogViewController ()
<
ReduxyStoreSubscriber,
ReduxyRoutable
>
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicatorView;

@property (copy, nonatomic) ReduxyAsyncActionCanceller canceller;

@end

@implementation RandomDogViewController

+ (void)load {
    raction_add(randomdog.reload);
}
    
- (NSString *)path {
    return @"randomdog";
}

- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self.store unsubscribe:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSAssert(self.store, @"No store");
    
    self.view.backgroundColor = [UIColor grayColor];
    
    self.title = (self.breed?
                  self.breed:
                  @"random dog");
    
    [self.store subscribe:self];
    
    self.indicatorView.hidesWhenStopped = YES;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.canceller) {
        self.canceller();
        self.canceller = nil;
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

#pragma mark - private

- (void)updateImageWithData:(NSData *)data {
    self.imageView.image = [UIImage imageWithData:data];
}

#pragma mark - network

- (void)reload {
    NSString *urlString = @"https://dog.ceo/api/breeds/image/random"; ///< all random
    if (self.breed) {
        urlString = [NSString stringWithFormat:@"https://dog.ceo/api/breed/%@/images/random", self.breed];
    }
    
    __weak typeof(self) wself = self;
    
    [self.store dispatch:raction_payload(indicator, @YES)];
    
    ReduxyAsyncAction *action = [ReduxyAsyncAction newWithTag:@"randomdog.fetch-random"
                                                        actor:^ReduxyAsyncActionCanceller(ReduxyDispatch storeDispatch)
                                 {
                                     NSURL *url = [NSURL URLWithString:urlString];
                                     
                                     NSURLSessionDataTask *task = [NSURLSession.sharedSession dataTaskWithURL:url
                                                                                            completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
                                                                   {
                                                                       wself.canceller = nil;
                                                                       
                                                                       if (!error) {
                                                                           NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                                                                                                                options:0
                                                                                                                                  error:nil];
                                                                           
                                                                           NSString *status = json[@"status"];
                                                                           
                                                                           if ([status isEqualToString:@"success"]) {
                                                                               NSString *imageUrl = json[@"message"];
                                                                               
                                                                               // success
                                                                               [wself loadImageWithUrlString:imageUrl completion:^(NSData *data) {
                                                                                   storeDispatch(data?
                                                                                                 raction_payload(randomdog.reload, @{ @"image": data }):
                                                                                                 raction(randomdog.reload));
                                                                                   
                                                                                   storeDispatch(raction_payload(indicator, @NO));
                                                                               }];
                                                                               
                                                                               return ;
                                                                           }
                                                                       }
                                                                       
                                                                       // fail
                                                                       storeDispatch(raction(randomdog.reload));
                                                                       storeDispatch(raction_payload(indicator, @NO));
                                                                   }];
                                     [task resume];
                                     
                                     return ^() {
                                         [task cancel];
                                         storeDispatch(raction_payload(indicator, @NO));
                                         
                                         NSLog(@"reload is cancelled");
                                     };
                                 }];
    
    self.canceller = (ReduxyAsyncActionCanceller)[self.store dispatch:action];
}

- (void)loadImageWithUrlString:(NSString *)urlString completion:(void (^)(NSData *data))completion {
    NSURL *url = [NSURL URLWithString:urlString];
    
    __weak typeof(self) wself = self;
    
    NSURLSessionDataTask *task = [NSURLSession.sharedSession dataTaskWithURL:url
                                                           completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
                                  {
                                      NSLog(@"load image error?: %@", error);
                                      wself.canceller = nil;
                                      completion(data);
                                  }];
    [task resume];
    
    self.canceller = ^void () {
        [task cancel];
        
        [wself.store dispatch:raction_payload(indicator, @NO)];
        
        NSLog(@"load image cancelled");
    };
}

#pragma mark - actions

- (IBAction)reloadButtonDidClick:(id)sender {
    [self reload];
}

- (IBAction)aboutButtonDidClick:(id)sender {
    [ReduxyRouter.shared routePath:@"about" from:self context:nil];
}

- (IBAction)popButtonDidClick:(id)sender {
    [ReduxyRouter.shared unroutePathFrom:self];
}


#pragma mark - ReduxyStoreSubscriber

- (void)store:(id<ReduxyStore>)store didChangeState:(ReduxyState)state byAction:(ReduxyAction)action {
    
    // update indicator
    NSNumber *indicator = indicatorSelector(state);
    if (indicator.boolValue) {
        [self.indicatorView startAnimating];
    }
    else {
        [self.indicatorView stopAnimating];
    }
    
    // update image
    //self.imageView.image = imageSelector(state);
    NSData *data = imageSelector(state);
    self.imageView.image = [UIImage imageWithData:data];
}


@end
