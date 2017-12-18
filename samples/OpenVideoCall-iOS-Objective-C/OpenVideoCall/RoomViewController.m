//
//  RoomViewController.m
//  OpenVideoCall
//
//  Created by GongYuhua on 2016/9/12.
//  Copyright © 2016年 Agora. All rights reserved.
//

#import "RoomViewController.h"
#import "VideoSession.h"
#import "VideoViewLayouter.h"
#import "KeyCenter.h"
#import "AGVideoPreProcessing.h"
#import "FUManager.h"
#import <FUAPIDemoBar/FUAPIDemoBar.h>

@interface RoomViewController () <AgoraRtcEngineDelegate,FUAPIDemoBarDelegate,UIGestureRecognizerDelegate>
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *flowViews;
@property (weak, nonatomic) IBOutlet UILabel *roomNameLabel;

@property (weak, nonatomic) IBOutlet UIView *controlView;

@property (weak, nonatomic) IBOutlet UIButton *muteVideoButton;
@property (weak, nonatomic) IBOutlet UIButton *muteAudioButton;

@property (weak, nonatomic) IBOutlet UIButton *cameraButton;
@property (weak, nonatomic) IBOutlet UIButton *speakerButton;

@property (weak, nonatomic) IBOutlet UITapGestureRecognizer *backgroundTap;
@property (weak, nonatomic) IBOutlet UITapGestureRecognizer *backgroundDoubleTap;

@property (strong, nonatomic) AgoraRtcEngineKit *agoraKit;
@property (strong, nonatomic) NSMutableArray<VideoSession *> *videoSessions;
@property (strong, nonatomic) VideoSession *doubleClickFullSession;
@property (strong, nonatomic) VideoViewLayouter *videoViewLayouter;

@property (assign, nonatomic) BOOL shouldHideFlowViews;
@property (assign, nonatomic) BOOL audioMuted;
@property (assign, nonatomic) BOOL videoMuted;
@property (assign, nonatomic) BOOL speakerEnabled;

@property (assign, nonatomic) BOOL isFiltering;
@property (strong, nonatomic) FUAPIDemoBar *fuDemoBar;
@property (assign, nonatomic) BOOL shouldShowFuDemoBar;

@end

@implementation RoomViewController
- (void)setShouldHideFlowViews:(BOOL)shouldHideFlowViews {
    _shouldHideFlowViews = shouldHideFlowViews;
    if (self.flowViews.count) {
        for (UIView *view in self.flowViews) {
            view.hidden = shouldHideFlowViews;
        }
    }
}

- (void)setDoubleClickFullSession:(VideoSession *)doubleClickFullSession {
    _doubleClickFullSession = doubleClickFullSession;
    if (self.videoSessions.count >= 3) {
        [self updateInterfaceWithSessions:self.videoSessions targetSize:self.containerView.frame.size animation:YES];
    }
}

- (VideoViewLayouter *)videoViewLayouter {
    if (!_videoViewLayouter) {
        _videoViewLayouter = [[VideoViewLayouter alloc] init];
    }
    return _videoViewLayouter;
}

- (void)setAudioMuted:(BOOL)audioMuted {
    _audioMuted = audioMuted;
    [self.muteAudioButton setImage:[UIImage imageNamed:(audioMuted ? @"btn_mute_blue" : @"btn_mute")] forState:UIControlStateNormal];
    [self.agoraKit muteLocalAudioStream:audioMuted];
}

- (void)setVideoMuted:(BOOL)videoMuted {
    _videoMuted = videoMuted;
    [self.muteVideoButton setImage:[UIImage imageNamed:(videoMuted ? @"btn_video" : @"btn_voice")] forState:UIControlStateNormal];
    self.cameraButton.hidden = videoMuted;
    self.speakerButton.hidden = !videoMuted;
    
    [self.agoraKit muteLocalVideoStream:videoMuted];
    
    [self setVideoMuted:videoMuted forUid:0];
    [self updateSelfViewVisiable];
}

- (void)setSpeakerEnabled:(BOOL)speakerEnabled {
    _speakerEnabled = speakerEnabled;
    [self.speakerButton setImage:[UIImage imageNamed:(speakerEnabled ? @"btn_speaker_blue" : @"btn_speaker")] forState:UIControlStateNormal];
    [self.speakerButton setImage:[UIImage imageNamed:(speakerEnabled ? @"btn_speaker" : @"btn_speaker_blue")] forState:UIControlStateHighlighted];
    
    [self.agoraKit setEnableSpeakerphone:speakerEnabled];
}

