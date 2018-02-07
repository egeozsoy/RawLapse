//
//  ViewController.swift
//  RawLapse
//
//  Created by Ege on 20.10.17.
//  Copyright © 2017 Ege. All rights reserved.
//

import UIKit
import Dispatch
import Photos
import AVFoundation
import MobileCoreServices
import ImageIO

class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate{
    /*
     Select a camera input.
     Create and configure a photo capture output.
     Configure the capture session by adding the camera input and the capture output.
     Optionally create and attach a preview view.
     Start the capture session.
     */
    
    //    data source Reference
    let pickerViewController = PickerViewController()
    //    camera Settings
    var captureSession = AVCaptureSession()
    var currentCamera: AVCaptureDevice?
    var photoOutput: AVCapturePhotoOutput?
    var photoSettings: AVCapturePhotoSettings?
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    var cameraPreviewLayerFrame: CGRect?
    //    captured photos as data objects
    var rawPhotoData: Data?
    var jpegPhotoData: Data?
    
    //    hud
    var hudActive = false
    var hudView: Hud?
    
    //    introView
    var introView: IntroView?
    
    //customSettings
    var buttonsSet = false
    var startBrightness : CGFloat?
    var uuid: String?
    var labelUpdateTimer: Timer?
    var forceLockScreenDimming = false
    let disabledColor = UIColor.init(white: 0.5, alpha: 0.5)
    var rotationAngle: Double = 0
    
    //    timelapse settings
    var timelapseTimer: Timer?
    var photoCounter = 0
    var activeTimelapse = false
    var lockAEButton: UIButton?
    var lockFocusButton:UIButton?
    var rawButton: UIButton?
    var privacyPolicyButton: UIButton?
    var secondInterval: Int?
    var amountOfPhotos: Int?
    var continuous: Bool?
    
    //    exportSettings
    var processedPhotoCounter = 0
    var createVideo = true
    var rawsToProcess = [URL]()
    var jpegsToProcess = [Data]()
    var images = [URL]()
    var mycircleBarObject: CircleProgressBar?
    var mycircleBar : CircleProgressBar?
    
    //    initialize
    let ruleOfThirdsViewer: UIImageView  = {
        let imageviewer = UIImageView()
        var image = UIImage(named: "ruleOfThirdsGrid")
        imageviewer.image = image
        imageviewer.translatesAutoresizingMaskIntoConstraints = false
        return imageviewer
    }()
    let sixteenByNineViewer: UIImageView  = {
        let imageviewer = UIImageView()
        var image = UIImage(named: "169")
        imageviewer.image = image
        imageviewer.translatesAutoresizingMaskIntoConstraints = false
        return imageviewer
    }()
    let middleScreenViewer: UIImageView  = {
        let imageviewer = UIImageView()
        var image = UIImage(named: "middleScreen")
        imageviewer.image = image
        imageviewer.translatesAutoresizingMaskIntoConstraints = false
        return imageviewer
    }()
    let shutterButton: UIButton = {
        let button = UIButton()
        var image = UIImage(named: "shutter_icon")
        image = image?.withRenderingMode(.alwaysTemplate)
        button.tintColor = UIColor.white
        button.setImage(image, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(startTimelapse), for: .touchUpInside)
        return button
    }()
    let settingsTextView:UITextView = {
        let tv = UITextView()
        tv.isEditable = false
        tv.backgroundColor = UIColor.clear
        tv.textColor = UIColor.white
        tv.textAlignment = .center
        tv.isSelectable = false
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    let hudButton:UIButton = {
        let button = UIButton()
        button.setTitle("HUD", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleHud), for: .touchUpInside)
        return button
    }()
    let slimTopBar: UIView = {
        let bar = UIView()
        bar.backgroundColor = UIColor.black
        bar.translatesAutoresizingMaskIntoConstraints = false
        return bar
    }()
    let bottomBar: UIView = {
        let bar = UIView()
        bar.backgroundColor = UIColor.black
        bar.translatesAutoresizingMaskIntoConstraints = false
        return bar
    }()
    let photoCounterLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    override var prefersStatusBarHidden: Bool {
        return true
    }
    override var shouldAutorotate: Bool{
        return false
    }
    
    //   MARK:  camera Setups
    func setupCaptureSession(){
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
    }
    
    func setupDevice(telephotoCamera telephoto:Bool){
        if telephoto{
            let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInTelephotoCamera] , mediaType: AVMediaType.video, position: AVCaptureDevice.Position.back)
            
