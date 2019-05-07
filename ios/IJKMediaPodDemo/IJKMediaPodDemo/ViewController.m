//
//  ViewController.m
//  IJKMediaPodDemo
//
//  Created by Zhang Rui on 15/7/23.
//  Copyright (c) 2015年 Zhang Rui. All rights reserved.
//

#import "ViewController.h"
#import <IJKMediaFramework/IJKMediaFramework.h>
#import "ViewControllers/IJKMoviePlayerViewController.h"
#import "Vendors/Reachability/Reachability.h"

const NSString *url = @"http://vfx.mtime.cn/Video/2017/03/31/mp4/170331093811717750.mp4";

@interface ViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *videos;
@property (nonatomic, strong) Reachability *reach;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

//    id<IJKMediaPlayback> playback = [[IJKFFMoviePlayerController alloc] initWithContentURL:nil  withOptions:nil];
//
//    [playback shutdown];
    [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    [self checkNetworks];
}

- (void)checkNetworks {
    _reach = [Reachability reachabilityWithHostName:@"www.baidu.com"];
    __weak __typeof__(self) weakSelf = self;
    _reach.reachableBlock = ^(Reachability *reachability) {
        [weakSelf fetchMovies];
    };
    [_reach startNotifier];
}

- (void)fetchMovies {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *url = [NSURL URLWithString:@"http://api.m.mtime.cn/PageSubArea/TrailerList.api"];
        NSData *data = [NSData dataWithContentsOfURL:url];
        if (!data) {
            return;
        }
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSArray *trailers = dict[@"trailers"];
        self.videos = trailers;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    });
}

#pragma mark - UITableViewDataSourse
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _videos.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    NSDictionary *video = _videos[indexPath.row];
    cell.textLabel.text = video[@"movieName"];
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *video = _videos[indexPath.row];
    NSString *url = video[@"url"];
    [IJKVideoViewController presentFromViewController:self withTitle:video[@"movieName"] URL:[NSURL URLWithString:url] completion:^{
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
