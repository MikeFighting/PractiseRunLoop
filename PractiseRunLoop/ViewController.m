//
//  ViewController.m
//  PractiseRunLoop
//
//  Created by robot on 4/24/16.
//  Copyright © 2016 codeFighter.com. All rights reserved.
//  QQ:1500190761 欢迎交流学习

#import "ViewController.h"

@interface ViewController ()

@property(nonatomic,strong) NSThread *myThread;
@property(nonatomic,assign) BOOL runLoopThreadDidFinishFlag;
@property(nonatomic,strong) dispatch_source_t timer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // [self simplePractiseBackGround];
    // [self simplePractiseMain];
    
    // [self tryPerformSelectorOnMianThread];
    // [self tryPerformSelectorOnBackGroundThread];
    
    // [self alwaysLiveBackGoundThread];
    // [self tryTimerOnMainThread];
    // [self tryTimerOnBackGrondThread];
    
    [self runLoopAddDependance];
    [self gcdTimer];
    
}

- (void)simplePractiseMain{

    while (1) {
        
        NSLog(@"while begin");
        // the thread be blocked here
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        NSLog(@"%@",runLoop);
        [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        // this will not be executed

        NSLog(@"while end");
        
    }

}
- (void)simplePractiseBackGround{

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      
        while (1) {
            
            NSPort *macPort = [NSPort port];
            NSLog(@"while begin");
            NSRunLoop *subRunLoop = [NSRunLoop currentRunLoop];
            [subRunLoop addPort:macPort forMode:NSDefaultRunLoopMode];
            [subRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
            NSLog(@"while end");
            NSLog(@"%@",subRunLoop);
            
        }
        
        
    });

}

- (void)tryPerformSelectorOnMianThread{

    [self performSelector:@selector(mainThreadMethod) withObject:nil];
    

}
- (void)mainThreadMethod{

    NSLog(@"execute %s",__func__);
    // print: execute -[ViewController mainThreadMethod]
    

}

- (void)tryPerformSelectorOnBackGroundThread{
    
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
   
    [self performSelector:@selector(backGroundThread) onThread:[NSThread currentThread] withObject:nil waitUntilDone:NO];
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    [runLoop run];

});
}
- (void)backGroundThread{

    NSLog(@"%u",[NSThread isMainThread]);
    NSLog(@"execute %s",__FUNCTION__);

}
- (void)alwaysLiveBackGoundThread{

    NSThread *thread = [[NSThread alloc]initWithTarget:self selector:@selector(myThreadRun) object:@"etund"];
    self.myThread = thread;
    [self.myThread start];

}
- (void)myThreadRun{

    NSLog(@"my thread run");
    
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{

    NSLog(@"%@",self.myThread);
    [self performSelector:@selector(doBackGroundThreadWork) onThread:self.myThread withObject:nil waitUntilDone:NO];
}
- (void)doBackGroundThreadWork{

    NSLog(@"do some work %s",__FUNCTION__);
    
}
- (void)tryTimerOnMainThread{

    NSTimer *myTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(timerAction) userInfo:nil repeats:YES];
    [myTimer fire];
    
}
- (void)tryTimerOnBackGrondThread{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
       
        NSTimer *myTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(timerAction) userInfo:nil repeats:YES];
        [myTimer fire];
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop run];

        
    });


}
- (void)timerAction{

    NSLog(@"timer action");
}
- (void)runLoopAddDependance{
    
    self.runLoopThreadDidFinishFlag = NO;
    NSLog(@"Start a New Run Loop Thread");
    NSThread *runLoopThread = [[NSThread alloc] initWithTarget:self selector:@selector(handleRunLoopThreadTask) object:nil];
    [runLoopThread start];
    
    NSLog(@"Exit handleRunLoopThreadButtonTouchUpInside");
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        
        while (!_runLoopThreadDidFinishFlag) {
            
            self.myThread = [NSThread currentThread];
            NSLog(@"Begin RunLoop");
            NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
            NSPort *myPort = [NSPort port];
            [runLoop addPort:myPort forMode:NSDefaultRunLoopMode];
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
            NSLog(@"End RunLoop");
            [self.myThread cancel];
            self.myThread = nil;
            
        }
    });

}
- (void)handleRunLoopThreadTask
{
    NSLog(@"Enter Run Loop Thread");
    for (NSInteger i = 0; i < 5; i ++) {
        NSLog(@"In Run Loop Thread, count = %ld", i);
        sleep(1);
    }
#if 0
    // 错误示范
    _runLoopThreadDidFinishFlag = YES;
    // 这个时候并不能执行线程完成之后的任务，因为Run Loop所在的线程并不知道runLoopThreadDidFinishFlag被重新赋值。Run Loop这个时候没有被任务事件源唤醒。
    // 正确的做法是使用 "selector"方法唤醒Run Loop。 即如下:
#endif
    NSLog(@"Exit Normal Thread");
    [self performSelector:@selector(tryOnMyThread) onThread:self.myThread withObject:nil waitUntilDone:NO];
    
    // NSLog(@"Exit Run Loop Thread");
}
- (void)tryOnMyThread{
    
    _runLoopThreadDidFinishFlag = YES;
    
}
- (void)gcdTimer{
    
    // get the queue
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    
    // creat timer
    self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    // config the timer (starting time，interval)
    // set begining time
    dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC));
    // set the interval
    uint64_t interver = (uint64_t)(1.0 * NSEC_PER_SEC);
    
    dispatch_source_set_timer(self.timer, start, interver, 0.0);
    
    dispatch_source_set_event_handler(self.timer, ^{
        
        // the tarsk needed to be processed async
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            for (int i = 0; i < 100000; i++) {
                
                NSLog(@"gcdTimer");
                
                
            }
            
        });

        
    });
    
    dispatch_resume(self.timer);
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
