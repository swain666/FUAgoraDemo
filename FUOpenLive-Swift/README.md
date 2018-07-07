# FUOpenLive-swift 快速接入文档

FUOpenLive-swift 是集成了 [Faceunity](https://github.com/Faceunity/FULiveDemo/tree/dev) 面部跟踪和虚拟道具功能 和 声网视频直播 功能的 swift 版本 Demo。

本文是 FaceUnity SDK 快速对接声网视频直播的导读说明，关于 FaceUnity SDK 的更多详细说明，请参看 [FULiveDemo](https://github.com/Faceunity/FULiveDemo/tree/dev)

注：本例是示例 Demo ,仅在 首页 --> Broadcaster 加入了 FaceUnity 效果，如需更多接入用户可参考 Broadcaster。


## 快速集成方法

### 一、获取视频数据输出并添加本地预览页面

1、将 FUCamera 和 FUOpenGLView 两个类拖入工程

2、添加 swfit/OC 桥接文件，并引入头文件

```C
#import "FUManager.h"
#import <FUAPIDemoBar/FUAPIDemoBar.h>
```



3、创建属性并加载，遵循代理

```c
lazy var camera: FUCamera = {
    let camera = FUCamera.init()
    camera.delegate = self
    return camera
}()

lazy var glView : FUOpenGLView = {
    let view = FUOpenGLView.init(frame: UIScreen.main.bounds)
    return view
}()
```

4、开始采集，并 实现代理方法如下，在此方法中可以获取原始视频数据。

```c
extension LiveRoomViewController : FUCameraDelegate {

    func didOutputVideoSampleBuffer(_ sampleBuffer: CMSampleBuffer!) {
        
        // 通过下面这两行可以将画面绘制到屏幕上
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        glView.display(pixelBuffer)
    }
}
```

### 二、导入 SDK

将 FaceUnity 文件夹全部拖入工程中，并且添加依赖库 `OpenGLES.framework`、`Accelerate.framework`、`CoreMedia.framework`、`AVFoundation.framework`、`stdc++.tbd`

### 三、快速加载道具

在 `viewDidLoad() ` 中调用快速加载道具函数，该函数会创建一个美颜道具及指定的贴纸道具。

```c
FUManager.share().loadItems()
```

注：FUManager 的 shareManager 函数中会对 SDK 进行初始化，并设置默认的美颜参数。

### 四、图像处理

在 LiveRoomViewController.swift 的 onFrameAvailable 视频回调中处理图像：

```c
extension LiveRoomViewController : FUCameraDelegate {

    func didOutputVideoSampleBuffer(_ sampleBuffer: CMSampleBuffer!) {

        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)

        FUManager.share().renderItems(to: pixelBuffer)
        
        glView.display(pixelBuffer)
        
            
        // push video frame to agora
        let videoFrame = AgoraVideoFrame.init()
        videoFrame.format = 12
        videoFrame.textureBuf = pixelBuffer
        videoFrame.time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        rtcEngine.pushExternalVideoFrame(videoFrame)
    }
}
```

### 五、切换道具及调整美颜参数

本例中通过添加 FUAPIDemoBar 来实现切换道具及调整美颜参数的具体实现，FUAPIDemoBar 是快速集成用的UI，客户可自定义UI。

在 LiveRoomViewController.m  中添加 demoBar 属性，并实现 demoBar 代理方法，以进一步实现道具的切换及美颜参数的调整。

```
lazy var demoBar : FUAPIDemoBar = {
        let demoBar = FUAPIDemoBar.init(frame: CGRect.init(x: 0, y: UIScreen.main.bounds.size.height - 180, width: UIScreen.main.bounds.size.width, height: 164))
        
        demoBar.itemsDataSource = FUManager.share().itemsDataSource;
        demoBar.selectedItem = FUManager.share().selectedItem ;

        demoBar.filtersDataSource = FUManager.share().filtersDataSource ;
        demoBar.beautyFiltersDataSource = FUManager.share().beautyFiltersDataSource ;
        demoBar.filtersCHName = FUManager.share().filtersCHName ;
        demoBar.selectedFilter = FUManager.share().selectedFilter ;
        demoBar.setFilterLevel(FUManager.share().selectedFilterLevel, forFilter: FUManager.share().selectedFilter)

        demoBar.skinDetectEnable = FUManager.share().skinDetectEnable;
        demoBar.blurShape = FUManager.share().blurShape ;
        demoBar.blurLevel = FUManager.share().blurLevel ;
        demoBar.whiteLevel = FUManager.share().whiteLevel ;
        demoBar.redLevel = FUManager.share().redLevel;
        demoBar.eyelightingLevel = FUManager.share().eyelightingLevel ;
        demoBar.beautyToothLevel = FUManager.share().beautyToothLevel ;
        demoBar.faceShape = FUManager.share().faceShape ;

        demoBar.enlargingLevel = FUManager.share().enlargingLevel ;
        demoBar.thinningLevel = FUManager.share().thinningLevel ;
        demoBar.enlargingLevel_new = FUManager.share().enlargingLevel_new ;
        demoBar.thinningLevel_new = FUManager.share().thinningLevel_new ;
        demoBar.jewLevel = FUManager.share().jewLevel ;
        demoBar.foreheadLevel = FUManager.share().foreheadLevel ;
        demoBar.noseLevel = FUManager.share().noseLevel ;
        demoBar.mouthLevel = FUManager.share().mouthLevel ;
        
        demoBar.delegate = self as FUAPIDemoBarDelegate

        return demoBar
    }()
```

```C
extension LiveRoomViewController : FUAPIDemoBarDelegate {
    func demoBarBeautyParamChanged() {

        FUManager.share().skinDetectEnable = demoBar.skinDetectEnable;
        FUManager.share().blurShape = demoBar.blurShape;
        FUManager.share().blurLevel = demoBar.blurLevel ;
        FUManager.share().whiteLevel = demoBar.whiteLevel;
        FUManager.share().redLevel = demoBar.redLevel;
        FUManager.share().eyelightingLevel = demoBar.eyelightingLevel;
        FUManager.share().beautyToothLevel = demoBar.beautyToothLevel;
        FUManager.share().faceShape = demoBar.faceShape;
        FUManager.share().enlargingLevel = demoBar.enlargingLevel;
        FUManager.share().thinningLevel = demoBar.thinningLevel;
        FUManager.share().enlargingLevel_new = demoBar.enlargingLevel_new;
        FUManager.share().thinningLevel_new = demoBar.thinningLevel_new;
        FUManager.share().jewLevel = demoBar.jewLevel;
        FUManager.share().foreheadLevel = demoBar.foreheadLevel;
        FUManager.share().noseLevel = demoBar.noseLevel;
        FUManager.share().mouthLevel = demoBar.mouthLevel;

        FUManager.share().selectedFilter = demoBar.selectedFilter ;
        FUManager.share().selectedFilterLevel = demoBar.selectedFilterLevel;
    }

    func demoBarDidSelectedItem(_ itemName: String!) {

        FUManager.share().loadItem(itemName)
    }
}
```

### 六、道具销毁

直播结束时结束时需要调用 `[[FUManager shareManager] destoryItems]`  销毁道具。



**快速集成完毕，关于 FaceUnity SDK 的更多详细说明，请参看 [FULiveDemo](https://github.com/Faceunity/FULiveDemo/tree/dev)**