/*---------------------------------------------------FaceUnity对接---------------------------------------------------*/
// 设置视频回调
- (void)setIsFiltering:(BOOL)isFiltering
{
    _isFiltering = isFiltering;
    if (self.agoraKit) {
        if (_isFiltering) {
            [AGVideoPreProcessing registerVideoPreprocessing: self.agoraKit];
        }else
        {
            [AGVideoPreProcessing deregisterVideoPreprocessing: self.agoraKit];
        }
    }
}

- (void)setShouldShowFuDemoBar:(BOOL)shouldShowFuDemoBar
{
    _shouldShowFuDemoBar = shouldShowFuDemoBar;
    
    if (shouldShowFuDemoBar) {
        if (CGAffineTransformEqualToTransform(self.fuDemoBar.transform, CGAffineTransformIdentity)) {
            [UIView animateWithDuration:0.5 animations:^{
                self.fuDemoBar.transform = CGAffineTransformMakeTranslation(0, -self.fuDemoBar.frame.size.height);
            }];
        }
    }else
    {
        [UIView animateWithDuration:0.5 animations:^{
            self.fuDemoBar.transform = CGAffineTransformIdentity;
        }];
    }
}

/**
 FUAPIDemoBar不是我们的交付内容，它的作用仅局限于我们的Demo演示，客户可以选择使用，但我们不会提供与之相关的技术支持或定制需求开发

 @return FUAPIDemoBar
 */
- (FUAPIDemoBar *)fuDemoBar
{
    if (!_fuDemoBar) {
        
        _fuDemoBar = [[FUAPIDemoBar alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, 208)];
        
        _fuDemoBar.itemsDataSource =  [FUManager shareManager].itemsDataSource;
        _fuDemoBar.filtersDataSource = [FUManager shareManager].filtersDataSource;
        
        _fuDemoBar.selectedItem = [FUManager shareManager].selectedItem;      /**选中的道具名称*/
        _fuDemoBar.selectedFilter = [FUManager shareManager].selectedFilter;  /**选中的滤镜名称*/
        _fuDemoBar.beautyLevel = [FUManager shareManager].beautyLevel;        /**美白 (0~1)*/
        _fuDemoBar.redLevel = [FUManager shareManager].redLevel;              /**红润 (0~1)*/
        _fuDemoBar.selectedBlur = [FUManager shareManager].selectedBlur;      /**磨皮(0、1、2、3、4、5、6)*/
        _fuDemoBar.faceShape = [FUManager shareManager].faceShape;            /**美型类型 (0、1、2、3) 默认：3，女神：0，网红：1，自然：2*/
        _fuDemoBar.faceShapeLevel = [FUManager shareManager].faceShapeLevel;  /**美型等级 (0~1)*/
        _fuDemoBar.enlargingLevel = [FUManager shareManager].enlargingLevel;  /**大眼 (0~1)*/
        _fuDemoBar.thinningLevel = [FUManager shareManager].thinningLevel;    /**瘦脸 (0~1)*/
        
        _fuDemoBar.delegate = self;
    }
    
    return _fuDemoBar;
}

#pragma -FUAPIDemoBarDelegate
- (void)demoBarDidSelectedItem:(NSString *)item
{
    //TODO: 调用FUManager单例的loadItem:方法，切换道具
    [[FUManager shareManager] loadItem:item];
    
}

/**设置美颜参数*/
- (void)demoBarBeautyParamChanged
{
    [self syncBeautyParams];
}

- (void)syncBeautyParams
{
    [FUManager shareManager].selectedFilter = _fuDemoBar.selectedFilter;
    [FUManager shareManager].selectedBlur = _fuDemoBar.selectedBlur;
    [FUManager shareManager].beautyLevel = _fuDemoBar.beautyLevel;
    [FUManager shareManager].redLevel = _fuDemoBar.redLevel;
    [FUManager shareManager].faceShape = _fuDemoBar.faceShape;
    [FUManager shareManager].faceShapeLevel = _fuDemoBar.faceShapeLevel;
    [FUManager shareManager].thinningLevel = _fuDemoBar.thinningLevel;
    [FUManager shareManager].enlargingLevel = _fuDemoBar.enlargingLevel;
}

