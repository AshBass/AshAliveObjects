//
//  ViewController.m
//  Demo
//
//  Created by crimsonho on 2021/6/10.
//

#import "ViewController.h"
#import <AshAliveObjects/AshAliveObjects.h>

typedef void(^TestBlock)(void);

@interface ViewController ()

@property (nonatomic, strong) NSMutableArray *array;
@property (nonatomic, strong) NSMutableDictionary *dictionary;
@property (nonatomic, copy) TestBlock test;
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.test = ^{
        self.view.tag = 20;
    };
    
    self.array = [[NSMutableArray alloc] init];
    [self.array addObject:self];

    self.dictionary = [[NSMutableDictionary alloc] init];
    [self.dictionary setObject:self forKey:@"vc"];
//
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(log) userInfo:self repeats:YES];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSArray *appAliveObjects = [AshMallocObjectsOC appAliveObjectsOC];
    NSMutableArray *modelArray = [[NSMutableArray alloc] init];
    for (id obj in appAliveObjects) {
        AshRetainCheckerObjectModel *model = [[AshRetainCheckerObjectModel alloc] initWithObject:obj];
        [modelArray addObject:model];
    }
    AshRetainChecker *retainChecker = [[AshRetainChecker alloc] init];
    for (AshRetainCheckerObjectModel *model in modelArray) {
        NSArray *logArray = [retainChecker findRetainWithObjectModel:model className:@"ViewController"];
        NSLog(@"%@", logArray);
    }
}

- (void)log
{
    NSLog(@"log");
}

@end
