# FUOpenLive-OC 快速接入文档

FUOpenLive-OC 是集成了 [Faceunity](https://github.com/Faceunity/FULiveDemo/tree/dev) 面部跟踪和虚拟道具功能 和 声网视频直播 功能的 OC 版本 Demo。

本文是 FaceUnity SDK 快速对接声网视频直播的导读说明，关于 FaceUnity SDK 的更多详细说明，请参看 [FULiveDemo](https://github.com/Faceunity/FULiveDemo/tree/dev)

注：本例是示例 Demo ,仅在 首页 --> Broadcaster 加入了 FaceUnity 效果，如需更多接入用户可参考 Broadcaster。


## 快速集成方法

### 一、获取视频数据输出并添加本地预览页面

1、将 FUCamera 和 FUOpenGLView 两个类拖入工程

2、创建属性并加载，遵循代理

```C

#import "FUCamera.h"
#import "FUOpenGLView.h"

@property (nonatomic, strong) FUCamera *camera ;
@property (nonatomic, strong) FUOpenGLView *glView ;


self.camera = [[FUCamera alloc] init];
self.camera.delegate = self ;
    
self.glView = [[FUOpenGLView alloc] initWithFrame:self.view.bounds];
[self.remoteContainerView addSubview:self.glView];
```

3、开始采集，并 实现代理方法如下，在此方法中可以获取原始视频数据。

```C
-(void)didOutputVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    
    // 通过下面这两行可以将画面绘制到屏幕上
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) ;
    [self.glView displayPixelBuffer:pixelBuffer];
}
```

### 二、导入 SDK

1、将 FaceUnity 文件夹全部拖入工程中，并且添加依赖库 `OpenGLES.framework`、`Accelerate.framework`、`CoreMedia.framework`、`AVFoundation.framework`、`stdc++.tbd`



### 三、快速加载道具

在 `viewDidLoad:` 中调用快速加载道具函数，该函数会创建一个美颜道具及指定的贴纸道具。

```c
[[FUManager shareManager] loadItems];
```

注：FUManager 的 shareManager 函数中会对 SDK 进行初始化，并设置默认的美颜参数。

### 四、图像处理并发送给声网SDK

在 LiveRoomViewController.m 的 onFrameAvailable 视频回调中处理图像：

```c
-(void)didOutputVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) ;
    
    [[FUManager shareManager] renderItemsToPixelBuffer:pixelBuffer];
    
    [self.glView displayPixelBuffer:pixelBuffer];
    
    
    // push video frame to agora
    AgoraVideoFrame *videoFrame = [[AgoraVideoFrame alloc] init];
    videoFrame.format = 12;
    videoFrame.textureBuf = pixelBuffer;
    videoFrame.time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    [self.rtcEngine pushExternalVideoFrame:videoFrame];
}
```

### 五、切换道具及调整美颜参数

本例中通过添加 FUAPIDemoBar 来实现切换道具及调整美颜参数的具体实现，FUAPIDemoBar 是快速集成用的UI，客户可自定义UI。

在 LiveRoomViewController.m  中添加 demoBar 属性，并实现 demoBar 代理方法，以进一步实现道具的切换及美颜参数的调整。

```C
-(FUAPIDemoBar *)demoBar {
    if (!_demoBar) {
        _demoBar = [[FUAPIDemoBar alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 180, self.view.frame.size.width, 164)];
        
        _demoBar.itemsDataSource = [FUManager shareManager].itemsDataSource;
        _demoBar.selectedItem = [FUManager shareManager].selectedItem ;
        
        _demoBar.filtersDataSource = [FUManager shareManager].filtersDataSource ;
        _demoBar.beautyFiltersDataSource = [FUManager shareManager].beautyFiltersDataSource ;
        _demoBar.filtersCHName = [FUManager shareManager].filtersCHName ;
        _demoBar.selectedFilter = [FUManager shareManager].selectedFilter ;
        [_demoBar setFilterLevel:[FUManager shareManager].selectedFilterLevel forFilter:[FUManager shareManager].selectedFilter] ;
        
        _demoBar.skinDetectEnable = [FUManager shareManager].skinDetectEnable;
        _demoBar.blurShape = [FUManager shareManager].blurShape ;
        _demoBar.blurLevel = [FUManager shareManager].blurLevel ;
        _demoBar.whiteLevel = [FUManager shareManager].whiteLevel ;
        _demoBar.redLevel = [FUManager shareManager].redLevel;
        _demoBar.eyelightingLevel = [FUManager shareManager].eyelightingLevel ;
        _demoBar.beautyToothLevel = [FUManager shareManager].beautyToothLevel ;
        _demoBar.faceShape = [FUManager shareManager].faceShape ;
        
        _demoBar.enlargingLevel = [FUManager shareManager].enlargingLevel ;
        _demoBar.thinningLevel = [FUManager shareManager].thinningLevel ;
        _demoBar.enlargingLevel_new = [FUManager shareManager].enlargingLevel_new ;
        _demoBar.thinningLevel_new = [FUManager shareManager].thinningLevel_new ;
        _demoBar.jewLevel = [FUManager shareManager].jewLevel ;
        _demoBar.foreheadLevel = [FUManager shareManager].foreheadLevel ;
        _demoBar.noseLevel = [FUManager shareManager].noseLevel ;
        _demoBar.mouthLevel = [FUManager shareManager].mouthLevel ;
        
        _demoBar.delegate = self;
    }
    return _demoBar ;
}

/**      FUAPIDemoBarDelegate       **/
- (void)demoBarDidSelectedItem:(NSString *)itemName {
    
    [[FUManager shareManager] loadItem:itemName];
}

- (void)demoBarBeautyParamChanged {
    
    [FUManager shareManager].skinDetectEnable = _demoBar.skinDetectEnable;
    [FUManager shareManager].blurShape = _demoBar.blurShape;
    [FUManager shareManager].blurLevel = _demoBar.blurLevel ;
    [FUManager shareManager].whiteLevel = _demoBar.whiteLevel;
    [FUManager shareManager].redLevel = _demoBar.redLevel;
    [FUManager shareManager].eyelightingLevel = _demoBar.eyelightingLevel;
    [FUManager shareManager].beautyToothLevel = _demoBar.beautyToothLevel;
    [FUManager shareManager].faceShape = _demoBar.faceShape;
    [FUManager shareManager].enlargingLevel = _demoBar.enlargingLevel;
    [FUManager shareManager].thinningLevel = _demoBar.thinningLevel;
    [FUManager shareManager].enlargingLevel_new = _demoBar.enlargingLevel_new;
    [FUManager shareManager].thinningLevel_new = _demoBar.thinningLevel_new;
    [FUManager shareManager].jewLevel = _demoBar.jewLevel;
    [FUManager shareManager].foreheadLevel = _demoBar.foreheadLevel;
    [FUManager shareManager].noseLevel = _demoBar.noseLevel;
    [FUManager shareManager].mouthLevel = _demoBar.mouthLevel;
    
    [FUManager shareManager].selectedFilter = _demoBar.selectedFilter ;
    [FUManager shareManager].selectedFilterLevel = _demoBar.selectedFilterLevel;
}
```



### 六、道具销毁

直播结束时结束时需要调用 `[[FUManager shareManager] destoryItems]`  销毁道具。



**快速集成完毕，关于 FaceUnity SDK 的更多详细说明，请参看 [FULiveDemo](https://github.com/Faceunity/FULiveDemo/tree/dev)**