//
//  ViewController.m
//  IJKMediaPodDemo
//
//  Created by Zhang Rui on 15/7/23.
//  Copyright (c) 2015年 Zhang Rui. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import "ViewController.h"
#import <IJKMediaFramework/IJKMediaFramework.h>
#import "ViewControllers/IJKMoviePlayerViewController.h"
#import "Vendors/Reachability/Reachability.h"
#import "Misc/IJKDemoHistory.h"

@interface ViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *videos;
@property (nonatomic, strong) NSArray *historys;
@property (nonatomic, strong) Reachability *reach;
@property (nonatomic, assign) BOOL useAVKit;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _useAVKit = NO;
    UIBarButtonItem *rightBarItem = [[UIBarButtonItem alloc] initWithTitle:@"IJKPlayer" style:UIBarButtonItemStylePlain target:self action:@selector(handleRightBarItemClick:)];
    self.navigationItem.rightBarButtonItem = rightBarItem;
    
    [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    [self checkNetworks];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self fetchPlayHistory];
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

- (void)fetchPlayHistory {
    _historys = [[IJKDemoHistory instance] list];
    [self.tableView reloadData];
}

#pragma mark - handleRightBarItemClick
- (void)handleRightBarItemClick:(UIBarButtonItem *)barItem {
    _useAVKit = !_useAVKit;
    barItem.title = _useAVKit ? @"AVKit" : @"IJKPlayer";
}

#pragma mark - Input Action
- (IBAction)handleInputClick:(UIButton *)button {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"输入URL" message:nil preferredStyle:UIAlertControllerStyleAlert];
    __weak __typeof__(self) weakSelf = self;
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"URL";
    }];
    UIAlertAction *playAction = [UIAlertAction actionWithTitle:@"播放" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *textFiled = alertController.textFields.firstObject;
        NSString *url = textFiled.text;
        [weakSelf playVideo:url url:url];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:playAction];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Play With URL
- (void)playVideo:(NSString *)title url:(NSString *)url {
    if (!url || url.length == 0) {
        return;
    }
    IJKDemoHistoryItem *historyItem = [[IJKDemoHistoryItem alloc] init];
    
    historyItem.title = title;
    historyItem.url = [NSURL URLWithString:url];
    [[IJKDemoHistory instance] add:historyItem];
    if (_useAVKit) {
        AVPlayer *player = [AVPlayer playerWithURL:[NSURL URLWithString:url]];
        AVPlayerViewController *playerViewController = [AVPlayerViewController new];
        playerViewController.player = player;
        [self presentViewController:playerViewController animated:YES completion:^{
            [player play];
        }];
    } else {
        [IJKVideoViewController presentFromViewController:self withTitle:title URL:[NSURL URLWithString:url] completion:^{
        }];
    }
}

#pragma mark - UITableViewDataSourse
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return _videos.count;
        case 1:
            return _historys.count;
        default:
            return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return @"预告片";
        case 1:
            return @"历史记录";
        default:
            return @"";
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (indexPath.section == 0) {
        NSDictionary *video = _videos[indexPath.row];
        cell.textLabel.text = video[@"movieName"];
    } else if(indexPath.section == 1) {
        IJKDemoHistoryItem *item = _historys[indexPath.row];
        cell.textLabel.text = item.title;
    }
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        NSDictionary *video = _videos[indexPath.row];
        NSString *url = video[@"url"];
        [self playVideo:video[@"movieName"] url:url];
    } else {
        IJKDemoHistoryItem *item = _historys[indexPath.row];
        [self playVideo:item.title url:item.url.absoluteString];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return (indexPath.section == 1);
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        return UITableViewCellEditingStyleDelete;
    }
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    __weak typeof(self) weakSelf = self;
    if (indexPath.section == 1 && editingStyle == UITableViewCellEditingStyleDelete) {
        [[IJKDemoHistory instance] removeAtIndex:indexPath.row];
        weakSelf.historys = [[IJKDemoHistory instance] list];
        [weakSelf.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
