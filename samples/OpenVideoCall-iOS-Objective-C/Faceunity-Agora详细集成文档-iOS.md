# Open Video Call iOS for Objective-C

这个示例项目演示了如何在Agora视频SDKDemo中快速集成FaceunitySDK。

# 对接步骤

## 注册视频回调
首先在工程中添加 `AGVideoPreProcessing.h` 及 `AGVideoPreProcessing.m` 两个文件，并在 `RoomViewController.m` 中注册视频回调，步骤如下：

声明 isFiltering 属性：

	@property (assign, nonatomic) BOOL isFiltering;
重写set方法：

```C
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
```
在 `RoomViewController.m` 的 `viewDidLoad` 中将 `isFiltering` 赋值为 YES 注册视频回调，并在 `leaveChannel` 中将 `isFiltering` 赋值为 NO 关闭视频回调

## 添加 FaceunitySDK 及相关代码文件
需要添加的文件列表如下：

`FaceUnity-SDK-iOS`：FaceunitySDK

`items`：示例道具

`FUManager`：快速集成的管理类，如何调用FaceunitySDk接口的代码都封装在这个类中

`FUAPIDemoBar`：快速集成UI的framewok

`authpack.h`：鉴权证书

以上文件都包含在 `Faceunity` 文件夹下，将 `Faceunity` 文件夹添加到工程目录中即可。

## 道具的加载与销毁
### 进入房间时加载道具：
在 `RoomViewController.m` 的 `viewDidLoad` 中调用 `[[FUManager shareManager] loadItems]` 加载贴纸道具及美颜道具

### 离开房间时销毁道具：
在 `RoomViewController.m` 的 `leaveChannel` 中调用 `[[FUManager shareManager] destoryFaceunityItems]` 销毁faceunity全部道具。

## 图像处理
在 `AGVideoPreProcessing.m` 的 `onCaptureVideoFrame` 视频回调接口中先注释掉原有的图像处理代码：

```C
//    int width = videoFrame.width;
//    int height = videoFrame.height;
//    
//    memset(videoFrame.uBuffer, 128, videoFrame.uStride*height/2);
//    memset(videoFrame.vBuffer, 128, videoFrame.vStride*height/2);
```

然后调用以下方法对视频图像进行处理即可：

```C
[[FUManager shareManager] processYUVFrame:videoFrame.yBuffer u:videoFrame.uBuffer v:videoFrame.vBuffer ystride:videoFrame.yStride ustride:videoFrame.uStride vstride:videoFrame.vStride width:videoFrame.width height:videoFrame.height];
```
 
## 添加界面（可选）

## 集成 FUAPIDemoBar

### 创建FUAPIDemoBar：
我们在一开始已经将 `FUAPIDemoBar.framework` 添加到工程中，现在在 `RoomViewController.m` 中声明 fuDemoBar 属性：

	@property (strong, nonatomic) FUAPIDemoBar *fuDemoBar;
	
使用懒加载模式创建 `fuDemoBar`：

```C
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

```
然后在 `viewDidLoad` 中将 `fuDemoBar` 添加到 `view` 上：

	[self.view addSubview:self.fuDemoBar];
这里初始化时将 `fuDemoBar` 的 `frame` 的 y 值设置在了 `view` 的最下方，所以这一步运行程序将无法看到 `fuDemoBar`，需要通过下一步的 UI 动画来触发  `fuDemoBar` 显示。

### 设置 `fuDemoBar` 显示及隐藏动画

在 `RoomViewController.m` 中声明 `shouldShowFuDemoBar` 属性：

	@property (assign, nonatomic) BOOL shouldShowFuDemoBar;
	
重写set方法设置 `fuDemoBar` 动画：

```C
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
```
然后通过点击屏幕来触发 `fuDemoBar` 动画，即在 `doBackTapped` 方法中设置 `shouldShowFuDemoBar` 的值，当原有UI显示时隐藏 `fuDemoBar`，当原有UI隐藏时显示 `fuDemoBar`：

    self.shouldShowFuDemoBar = self.shouldHideFlowViews;
    

### 修改手势代码使 `fuDemoBar` 可被点击
在添加了 `fuDemoBar` 后，因为原有手势存在的原因导致 `fuDemoBar` 无法被点击，因此需要修改一部分代码才能使 `fuDemoBar` 可被点击。
首先将 `RoomViewController.m` 中手势对象的 `delegate` 设置为 `self`，然后遵守并实现 `UIGestureRecognizerDelegate` 的 `shouldReceiveTouch` 方法，使只有点击空白区域时才允许接受touch操作：

```C
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([NSStringFromClass([touch.view class]) isEqualToString:@"AgoraVideoRenderIosView"] || touch.view == self.controlView) {
        return YES;
    }
    return  NO;
}

```

### 实现FUAPIDemoBarDelegate方法：
实现FUAPIDemoBarDelegate方法，以实现道具的切换及美颜参数的同步

切换道具：

```C
- (void)demoBarDidSelectedItem:(NSString *)item
{
    // 加载道具
    [[FUManager shareManager] loadItem:item];
}
```

同步美颜参数：

```C
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
```

## 添加icons图片资源
将附件中的 `fu_icons` 文件夹拷贝到 `Assets.xcassets` 文件夹中即可