            let device = deviceDiscoverySession.devices.first
            currentCamera = device
        }
        else{
            let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera] , mediaType: AVMediaType.video, position: AVCaptureDevice.Position.back)
            
            let device = deviceDiscoverySession.devices.first
            currentCamera = device
        }
    }
    
    func setupInputOutput(){
        do{
            guard let currentCamera = self.currentCamera else {
                self.shutterButton.tintColor = self.disabledColor
                self.showAlert(withTitle: "No Camera", withMessage: "Make sure your device supports a camera")
                return
            }
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentCamera)
            guard self.captureSession.canAddInput(captureDeviceInput) else { return }
            self.captureSession.addInput(captureDeviceInput)
            self.photoOutput = AVCapturePhotoOutput()
            guard self.captureSession.canAddOutput(self.photoOutput!) else { return }
            self.captureSession.addOutput(self.photoOutput!)
            try? currentCamera.lockForConfiguration()
            currentCamera.setExposureModeCustom(duration: currentCamera.activeFormat.maxExposureDuration, iso: currentCamera.activeFormat.minISO, completionHandler: nil)
            currentCamera.exposureMode = .continuousAutoExposure
            currentCamera.unlockForConfiguration()
            self.updateLabels()
        }
        catch let error {
            print(error)
        }
    }
    
    func extremeDarkness(turnOnExtreme active:Bool){
        guard let currentCamera = self.currentCamera else {
            self.shutterButton.tintColor = self.disabledColor
            self.showAlert(withTitle: "No Camera", withMessage: "Make sure your device supports a camera")
            return
        }
        try? currentCamera.lockForConfiguration()
        
        if active {
            currentCamera.exposureMode = .custom
            currentCamera.setExposureModeCustom(duration: currentCamera.activeFormat.maxExposureDuration, iso: currentCamera.activeFormat.maxISO, completionHandler: nil)
        }
        else{
            currentCamera.setExposureModeCustom(duration: currentCamera.activeFormat.maxExposureDuration, iso: currentCamera.activeFormat.minISO, completionHandler: nil)
            currentCamera.exposureMode = .continuousAutoExposure
        }
        currentCamera.unlockForConfiguration()
        self.updateLabels()
    }
    
    
    
    //    how to setup photoSettings
    func setupRawJpeg(rawSupported rawSupport: Bool){
        if rawSupport{
            guard let rawFormatType = photoOutput?.availableRawPhotoPixelFormatTypes.first else{
                setupRawJpeg(rawSupported: false)
                return
            }
            photoSettings = AVCapturePhotoSettings(rawPixelFormatType: rawFormatType)
        }
        else{
            photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])
        }
        guard let pSettings = photoSettings else{
            return
        }
        let preferedThumbnailFormat = pSettings.availableEmbeddedThumbnailPhotoCodecTypes.first
        pSettings.embeddedThumbnailPhotoFormat = [AVVideoCodecKey : preferedThumbnailFormat as Any , AVVideoWidthKey : 512 , AVVideoHeightKey: 512]
        
        photoOutput?.setPreparedPhotoSettingsArray([pSettings], completionHandler: nil)
    }
    
    func setupPreviewLayer(){
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        guard let cameraPreviewLayer = cameraPreviewLayer else{
            return
        }
        cameraPreviewLayer.videoGravity = .resizeAspect
        cameraPreviewLayer.frame = self.view.frame
        self.view.layer.insertSublayer(cameraPreviewLayer, at: 0)
        
        let  x = cameraPreviewLayer.frame.minX
        let width = cameraPreviewLayer.frame.width
        let height = cameraPreviewLayer.frame.height
        let wantedHeight = cameraPreviewLayer.frame.width * 4/3
        let y = (height - wantedHeight)/2
        cameraPreviewLayerFrame = CGRect(x: x, y: y, width: width , height: wantedHeight)
        setRuleOfThirdsViewer()
        setmiddleScreenViewer()
        setSixteenByNineViewer()
    }
    
    func startRunningCaptureSession(){
        captureSession.startRunning()
    }
    
    func lockUnlockExposureFocus(toggleExposure exposureToggle:Bool , toggleFocus focusToggle:Bool){
        if let lockedExposure = lockAEButton?.isSelected  , let lockedFocus = lockFocusButton?.isSelected{
            try? currentCamera?.lockForConfiguration()
            if(exposureToggle){
                if(lockedExposure){
                    currentCamera?.exposureMode = .locked
                }else{
                    currentCamera?.exposureMode = .continuousAutoExposure
                }
            }
            if(focusToggle){
                if(lockedFocus){
                    currentCamera?.focusMode = .locked
                }else{
                    currentCamera?.focusMode = .continuousAutoFocus
                }
            }
            currentCamera?.unlockForConfiguration()
        }
    }
    
    func handleExposureFocusTap(_ tap : UITapGestureRecognizer , changeExposure exposureNotLocked: Bool , changeFocus focusNotLocked:Bool){
        guard let cameraPreviewLayerFrame = cameraPreviewLayerFrame else{
            print("no preview layer")
            return
        }
        if(tap.location(in: self.view).y < (self.view.frame.height - cameraPreviewLayerFrame.height) / 2 || tap.location(in: self.view).y > (self.view.frame.height - cameraPreviewLayerFrame.height) / 2 + cameraPreviewLayerFrame.height ){
        }else{
            try? currentCamera?.lockForConfiguration()
            drawExposureCircle(tapPoint: tap.location(in: self.view))
            let x = tap.location(in: self.view).y / self.view.bounds.size.height
            let y = 1 - tap.location(in: self.view).x / self.view.bounds.size.width
            let point = CGPoint(x: x, y: y)
            if(exposureNotLocked && currentCamera?.exposureMode != .custom){
                currentCamera?.exposurePointOfInterest = point
                currentCamera?.exposureMode = .continuousAutoExposure
            }
            if(focusNotLocked){
                currentCamera?.focusPointOfInterest = CGPoint(x: x, y: y)
                currentCamera?.focusMode = .autoFocus
            }
            currentCamera?.unlockForConfiguration()
        }
        updateLabels()
    }
    
    func drawExposureCircle( tapPoint : CGPoint){
        let circlePath = UIBezierPath(arcCenter: tapPoint, radius: CGFloat(30), startAngle: CGFloat(0), endAngle:CGFloat(Double.pi * 2), clockwise: true)
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = circlePath.cgPath
        //change the fill color
        shapeLayer.fillColor = UIColor.clear.cgColor
        //you can change the stroke color
        shapeLayer.strokeColor = UIColor.orange.cgColor
        //you can change the line width
        shapeLayer.lineWidth = 3.0
        
        let circleView = UIView(frame: self.view.frame)
        circleView.layer.addSublayer(shapeLayer)
        self.view.addSubview(circleView)
        
        circleView.alpha = 0.0
        UIView.animate(withDuration: 1) {
            circleView.alpha = 0.9
        }
        UIView.animate(withDuration: 1, animations: {
            circleView.alpha = 0
        }) { (completed) in
            circleView.removeFromSuperview()
        }
    }
    
    @objc func handleSettingTap(_ tap : UITapGestureRecognizer ){
        if let lockedExposure = lockAEButton?.isSelected , let lockedFocus = lockFocusButton?.isSelected{
            handleExposureFocusTap(tap, changeExposure: !lockedExposure, changeFocus: !lockedFocus)
        }
    }
    
    @objc func handleSwiping(_ swipe: UISwipeGestureRecognizer){
        guard let currentCamera = currentCamera else {
            print("no camera")
            return
        }
        if currentCamera.exposureMode == .custom {return}
        try? currentCamera.lockForConfiguration()
        let newExposureBias = swipe.direction == .left ? currentCamera.exposureTargetBias - 1 : currentCamera.exposureTargetBias + 1
        if newExposureBias > -6 && newExposureBias < 6{
            currentCamera.setExposureTargetBias(newExposureBias, completionHandler: { (time) in
                self.updateLabels()
            })
        }
        currentCamera.unlockForConfiguration()
    }
    
    //    helper Functions
    func getSettingFromSettingsDic(settingToGet settingStr : String) -> Bool{
        guard let settingsDic = UserDefaults.standard.dictionary(forKey: "settinsgDic") as? [String:Bool] else{return false}
        if let settingBoolean = settingsDic[settingStr]{
            return settingBoolean
        }
        return false
    }
    
    func updateLabels(){
        if let camera = currentCamera {
            settingsTextView.text = "ISO: \(Int(camera.iso))\nShutter: 1/\(Int(1 / (camera.exposureDuration).seconds))\nEV:\(camera.exposureTargetBias)"
            if activeTimelapse == false && processedPhotoCounter > 0 {
                photoCounterLabel.text = "\(processedPhotoCounter)/\(photoCounter)"
            }
            else{
                if pickerViewController.continuous  {
                    photoCounterLabel.text = "\(photoCounter)/∞"
                }
                else{
                    photoCounterLabel.text = "\(photoCounter)/\(pickerViewController.amountOfPhotos)"
                }
            }
        }
        activateProgressBar(activeTimelapse: activeTimelapse)
        
//        UIDevice.current.isBatteryMonitoringEnabled = true
//        if UIDevice.current.batteryLevel < 0.05 && activeTimelapse == true {
//            stopTimeLapse()
//            showAlert(withTitle: "TimeLapse stopped", withMessage: "Because your battery is lower then %5")
//        }
    }
    
    func keepLabelsUpToDate(){
        labelUpdateTimer =  Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
            self.updateLabels()
        }
    }
    
    func startUpdateTimer(){
        if labelUpdateTimer == nil {
            keepLabelsUpToDate()
        }
    }
    
    func stopUpdateTimer(){
        if labelUpdateTimer != nil{
            labelUpdateTimer?.invalidate()
            labelUpdateTimer = nil
        }
    }
    
    @objc func adjustBrightness(notification: NSNotification){
        let device = notification.object as? UIDevice
        if device?.proximityState == true && activeTimelapse == true{
            UIScreen.main.brightness = 1.0
            Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: { (timer) in
                self.dimScreen()
            })
        }
    }
    
    func showAlert(withTitle title:String , withMessage message:String){
        let alert = UIAlertController(title: title,
                                      message:  message,
                                      preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    func fixBrightness(){
        if let brightness = self.startBrightness {
            UIScreen.main.brightness = brightness
        }
    }
    
    func dimScreen(){
        if let settingsDic = UserDefaults.standard.dictionary(forKey: "settinsgDic") as? [String:Bool]{
            if settingsDic[screenDimingStr] == true && forceLockScreenDimming == false {
                UIScreen.main.brightness = 0.0
            }
        }
    }
    
    func rawNotSupportedOnDevice() -> Bool {
        return (photoOutput?.availableRawPhotoFileTypes == nil  || photoOutput?.availableRawPhotoFileTypes.count == 0)
    }
    
    func resetParameters(){
        print("resetting")
        rawsToProcess = []
        jpegsToProcess = []
        photoCounter = 0
        processedPhotoCounter = 0
        images = []
    }
    
    //    changes button orientation
    @objc func newOrientation(notification: Notification){
        switch UIDevice.current.orientation {
        case UIDeviceOrientation.landscapeLeft:
            rotationAngle = Double.pi / 2
            break;
        case UIDeviceOrientation.landscapeRight:
            rotationAngle = -(Double.pi / 2)
            break;
        case UIDeviceOrientation.portrait:
            rotationAngle = 0
            break;
        default:
            break;
        }
        self.lockAEButton?.transform = CGAffineTransform.init(rotationAngle: CGFloat(rotationAngle))
        self.lockFocusButton?.transform = CGAffineTransform.init(rotationAngle: CGFloat(rotationAngle))
        self.rawButton?.transform = CGAffineTransform.init(rotationAngle: CGFloat(rotationAngle))
        self.hudButton.transform = CGAffineTransform.init(rotationAngle: CGFloat(rotationAngle))
        self.photoCounterLabel.transform = CGAffineTransform.init(rotationAngle: CGFloat(rotationAngle))
        self.settingsTextView.transform = CGAffineTransform.init(rotationAngle: CGFloat(rotationAngle))
    }
    
    @objc func toggleRawButton(){
        if activeTimelapse == false{
            if rawButton?.isSelected == true{
                rawButton?.isSelected = false
            }
            else{
                if rawNotSupportedOnDevice(){
                    rawButton?.isEnabled = false
                    //                    showAlert(withTitle: "Device not supported", withMessage: "RAW mode is only available on devices, that support raw photos, you can still use RawLapse for taking JPEG photos")
                }
                else{
                    rawButton?.isEnabled = true
                    rawButton?.isSelected = true
                }
            }
        }
    }
    
    //    get preview by putting your hand
    func toggleProximitySensor(){
        let device = UIDevice.current
        guard let settingsDic = UserDefaults.standard.dictionary(forKey: "settinsgDic") as? [String:Bool] else{return}
        if activeTimelapse==true && settingsDic[screenDimingStr] == true {
            device.isProximityMonitoringEnabled = true
            NotificationCenter.default.addObserver(self, selector: #selector(adjustBrightness), name: NSNotification.Name.UIDeviceProximityStateDidChange, object: device)
        }
        else if activeTimelapse == false{
            device.isProximityMonitoringEnabled = false
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceProximityStateDidChange, object: device)
        }
    }
    
    func setupCameras(telephoto:Bool){
        self.setupCaptureSession()
        self.setupDevice(telephotoCamera: telephoto)
        self.setupPreviewLayer()
        self.startRunningCaptureSession()
        self.setupInputOutput()
        self.extremeDarkness(turnOnExtreme: getSettingFromSettingsDic(settingToGet: extremeDarknessStr))
    }
    
    func switchCamera(changeToTelephoto telephoto:Bool){
        
        if AVCaptureDevice.default(.builtInDualCamera, for: AVMediaType.video, position: .back) != nil{
            captureSession = AVCaptureSession()
            cameraPreviewLayer?.removeFromSuperlayer()
            setupCameras(telephoto: telephoto)
        }
    }
    
    var changedShortly = false
    
    @objc func printPinchFactor(_ gestureRecognizer : UIPinchGestureRecognizer){
        if changedShortly == false{
            if gestureRecognizer.scale > 2.5 {
                switchCamera(changeToTelephoto:  true)
                changedShortly = true
                Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: { (booly) in
                    self.changedShortly = false
                })
            }
            else if gestureRecognizer.scale < 0.4{
                switchCamera(changeToTelephoto:  false)
                changedShortly = true
                Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: { (booly) in
                    self.changedShortly = false
                })
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleSettingTap(_:))))
        let leftSwipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSwiping(_:)))
        leftSwipeRecognizer.direction = .left
        let rightSwipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSwiping(_:)))
        rightSwipeRecognizer.direction = .right
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(printPinchFactor(_:)))
        
        self.view.addGestureRecognizer(leftSwipeRecognizer)
        self.view.addGestureRecognizer(rightSwipeRecognizer)
        self.view.addGestureRecognizer(pinchRecognizer)
        checkCameraAuthorization { (error) in
            DispatchQueue.main.async {
                self.keepLabelsUpToDate()
                self.setupCameras(telephoto: false)
                self.toggleRawButton()
            }
        }
        checkPhotoLibraryAuthorization {(error) in}
        //        allows buttons to change orientation
        NotificationCenter.default.addObserver(self, selector: #selector(newOrientation), name: Notification.Name.UIDeviceOrientationDidChange, object: nil)
        
        addViews()
        setupUI()
        startBrightness = UIScreen.main.brightness
        
        //        only show the firsttime
        if UserDefaults.standard.bool(forKey: "secondTime") == false{
            introView = IntroView.introview(inView: self.view)
            introView?.setupInsideView()
            introView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(clearIntroView)))
            UserDefaults.standard.set(true, forKey: "secondTime")
        }
    }
    
    @objc func clearIntroView(){
        introView?.animateOut()
    }
    
    @objc func startTimelapse(){
        setupRawJpeg(rawSupported: rawButton!.isSelected)
        
        self.amountOfPhotos = pickerViewController.amountOfPhotos
        self.secondInterval = pickerViewController.secondInterval
        self.continuous = pickerViewController.continuous
        if startBrightness == nil{
            startBrightness = UIScreen.main.brightness
        }
        dimScreen()
        
        if let settingsDic = UserDefaults.standard.dictionary(forKey: "settinsgDic") as? [String:Bool]
        {
            if settingsDic[createVideoStr] == true{
                createVideo = true
            }
            else{
                createVideo =  false
            }
        }
        else{
            createVideo = false}
        
        if(activeTimelapse == false){
            
            activeTimelapse = true
            //till bug is found, call this at the very end
            callProcessQueue()
            toggleProximitySensor()
            shutterButton.tintColor = UIColor.red
            //            how to use the timer
            if let secondInterval = secondInterval {
                timelapseTimer =  Timer.scheduledTimer(withTimeInterval: TimeInterval(secondInterval), repeats: true) { (timer) in
                    self.timelapseTimer?.tolerance = 0.3
                    //check too many photos bug
                    if let amountOfPhotos = self.amountOfPhotos  , let continuous = self.continuous{
                        if(self.photoCounter < amountOfPhotos || continuous){
                            self.takePhoto()
                            self.photoCounter += 1;
                            self.updateLabels()
                            if(amountOfPhotos % 10 == 0){
                                self.dimScreen()
                            }
                        }
                        else{
                            self.stopTimeLapse();
                        }
                    }
                }
            }
        }else{
            stopTimeLapse();
        }
    }
    
    func activateProgressBar(activeTimelapse active: Bool){
        if active == false && photoCounter != 0{
            let percantage = Float(self.processedPhotoCounter) / Float(self.photoCounter)
            if self.mycircleBar == nil{
                self.mycircleBarObject = CircleProgressBar(frame: self.view.frame)
                self.mycircleBar  = self.mycircleBarObject?.circleProgressBar(inView: self.view, photoPercantage: 1)
                self.view.addSubview(self.mycircleBar!)
                self.mycircleBarObject?.shapeLayer.strokeEnd = CGFloat(percantage)
            }
            else{
                self.mycircleBarObject?.shapeLayer.strokeEnd = CGFloat(percantage)
            }
        }
        else{
            if self.mycircleBar != nil {
                mycircleBar?.removeFromSuperview()
                mycircleBarObject?.removeFromSuperview()
                mycircleBar = nil
                mycircleBarObject = nil
            }
        }
    }
    
    func stopTimeLapse(){
        print("stop it")
        activeTimelapse = false;
        timelapseTimer?.invalidate();
        self.fixBrightness()
        if createVideo{
            shutterButton.tintColor = UIColor.blue
        }
        else{
            shutterButton.tintColor = UIColor.white
            self.resetParameters()
        }
        toggleProximitySensor()
        mycircleBar?.removeFromSuperview()
        return ;
    }
    
    func createVideoFromImages(){
        shutterButton.tintColor = self.disabledColor
            do {
                if self.images.count == 0 { self.shutterButton.tintColor = UIColor.white
                    self.images.removeAll()
                    self.resetParameters()
                    return}
                let firstImageData = try Data(contentsOf: self.images.first!)
                let firstImage = UIImage(data: firstImageData)
                guard let imageSize = firstImage?.size  else { self.images.removeAll();
                    return}
                let settings = RenderSettings(orientation: firstImage!.imageOrientation, quality: "4K" , width: Int(imageSize.width), height: Int(imageSize.height))
                let imageAnimator = ImageAnimator(renderSettings: settings , imagesArray: self.images)
                imageAnimator.render() {
                    print("yes")
                    self.shutterButton.tintColor = UIColor.white
                    self.images.removeAll()
                    self.resetParameters()
                }
            }
            catch{
            }
    }
    
    var imageOrientation: AVCaptureVideoOrientation = .portrait
    
    func managePhotoOrientation() -> AVCaptureVideoOrientation {
        
        var currentDevice: UIDevice
        currentDevice = .current
        var deviceOrientation: UIDeviceOrientation
        deviceOrientation = currentDevice.orientation
        
        if deviceOrientation == .portrait {
            imageOrientation = .portrait
        }else if (deviceOrientation == .landscapeLeft){
            imageOrientation = .landscapeRight
        }else if (deviceOrientation == .landscapeRight){
            imageOrientation = .landscapeLeft
        }else if (deviceOrientation == .portraitUpsideDown){
            imageOrientation = .portraitUpsideDown
        }
        return imageOrientation
    }
    
    @objc  func takePhoto(){
        if let photoSettings = self.photoSettings {
            photoOutput?.connection(with: AVMediaType.video)?.videoOrientation = managePhotoOrientation()
            let uniqueSettings = AVCapturePhotoSettings.init(from: photoSettings)
            self.photoOutput?.capturePhoto(with: uniqueSettings, delegate: self)
        }
    }
    
    func cachesDirectory() -> URL{
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func uniqueURL() -> URL{
        if uuid == nil{
            uuid = UUID().uuidString
        }
        var appendString = ""
        if(photoCounter < 10){
            appendString = "0000\(photoCounter)"
        }
        else if(photoCounter < 100){
            appendString = "000\(photoCounter)"
        }
        else if(photoCounter < 1000){
            appendString = "00\(photoCounter)"
        }else if(photoCounter < 10000){
            appendString = "0\(photoCounter)"
        }else{
            appendString = "\(photoCounter)"
        }
        if let newUuid = uuid{
            let saveString = "IMG-" + newUuid + appendString + ".dng"
            return cachesDirectory().appendingPathComponent(saveString)
        }
        else {
            let saveString = "IMG-" + appendString + ".dng"
            return cachesDirectory().appendingPathComponent(saveString)        }
    }
    
    func tmpURL(count: Int) -> URL{
        if uuid == nil{
            uuid = UUID().uuidString
        }
        var appendString = ""
        if(count < 10){
            appendString = "0000\(count)"
        }
        else if(count < 100){
            appendString = "000\(count)"
        }
        else if(count < 1000){
            appendString = "00\(count)"
        }else if(count < 10000){
            appendString = "0\(count)"
        }else{
            appendString = "\(count)"
        }
        if let newUuid = uuid{
            let saveString = "IMG-" + newUuid + appendString + ".jpg"
            return cachesDirectory().appendingPathComponent(saveString)
        }
        else {
            let saveString = "IMG-" + appendString + ".jpg"
            return cachesDirectory().appendingPathComponent(saveString)        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if photo.isRawPhoto{
            self.rawPhotoData = photo.fileDataRepresentation()
        }
        else{
            self.jpegPhotoData = photo.fileDataRepresentation()
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        guard error == nil else{
            return
        }
        saveRawWithEmbeddedThumbnail()
    }
    
    func getAdjustedRaw(rawData : Data?) -> CIImage?{
        
        guard let shadowHighlight = CIFilter(name: "CIHighlightShadowAdjust") else{print("shadowHighlightNotFound");return nil}
        guard let contrastCurve = CIFilter(name: "CIColorControls") else{ print("CIColorControlsNotFound"); return nil}
        guard let rawImage = CIFilter(imageData: rawData, options: nil) else {return nil}
        
        /* can be used to adjust raw exposure if needed
         rawImage.setValue(-0.3, forKey: kCIInputEVKey) */
        rawImage.setValue(2, forKey: kCIInputBoostShadowAmountKey)
        shadowHighlight.setValue(rawImage.outputImage, forKey: kCIInputImageKey)
        shadowHighlight.setValue(0.9, forKey: "inputHighlightAmount")
        shadowHighlight.setValue(0.3 , forKey: "inputShadowAmount")
        contrastCurve.setValue(shadowHighlight, forKey: kCIInputImageKey)
        contrastCurve.setValue(0.99, forKey: "inputContrast")
        contrastCurve.setValue(1.1, forKey: "inputSaturation")
        
        rawImage.setValue(contrastCurve, forKey: kCIInputLinearSpaceFilter)
        
        return rawImage.outputImage
    }
    
    lazy var contextForSaving:CIContext = CIContext(options:
        [kCIContextCacheIntermediates : false ,
         kCIContextPriorityRequestLow : true ])
    
    func createCGIImage(from rawImage: CIImage ) -> CGImage? {
        return contextForSaving.createCGImage(rawImage, from: rawImage.extent, format: kCIFormatRGBAh, colorSpace: CGColorSpace(name:CGColorSpace.extendedLinearSRGB), deferred: true)
    }
    
    func callProcessQueue(){
        if createVideo == false{
            return
        }
        
        if rawButton!.isSelected {
            DispatchQueue.global(qos: .default).async{
                self.processRawQueue()
            }
        }
        else{
            DispatchQueue.global(qos: .default).async{
                self.processJpegQueue()
            }
        }
    }
    
    fileprivate func shouldCreateVideo(_ continueLoop: inout Bool) {
        if self.processedPhotoCounter == photoCounter && activeTimelapse == false && self.createVideo == true {
            continueLoop = false
            print("Start video creation")
            DispatchQueue.main.async {
                self.createVideoFromImages()
            }
        }
    }
    
    fileprivate func createImageAndAddToList(_ myNewPhotoData: Data?) throws {
        let myUrl = tmpURL(count: processedPhotoCounter)
        try myNewPhotoData?.write(to: myUrl)
        images.append(myUrl)
        processedPhotoCounter += 1
    }
    
    //autorelease pool for memory management - because of a bug in UIImagejpegRep
    func processRawQueue(){
        var continueLoop = true
        while continueLoop {
            while !rawsToProcess.isEmpty{
                print("Waiting list : \(rawsToProcess.count)")
                autoreleasepool{
                    let imageURL = rawsToProcess.removeFirst()
                    let imageData = try? Data(contentsOf: imageURL)
                    if let rawAsCIImage = getAdjustedRaw(rawData: imageData){
                        let myCGImage = createCGIImage(from: rawAsCIImage)
                        let myNewImage = UIImage(cgImage: myCGImage!)
                        let myNewPhotoData = UIImageJPEGRepresentation(myNewImage, 0.9)
                        do {
                            try createImageAndAddToList(myNewPhotoData)
                        }
                        catch{
                            print(error)
                        }
                    }
                }
            }
            shouldCreateVideo(&continueLoop)
//            to avoid unnecessary loops
            sleep(2)
        }
    }
    
    func processJpegQueue(){
        var continueLoop = true
        while continueLoop {
            while !jpegsToProcess.isEmpty{
                print("Waiting list : \(jpegsToProcess.count)")
                let imageData = jpegsToProcess.removeFirst()
                let testUI = UIImage(data: imageData)
                if let jpegAsCIImage = CIImage(data: imageData){
                    let myCGImage = self.createCGIImage(from: jpegAsCIImage)
                    let mynewUIImage = UIImage.init(cgImage: myCGImage!, scale: 1.0, orientation: testUI!.imageOrientation)
                    let myNewPhotoData = UIImageJPEGRepresentation(mynewUIImage, 0.8)
                    do {
                        try createImageAndAddToList(myNewPhotoData)
                    }
                    catch{
                        print(error)
                    }
                }
            }
            shouldCreateVideo(&continueLoop)
            sleep(2)
        }
    }
    
    func saveRawWithEmbeddedThumbnail(){
        self.checkPhotoLibraryAuthorization { (error) in}
        let dngFileURL = uniqueURL()
        do{
            if let rawPhoto = rawPhotoData {
                try rawPhoto.write(to: dngFileURL, options: [])
                self.rawsToProcess.append(dngFileURL)
                print("length of rawsToProcess: \(rawsToProcess.count)")
            }
        }
        catch{
            print("error \(photoCounter)")
            return}
        
        guard let rawPreferred = rawButton?.isSelected else{ return}
        
        PHPhotoLibrary.shared().performChanges({
            let creationRequet = PHAssetCreationRequest.forAsset()
            let creationOptions = PHAssetResourceCreationOptions()
            creationOptions.shouldMoveFile = false
            
            if rawPreferred{
                creationRequet.addResource(with: .photo, fileURL: dngFileURL, options: creationOptions)
            }
            else{
                self.jpegsToProcess.append(self.jpegPhotoData!)
                creationRequet.addResource(with: .photo, data: self.jpegPhotoData!, options: creationOptions)
            }
        }, completionHandler: nil)
    }
    
    func checkCameraAuthorization(_ completionHandler: @escaping ((_ authorized: Bool) -> Void)) {
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .authorized:
            //The user has previously granted access to the camera.
            completionHandler(true)
            
        case .notDetermined:
            // The user has not yet been presented with the option to grant video access so request access.
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { success in
                completionHandler(success)
            })
            
        case .denied:
            // The user has previously denied access.
            completionHandler(false)
            
        case .restricted:
            // The user doesn't have the authority to request access e.g. parental restriction.
            completionHandler(false)
        }
    }
    
    func checkPhotoLibraryAuthorization(_ completionHandler: @escaping ((_ authorized: Bool) -> Void)) {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            // The user has previously granted access to the photo library.
            completionHandler(true)
            
        case .notDetermined:
            // The user has not yet been presented with the option to grant photo library access so request access.
            PHPhotoLibrary.requestAuthorization({ status in
                completionHandler((status == .authorized))
            })
            
        case .denied:
            // The user has previously denied access.
            completionHandler(false)
            
        case .restricted:
            // The user doesn't have the authority to request access e.g. parental restriction.
            completionHandler(false)
        }
    }
    
    @objc func handleHud(){
        if hudActive {
            hudView?.animateOut()
            hudActive = false
        }
        else{
            if(hudView == nil){
                hudView = Hud.hud(inView: self.view)
                hudView?.setupInsideHud(pickerViewController: pickerViewController)
                hudActive = true
            }
            else{
                hudView?.animateIn()
                hudActive = true
            }
        }
    }
    
    @objc func toggleLockAEButton(){
        lockAEButton?.isSelected = !(lockAEButton!.isSelected)
        lockUnlockExposureFocus(toggleExposure: true, toggleFocus: false)
    }
    @objc func toggleLockFocusButton(){
        lockFocusButton?.isSelected = !(lockFocusButton!.isSelected)
        lockUnlockExposureFocus(toggleExposure: false, toggleFocus: true)
    }
    
    func setRuleOfThirdsViewer(){
        
        if let settingsDic = UserDefaults.standard.dictionary(forKey: "settinsgDic") as? [String:Bool]{
            if settingsDic[ruleOfThirds] == true {
                self.view.addSubview(ruleOfThirdsViewer)
                ruleOfThirdsViewer.heightAnchor.constraint(equalToConstant: cameraPreviewLayerFrame!.height ).isActive = true
                ruleOfThirdsViewer.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
                ruleOfThirdsViewer.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
                ruleOfThirdsViewer.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
            }
            else {
                ruleOfThirdsViewer.removeFromSuperview()
            }
        }
    }
    
    func setSixteenByNineViewer(){
        
        if let settingsDic = UserDefaults.standard.dictionary(forKey: "settinsgDic") as? [String:Bool]{
            if settingsDic[sixteenByNine] == true {
                self.view.addSubview(sixteenByNineViewer)
                sixteenByNineViewer.heightAnchor.constraint(equalToConstant: cameraPreviewLayerFrame!.height ).isActive = true
                sixteenByNineViewer.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
                sixteenByNineViewer.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
                sixteenByNineViewer.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
            }
            else {
                sixteenByNineViewer.removeFromSuperview()
            }
        }
    }
    
    func setmiddleScreenViewer(){
        
        if let settingsDic = UserDefaults.standard.dictionary(forKey: "settinsgDic") as? [String:Bool]{
            if settingsDic[middleScreen] == true {
                self.view.addSubview(middleScreenViewer)
                middleScreenViewer.heightAnchor.constraint(equalToConstant: cameraPreviewLayerFrame!.height ).isActive = true
                middleScreenViewer.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
                middleScreenViewer.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
                middleScreenViewer.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
            }
            else {
                middleScreenViewer.removeFromSuperview()
            }
        }
    }
    
    @objc func showSettingsPage(){
        let tablecontroller =  SettingsTableViewController()
        let navController = UINavigationController(rootViewController: tablecontroller)
        navController.navigationBar.barTintColor = UIColor.black
        navController.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
        present(navController, animated: true, completion: nil)
    }
    
    func addViews(){
        if(buttonsSet == false){
            setButtons()
            buttonsSet = true
        }
        bottomBar.addSubview(shutterButton)
        self.view.addSubview(slimTopBar)
        self.view.addSubview(bottomBar)
        slimTopBar.addSubview(hudButton)
        slimTopBar.addSubview(lockAEButton!)
        slimTopBar.addSubview(lockFocusButton!)
        slimTopBar.addSubview(rawButton!)
        slimTopBar.addSubview(privacyPolicyButton!)
        bottomBar.addSubview(settingsTextView)
        bottomBar.addSubview(photoCounterLabel)
    }
    
    func setButtons(){
        lockAEButton = UIButton()
        lockAEButton?.setTitle("AEL", for: .normal)
        lockAEButton?.setTitleColor(UIColor.white, for: .normal)
        lockAEButton?.setTitleColor(UIColor.orange, for: UIControlState.selected)
        lockAEButton?.addTarget(self, action: #selector(toggleLockAEButton), for: .touchUpInside)
        lockAEButton?.translatesAutoresizingMaskIntoConstraints = false
        
        lockFocusButton = UIButton()
        lockFocusButton?.setTitle("AFL", for: .normal)
        lockFocusButton?.setTitleColor(UIColor.white, for: .normal)
        lockFocusButton?.setTitleColor(UIColor.orange, for: .selected)
        lockFocusButton?.addTarget(self, action: #selector(toggleLockFocusButton), for: .touchUpInside)
        lockFocusButton?.translatesAutoresizingMaskIntoConstraints = false
        
        rawButton = UIButton()
        rawButton?.setTitle("RAW", for: .normal)
        rawButton?.setTitleColor(UIColor.white, for: .normal)
        rawButton?.setTitleColor(UIColor.orange, for: .selected)
        rawButton?.setTitleColor(disabledColor, for: .disabled)
        rawButton?.addTarget(self, action: #selector(toggleRawButton), for: .touchUpInside)
        rawButton?.translatesAutoresizingMaskIntoConstraints = false
        
        privacyPolicyButton = UIButton()
        privacyPolicyButton?.setTitle("i", for: .normal)
        privacyPolicyButton?.setTitleColor(UIColor.white, for: .normal)
        privacyPolicyButton?.addTarget(self, action: #selector(showSettingsPage), for: .touchUpInside)
        privacyPolicyButton?.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func setupUI(){
        
        slimTopBar.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor , constant:0).isActive = true
        slimTopBar.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        slimTopBar.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        slimTopBar.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        hudButton.centerXAnchor.constraint(equalTo: slimTopBar.centerXAnchor).isActive = true
        hudButton.centerYAnchor.constraint(equalTo: slimTopBar.centerYAnchor).isActive = true
        hudButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        hudButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        lockAEButton?.leftAnchor.constraint(equalTo: slimTopBar.leftAnchor, constant: 16).isActive = true
        lockAEButton?.centerYAnchor.constraint(equalTo: slimTopBar.centerYAnchor).isActive = true
        lockAEButton?.widthAnchor.constraint(equalToConstant: 44).isActive = true
        lockAEButton?.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        lockFocusButton?.leftAnchor.constraint(equalTo: lockAEButton!.rightAnchor).isActive = true
        lockFocusButton?.centerYAnchor.constraint(equalTo: slimTopBar.centerYAnchor).isActive = true
        lockFocusButton?.widthAnchor.constraint(equalToConstant: 44).isActive = true
        lockFocusButton?.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        privacyPolicyButton?.rightAnchor.constraint(equalTo: slimTopBar.rightAnchor, constant: 16).isActive = true
        privacyPolicyButton?.centerYAnchor.constraint(equalTo: slimTopBar.centerYAnchor).isActive = true
        privacyPolicyButton?.widthAnchor.constraint(equalToConstant: 66).isActive = true
        privacyPolicyButton?.heightAnchor.constraint(equalToConstant: 66).isActive = true
        
        rawButton?.rightAnchor.constraint(equalTo: privacyPolicyButton!.leftAnchor, constant: -32).isActive = true
        rawButton?.centerYAnchor.constraint(equalTo: slimTopBar.centerYAnchor, constant: 0).isActive = true
        rawButton?.widthAnchor.constraint(equalToConstant: 44).isActive = true
        rawButton?.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        bottomBar.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor , constant:0).isActive = true
        bottomBar.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        bottomBar.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        bottomBar.heightAnchor.constraint(equalToConstant: 88).isActive = true
        
        shutterButton.centerXAnchor.constraint(equalTo: bottomBar.centerXAnchor).isActive = true
        shutterButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor).isActive = true
        shutterButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        shutterButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        settingsTextView.bottomAnchor.constraint(equalTo: bottomBar.bottomAnchor).isActive = true
        settingsTextView.leftAnchor.constraint(equalTo: bottomBar.leftAnchor).isActive = true
        settingsTextView.heightAnchor.constraint(equalToConstant: 88).isActive = true
        settingsTextView.widthAnchor.constraint(equalToConstant: 100).isActive = true
        
        photoCounterLabel.rightAnchor.constraint(equalTo: bottomBar.rightAnchor , constant: -16).isActive = true
        photoCounterLabel.bottomAnchor.constraint(equalTo: bottomBar.bottomAnchor , constant: -16).isActive = true
        photoCounterLabel.widthAnchor.constraint(equalToConstant: 100).isActive = true
        photoCounterLabel.heightAnchor.constraint(equalToConstant: 44).isActive = true
    }
}

