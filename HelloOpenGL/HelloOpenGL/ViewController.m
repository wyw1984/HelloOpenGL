//
//  ViewController.m
//  HelloOpenGL
//
//  Created by yanwu wei on 2017/5/2.
//  Copyright © 2017年 Ivan. All rights reserved.
//

#import "ViewController.h"
#import "OpenGLView.h" 
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ReactiveCocoa/RACEXTScope.h>


@interface ViewController ()
{
    OpenGLView* _glView;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _glView = [[OpenGLView alloc] initWithFrame:CGRectMake(0, 100, self.view.frame.size.width, 300)];
    [self.view addSubview:_glView];
    
    
    {
        NSArray *segmentedArray = [[NSArray alloc] initWithObjects:@"全屏",@"1/4",nil];
        //初始化UISegmentedControl
        UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:segmentedArray];
        
        [self.view addSubview:segmentedControl];
        segmentedControl.frame = CGRectMake(20,40,300,40);
        
        segmentedControl.selectedSegmentIndex = 0;
        
        @weakify(self);
        [[segmentedControl rac_newSelectedSegmentIndexChannelWithNilValue:@0] subscribeNext:^(id x)
         {
             // 返回的基本数据类型都被装包成NSNumber，可在此做一些判断操作
             NSLog(@"selectIndex-%@",x);
             @strongify(self);
             
             if([x integerValue] == 0)
             {
                 [self toFull];
             }
             
             if([x integerValue] == 1)
             {
                 [self to14];
             }
             
             
         }];
    }
    
    
}
-(void)toFull
{
    //[self.videoView stopRender];
    [_glView setFrame:CGRectMake(0, 100, self.view.frame.size.width, 300)];
    //[self.videoView startRender];
}

-(void)to14
{
    //[self.videoView stopRender];
    [_glView setFrame:CGRectMake(0, 100, self.view.frame.size.width/2, 300/2)];
    //[self.videoView startRender];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