//MARK: - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([NSStringFromClass([touch.view class]) isEqualToString:@"AgoraVideoRenderIosView"] || touch.view == self.controlView) {
        return YES;
    }
    return  NO;
}
/*---------------------------------------------------FaceUnity对接---------------------------------------------------*/

- (void)viewDidLoad {
    [super viewDidLoad];
    self.videoSessions = [[NSMutableArray alloc] init];
    
    self.roomNameLabel.text = self.roomName;
    [self.backgroundTap requireGestureRecognizerToFail:self.backgroundDoubleTap];
    
    [self loadAgoraKit];
    
    // 开启外部视频回调
    self.isFiltering = YES;
    
    // 加载贴纸道具及美颜道具
    [[FUManager shareManager] loadItems];
    
    [self.view addSubview:self.fuDemoBar];
    
    // 显示fuDemoBar
    [self performSelector:@selector(doBackTapped:) withObject:NULL afterDelay:0.5];
}

- (IBAction)doMuteVideoPressed:(UIButton *)sender {
    self.videoMuted = !self.videoMuted;
}

- (IBAction)doMuteAudioPressed:(UIButton *)sender {
    self.audioMuted = !self.audioMuted;
}

- (IBAction)doCameraPressed:(UIButton *)sender {
    [self.agoraKit switchCamera];
}

- (IBAction)doSpeakerPressed:(UIButton *)sender {
    self.speakerEnabled = !self.speakerEnabled;
}

- (IBAction)doClosePressed:(UIButton *)sender {
    [self leaveChannel];
}

- (IBAction)doBackTapped:(UITapGestureRecognizer *)sender {
    self.shouldHideFlowViews = !self.shouldHideFlowViews;
    
    // 显示／隐藏fuDemoBar
    self.shouldShowFuDemoBar = self.shouldHideFlowViews;
}

- (IBAction)doBackDoubleTapped:(UITapGestureRecognizer *)sender {
    if (!self.doubleClickFullSession) {
        NSInteger tappedIndex = [self.videoViewLayouter responseIndexOfLocation:[sender locationInView:self.containerView]];
        if (tappedIndex >= 0 && tappedIndex < self.videoSessions.count) {
            self.doubleClickFullSession = self.videoSessions[tappedIndex];
        }
    } else {
        self.doubleClickFullSession = nil;
    }
}

- (void)updateInterfaceWithSessions:(NSArray *)sessions targetSize:(CGSize)targetSize animation:(BOOL)animation {
    if (animation) {
        [UIView animateWithDuration:0.3 animations:^{
            [self updateInterfaceWithSessions:sessions targetSize:targetSize];
            [self.view layoutIfNeeded];
        }];
    } else {
        [self updateInterfaceWithSessions:sessions targetSize:targetSize];
    }
}

- (void)updateInterfaceWithSessions:(NSArray *)sessions targetSize:(CGSize)targetSize {
    if (!sessions.count) {
        return;
    }
    
    VideoSession *selfSession = sessions.firstObject;
    self.videoViewLayouter.selfView = selfSession.hostingView;
    self.videoViewLayouter.selfSize = selfSession.size;
    self.videoViewLayouter.targetSize = targetSize;
    
    NSMutableArray *peerVideoViews = [[NSMutableArray alloc] init];
    for (NSInteger i = 1; i < sessions.count; ++i) {
        VideoSession *session = sessions[i];
        [peerVideoViews addObject:session.hostingView];
    }
    self.videoViewLayouter.videoViews = peerVideoViews;
    self.videoViewLayouter.fullView = self.doubleClickFullSession.hostingView;
    self.videoViewLayouter.containerView = self.containerView;
    
    [self.videoViewLayouter layoutVideoViews];
    [self updateSelfViewVisiable];
    
    if (sessions.count >= 3) {
        self.backgroundDoubleTap.enabled = YES;
    } else {
        self.backgroundDoubleTap.enabled = NO;
        self.doubleClickFullSession = nil;
    }
}

- (void)setIdleTimerActive:(BOOL)active {
    [UIApplication sharedApplication].idleTimerDisabled = !active;
}

- (void)addLocalSession {
    VideoSession *localSession = [VideoSession localSession];
    [self.videoSessions addObject:localSession];
    [self.agoraKit setupLocalVideo:localSession.canvas];
    [self updateInterfaceWithSessions:self.videoSessions targetSize:self.containerView.frame.size animation:YES];
}

