//
//  AGVideoPreProcessing.m
//  OpenVideoCall
//
//  Created by Alex Zheng on 7/28/16.
//  Copyright © 2016 Agora.io All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AGVideoPreProcessing.h"

#import <AgoraRtcEngineKit/AgoraRtcEngineKit.h>
#import <AgoraRtcEngineKit/IAgoraRtcEngine.h>
#import <AgoraRtcEngineKit/IAgoraMediaEngine.h>
#import <string.h>

#import "FUManager.h"

class AgoraAudioFrameObserver : public agora::media::IAudioFrameObserver
{
public:
  virtual bool onRecordAudioFrame(AudioFrame& audioFrame) override
  {
    return true;
  }
  virtual bool onPlaybackAudioFrame(AudioFrame& audioFrame) override
  {
    return true;
  }
  virtual bool onPlaybackAudioFrameBeforeMixing(unsigned int uid, AudioFrame& audioFrame) override
  {
    return true;
  }
};

class AgoraVideoFrameObserver : public agora::media::IVideoFrameObserver
{
public:
  virtual bool onCaptureVideoFrame(VideoFrame& videoFrame) override
  {
      //TODO: 调用FUManager单例的renderItemsToYUVFrame: u: v: ystride: ustride: vstride: width: height:方法，将道具绘制到YUVFrame
      [[FUManager shareManager] renderItemsToYUVFrame:videoFrame.yBuffer u:videoFrame.uBuffer v:videoFrame.vBuffer ystride:videoFrame.yStride ustride:videoFrame.uStride vstride:videoFrame.vStride width:videoFrame.width height:videoFrame.height];
      
    return true;
  }
  virtual bool onRenderVideoFrame(unsigned int uid, VideoFrame& videoFrame) override
  {
    return true;
  }
};

//static AgoraAudioFrameObserver s_audioFrameObserver;
static AgoraVideoFrameObserver s_videoFrameObserver;

@implementation AGVideoPreProcessing


+ (int) registerVideoPreprocessing: (AgoraRtcEngineKit*) kit
{
  if (!kit) {
    return -1;
  }
  
  agora::rtc::IRtcEngine* rtc_engine = (agora::rtc::IRtcEngine*)kit.getNativeHandle;
  agora::util::AutoPtr<agora::media::IMediaEngine> mediaEngine;
  mediaEngine.queryInterface(rtc_engine, agora::rtc::AGORA_IID_MEDIA_ENGINE);
  if (mediaEngine)
  {
    //mediaEngine->registerAudioFrameObserver(&s_audioFrameObserver);
    mediaEngine->registerVideoFrameObserver(&s_videoFrameObserver);
  }
  return 0;
}

+ (int) deregisterVideoPreprocessing: (AgoraRtcEngineKit*) kit
{
  if (!kit) {
    return -1;
  }
  
  agora::rtc::IRtcEngine* rtc_engine = (agora::rtc::IRtcEngine*)kit.getNativeHandle;
  agora::util::AutoPtr<agora::media::IMediaEngine> mediaEngine;
  mediaEngine.queryInterface(rtc_engine, agora::rtc::AGORA_IID_MEDIA_ENGINE);
  if (mediaEngine)
  {
    //mediaEngine->registerAudioFrameObserver(NULL);
    mediaEngine->registerVideoFrameObserver(NULL);
  }
  return 0;
}

@end
