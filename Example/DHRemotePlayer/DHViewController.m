//
//  DHViewController.m
//  DHRemotePlayer
//
//  Created by DHLau on 05/18/2017.
//  Copyright (c) 2017 DHLau. All rights reserved.
//

#import "DHViewController.h"
#import "DHRemotePlayer.h"

@interface DHViewController ()

@property (weak, nonatomic) IBOutlet UILabel *playTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalTimeLabel;

@property (weak, nonatomic) IBOutlet UIProgressView *loadPV;

@property (nonatomic, weak) NSTimer *timer;
@property (weak, nonatomic) IBOutlet UISlider *playSlider;

@property (weak, nonatomic) IBOutlet UIButton *mutedBtn;
@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;

@end

@implementation DHViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.playTimeLabel.text =  [DHRemotePlayer shareInstance].currentTimeFormat;
    self.totalTimeLabel.text = [DHRemotePlayer shareInstance].totalTimeFormat;
    
    self.playSlider.value = [DHRemotePlayer shareInstance].progress;
    
    self.volumeSlider.value = [DHRemotePlayer shareInstance].volume;
    
    self.loadPV.progress = [DHRemotePlayer shareInstance].loadDataProgress;
    
    self.mutedBtn.selected = [DHRemotePlayer shareInstance].muted;
}

- (IBAction)play:(id)sender {
    NSURL *url = [NSURL URLWithString:@"http://audio.xmcdn.com/group23/M06/5C/70/wKgJL1g0DVahoMhrAMJMkvfN17c025.m4a"];
    [[DHRemotePlayer shareInstance] playWithURL:url isCache:YES];
    
}
- (IBAction)pause:(id)sender {
     [[DHRemotePlayer shareInstance] pause];
}

- (IBAction)resume:(id)sender {
    [[DHRemotePlayer shareInstance] resume];
}
- (IBAction)kuaijin:(id)sender {
    [[DHRemotePlayer shareInstance] seekWithTimeDiffer:15];
}
- (IBAction)progress:(UISlider *)sender {
    [[DHRemotePlayer shareInstance] seekWithProgress:sender.value];
}
- (IBAction)rate:(id)sender {
    [[DHRemotePlayer shareInstance] setRate:2];
}
- (IBAction)muted:(UIButton *)sender {
    sender.selected = !sender.selected;
    [[DHRemotePlayer shareInstance] setMuted:sender.selected];
}
- (IBAction)volume:(UISlider *)sender {
    [[DHRemotePlayer shareInstance] setVolume:sender.value];
}

@end
