# FUAgoraDemo 快速接入文档

FUAgoraDemo 是集成了 [Faceunity](https://github.com/Faceunity/FULiveDemo/tree/dev) 面部跟踪和虚拟道具功能 和 声网视频直播 功能的 Demo。

本文是 FaceUnity SDK 快速对接声网视频直播的导读说明，关于 FaceUnity SDK 的更多详细说明，请参看 [FULiveDemo](https://github.com/Faceunity/FULiveDemo/tree/dev)

注：本例是示例 Demo ,仅在 首页 --> Broadcaster 加入了 FaceUnity 效果，如需更多接入用户可参考 Broadcaster。


## 快速集成方法

### 一、获取视频数据输出

1、将 videoprp.framework 拖入工程

2、在 LiveRoomViewController.swift 中加入 YuvPreProcessor 属性，并遵循代理方法。

```C
//MARK: Thrid filter
    fileprivate lazy var yuvProcessor:YuvPreProcessor? = {
        let yuvProcessor = YuvPreProcessor()
        yuvProcessor.delegate = self as YuvPreProcessorProtocol
        return yuvProcessor
    }()
    fileprivate var shouldYuvProcessor = false {
        didSet {
            if shouldYuvProcessor {
                yuvProcessor?.turnOn()
            } else {
                yuvProcessor?.turnOff()
            }
        }
    }
```

3、实现代理方法如下，在此方法中可以获取原始视频数据，数据是 YVU 格式。

```C
//在这里处理视频数据，添加Faceunity特效
extension LiveRoomViewController: YuvPreProcessorProtocol {
    
    func onFrameAvailable(_ y: UnsafeMutablePointer<UInt8>, ubuf u: UnsafeMutablePointer<UInt8>, vbuf v: UnsafeMutablePointer<UInt8>, ystride: Int32, ustride: Int32, vstride: Int32, width: Int32, height: Int32) {
        
        // 此处可以获取视频数据
    }
}
```

### 二、导入 SDK

1、将 FaceUnity 文件夹全部拖入工程中，并且添加依赖库 `OpenGLES.framework`、`Accelerate.framework`、`CoreMedia.framework`、`AVFoundation.framework`、`stdc++.tbd`

2、添加 swfit/OC 桥接文件，并引入头文件

```c
#import "FUManager.h"
#import <FUAPIDemoBar/FUAPIDemoBar.h>
```

### 二、快速加载道具

在 `viewDidLoad:` 中调用快速加载道具函数，该函数会创建一个美颜道具及指定的贴纸道具。

```c
[[FUManager shareManager] loadItems];
```

注：FUManager 的 shareManager 函数中会对 SDK 进行初始化，并设置默认的美颜参数。

### 三、图像处理

在 LiveRoomViewController.swift 的 onFrameAvailable 视频回调中处理图像：

```c
func onFrameAvailable(_ y: UnsafeMutablePointer<UInt8>, ubuf u: UnsafeMutablePointer<UInt8>, vbuf v: UnsafeMutablePointer<UInt8>, ystride: Int32, ustride: Int32, vstride: Int32, width: Int32, height: Int32) {
        
        FUManager.share().renderItemsWith(y: y, u: u, v: v, ystride: ystride, ustride: ustride, vstride: vstride, width: width, height: height)
}
```

### 四、切换道具及调整美颜参数

本例中通过添加 FUAPIDemoBar 来实现切换道具及调整美颜参数的具体实现，FUAPIDemoBar 是快速集成用的UI，客户可自定义UI。

1、在 LiveRoomViewController.swift  对应的 storyboard 添加高度为 164 的 UIView 并将其 Class 设置为 FUAPIDemoBar。

2、在 LiveRoomViewController.swift  中添加 demoBar 属性，并实现 demoBar 代理方法，以进一步实现道具的切换及美颜参数的调整。

```C
@IBOutlet weak var demobar: FUAPIDemoBar! {
        
        didSet {
            demobar.itemsDataSource = FUManager.share().itemsDataSource;
            demobar.selectedItem = FUManager.share().selectedItem ;
            
            demobar.filtersDataSource = FUManager.share().filtersDataSource ;
            demobar.beautyFiltersDataSource = FUManager.share().beautyFiltersDataSource ;
            demobar.filtersCHName = FUManager.share().filtersCHName ;
            demobar.selectedFilter = FUManager.share().selectedFilter ;
            demobar.setFilterLevel(FUManager.share().selectedFilterLevel, forFilter: FUManager.share().selectedFilter)
            
            demobar.skinDetectEnable = FUManager.share().skinDetectEnable;
            demobar.blurShape = FUManager.share().blurShape ;
            demobar.blurLevel = FUManager.share().blurLevel ;
            demobar.whiteLevel = FUManager.share().whiteLevel ;
            demobar.redLevel = FUManager.share().redLevel;
            demobar.eyelightingLevel = FUManager.share().eyelightingLevel ;
            demobar.beautyToothLevel = FUManager.share().beautyToothLevel ;
            demobar.faceShape = FUManager.share().faceShape ;
            
            demobar.enlargingLevel = FUManager.share().enlargingLevel ;
            demobar.thinningLevel = FUManager.share().thinningLevel ;
            demobar.enlargingLevel_new = FUManager.share().enlargingLevel_new ;
            demobar.thinningLevel_new = FUManager.share().thinningLevel_new ;
            demobar.jewLevel = FUManager.share().jewLevel ;
            demobar.foreheadLevel = FUManager.share().foreheadLevel ;
            demobar.noseLevel = FUManager.share().noseLevel ;
            demobar.mouthLevel = FUManager.share().mouthLevel ;
            
            demobar.delegate = self as FUAPIDemoBarDelegate;
        }
    }
```

```C

extension LiveRoomViewController : FUAPIDemoBarDelegate {
    
    // 同步美颜参数
    func demoBarBeautyParamChanged() {
        
        FUManager.share().skinDetectEnable = demobar.skinDetectEnable;
        FUManager.share().blurShape = demobar.blurShape;
        FUManager.share().blurLevel = demobar.blurLevel ;
        FUManager.share().whiteLevel = demobar.whiteLevel;
        FUManager.share().redLevel = demobar.redLevel;
        FUManager.share().eyelightingLevel = demobar.eyelightingLevel;
        FUManager.share().beautyToothLevel = demobar.beautyToothLevel;
        FUManager.share().faceShape = demobar.faceShape;
        FUManager.share().enlargingLevel = demobar.enlargingLevel;
        FUManager.share().thinningLevel = demobar.thinningLevel;
        FUManager.share().enlargingLevel_new = demobar.enlargingLevel_new;
        FUManager.share().thinningLevel_new = demobar.thinningLevel_new;
        FUManager.share().jewLevel = demobar.jewLevel;
        FUManager.share().foreheadLevel = demobar.foreheadLevel;
        FUManager.share().noseLevel = demobar.noseLevel;
        FUManager.share().mouthLevel = demobar.mouthLevel;
        
        FUManager.share().selectedFilter = demobar.selectedFilter ;
        FUManager.share().selectedFilterLevel = demobar.selectedFilterLevel;
    }
    
    // 切换贴纸道具
    func demoBarDidSelectedItem(_ itemName: String!) {
        
        FUManager.share().loadItem(itemName)
    }
}
```

五、道具销毁


直播结束时结束时需要调用 `[[FUManager shareManager] destoryItems]`  销毁道具。

**快速集成完毕，关于 FaceUnity SDK 的更多详细说明，请参看 [FULiveDemo](https://github.com/Faceunity/FULiveDemo/tree/dev)**