- (VideoSession *)fetchSessionOfUid:(NSUInteger)uid {
    for (VideoSession *session in self.videoSessions) {
        if (session.uid == uid) {
            return session;
        }
    }
    return nil;
}

- (VideoSession *)videoSessionOfUid:(NSUInteger)uid {
    VideoSession *fetchedSession = [self fetchSessionOfUid:uid];
    if (fetchedSession) {
        return fetchedSession;
    } else {
        VideoSession *newSession = [[VideoSession alloc] initWithUid:uid];
        [self.videoSessions addObject:newSession];
        [self updateInterfaceWithSessions:self.videoSessions targetSize:self.containerView.frame.size animation:YES];
        return newSession;
    }
}

- (void)setVideoMuted:(BOOL)muted forUid:(NSUInteger)uid {
    VideoSession *fetchedSession = [self fetchSessionOfUid:uid];
    fetchedSession.isVideoMuted = muted;
}

- (void)updateSelfViewVisiable {
    UIView *selfView = self.videoSessions.firstObject.hostingView;
    if (self.videoSessions.count == 2) {
        selfView.hidden = self.videoMuted;
    } else {
        selfView.hidden = false;
    }
}

- (void)alertString:(NSString *)string {
    if (!string.length) {
        return;
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:string preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)leaveChannel {
    
    // 关闭视频回调
    self.isFiltering = NO;
    
    //TODO: 调用FUManager单例的destoryItems方法，销毁faceunity全部道具
    [[FUManager shareManager] destoryItems];
    
    [self.agoraKit setupLocalVideo:nil];
    [self.agoraKit leaveChannel:nil];
    [self.agoraKit stopPreview];
    
    for (VideoSession *session in self.videoSessions) {
        [session.hostingView removeFromSuperview];
    }
    [self.videoSessions removeAllObjects];
    
    [self setIdleTimerActive:YES];
    
    if ([self.delegate respondsToSelector:@selector(roomVCNeedClose:)]) {
        [self.delegate roomVCNeedClose:self];
    }
}

//MARK: - Agora Media SDK
- (void)loadAgoraKit {
    self.agoraKit = [AgoraRtcEngineKit sharedEngineWithAppId:[KeyCenter AppId] delegate:self];
    [self.agoraKit setChannelProfile:AgoraRtc_ChannelProfile_Communication];
    [self.agoraKit enableVideo];
    [self.agoraKit setVideoProfile:self.videoProfile swapWidthAndHeight:NO];
    
    [self addLocalSession];
    [self.agoraKit startPreview];
    
    int code = [self.agoraKit joinChannelByKey:nil channelName:self.roomName info:nil uid:0 joinSuccess:nil];
    if (code == 0) {
        [self setIdleTimerActive:NO];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self alertString:[NSString stringWithFormat:@"Join channel failed: %d", code]];
        });
    }
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine firstRemoteVideoDecodedOfUid:(NSUInteger)uid size:(CGSize)size elapsed:(NSInteger)elapsed {
    VideoSession *userSession = [self videoSessionOfUid:uid];
    userSession.size = size;
    [self.agoraKit setupRemoteVideo:userSession.canvas];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine firstLocalVideoFrameWithSize:(CGSize)size elapsed:(NSInteger)elapsed {
    if (self.videoSessions.count) {
        VideoSession *selfSession = self.videoSessions.firstObject;
        selfSession.size = size;
        [self updateInterfaceWithSessions:self.videoSessions targetSize:self.containerView.frame.size animation:NO];
    }
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOfflineOfUid:(NSUInteger)uid reason:(AgoraRtcUserOfflineReason)reason {
    VideoSession *deleteSession;
    for (VideoSession *session in self.videoSessions) {
        if (session.uid == uid) {
            deleteSession = session;
        }
    }
    
    if (deleteSession) {
        [self.videoSessions removeObject:deleteSession];
        [deleteSession.hostingView removeFromSuperview];
        [self updateInterfaceWithSessions:self.videoSessions targetSize:self.containerView.frame.size animation:YES];
        
        if (deleteSession == self.doubleClickFullSession) {
            self.doubleClickFullSession = nil;
        }
    }
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didVideoMuted:(BOOL)muted byUid:(NSUInteger)uid {
    [self setVideoMuted:muted forUid:uid];
}
@end
