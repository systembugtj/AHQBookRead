//
//  DZMReadController.swift
//  DZMeBookRead
//
//  Created by 邓泽淼 on 2017/5/11.
//  Copyright © 2017年 DZM. All rights reserved.
//

import UIKit

class DZMReadController: DZMViewController,DZMReadMenuDelegate,DZMCoverControllerDelegate,UIPageViewControllerDelegate,UIPageViewControllerDataSource {
    
    /// 阅读模型(必传)
    var readModel:DZMReadModel!
    
    /// 阅读菜单UI
    private(set) var readMenu:DZMReadMenu!
    
    /// 阅读操作对象
    private(set) var readOperation:DZMReadOperation!
    
    /// 翻页控制器 (仿真)
    private(set) var pageViewController:UIPageViewController?
    
    /// 翻页控制器 (无效果,覆盖,上下)
    private(set) var coverController:DZMCoverController?
    
    /// 当前显示的阅读View控制器
    private(set) var currentReadViewController:DZMReadViewController?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // 设置白色状态栏
        isStatusBarLightContent = true
        
        // 初始化控制器操作对象
        readOperation = DZMReadOperation(vc: self)
        
        // 初始化阅读UI控制对象
        readMenu = DZMReadMenu.readMenu(vc: self, delegate: self)
        
        // 初始化控制器
        creatPageController(readOperation.GetCurrentReadViewController(isUpdateFont: true, isSave: true))
        
        //监听是否触发home键挂起程序.
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationWillResignActive), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        
        ///监听是否重新进入程序程序.
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationDidBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        ///监听是否被kill
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationWillTerminate), name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
        
        
    }
    
    
    func applicationWillResignActive(){
        print("监听是否触发home键挂起程序.")
        readMenu.lightView.reSetSystemBrightness()
    }
    
    func applicationDidBecomeActive(){
        print("监听是否重新进入程序程序.")
        readMenu.lightView.reSetCustomBrightness()
    }
    
    func applicationWillTerminate(){
        print("监听是否进入后台或被kill")
    }
    
    // MARK: -- DZMReadMenuDelegate
    
    /// 背景颜色
    func readMenuClickSetuptColor(readMenu: DZMReadMenu, index: NSInteger, color: UIColor) {
        
        DZMReadConfigure.shared().colorIndex = index
        
        currentReadViewController?.configureBGColor()
    }
    
    /// 翻书动画
    func readMenuClickSetuptEffect(readMenu: DZMReadMenu, index: NSInteger) {
        
        DZMReadConfigure.shared().effectType = index
        
        creatPageController(readOperation.GetCurrentReadViewController())
    }
    
    /// 字体
    func readMenuClickSetuptFont(readMenu: DZMReadMenu, index: NSInteger) {
        
        DZMReadConfigure.shared().fontType = index
        
        creatPageController(readOperation.GetCurrentReadViewController(isUpdateFont: true, isSave: true))
    }
    
    /// 字体大小
    func readMenuClickSetuptFontSize(readMenu: DZMReadMenu, fontSize: CGFloat) {
        
        // DZMReadConfigure.shared().fontSize = fontSize 内部已赋值
        
        creatPageController(readOperation.GetCurrentReadViewController(isUpdateFont: true, isSave: true))
    }
    
    
    /// 点击返回按钮
    func readMenuClickBackButton(readMenu: DZMReadMenu, button: UIButton) {
        print("点击返回按钮-------")
     
        readMenu.lightView.reSetSystemBrightness()
    }

    
    /// 点击书签列表
    func readMenuClickMarkList(readMenu: DZMReadMenu, readMarkModel: DZMReadMarkModel) {
        
        readModel.modifyReadRecordModel(readMarkModel: readMarkModel, isUpdateFont: true, isSave: false)
        
        creatPageController(readOperation.GetCurrentReadViewController(isUpdateFont: false, isSave: true))
    }
    
    /// 下载
    func readMenuClickDownload(readMenu: DZMReadMenu) {
        
        print("点击了下载")
    }
    
    /// 拖拽进度条
    func readMenuSliderEndScroll(readMenu: DZMReadMenu, slider: ASValueTrackingSlider) {
        
        if readModel != nil && readModel.readRecordModel.isRecord { // 有阅读记录
   
            let toPage = NSInteger(slider.value)
     
            if (readModel.readRecordModel.page.intValue + 1) != toPage { // 不是同一页
                
                let _ = readOperation.GoToChapter(chapterID: readModel.readRecordModel.readChapterModel!.id, toPage: toPage - 1)
            }
        }
    }
    
    /// 上一章
    func readMenuClickPreviousChapter(readMenu: DZMReadMenu) {
        
        if readModel != nil && readModel.readRecordModel.isRecord { // 有阅读记录
        
            let _ = readOperation.GoToChapter(chapterID: "\(readModel.readRecordModel.readChapterModel!.id.integerValue() - 1)")
        }
    }
    
    /// 下一章
    func readMenuClickNextChapter(readMenu: DZMReadMenu) {
        
        if readModel != nil && readModel.readRecordModel.isRecord { // 有阅读记录
            
            let _ = readOperation.GoToChapter(chapterID: "\(readModel.readRecordModel.readChapterModel!.id.integerValue() + 1)")
        }
    }
    
    /// 点击章节列表
    func readMenuClickChapterList(readMenu: DZMReadMenu, readChapterListModel: DZMReadChapterListModel) {
        
        let _ = readOperation.GoToChapter(chapterID: readChapterListModel.id)
    }
    
    /// 切换日夜间模式
    func readMenuClickLightButton(readMenu: DZMReadMenu, isDay: Bool) {
        
        if isDay {
            currentReadViewController?.configureNightBGColor()
            currentReadViewController?.tableView.reloadData()
        }else{
            currentReadViewController?.configureBGColor()
            currentReadViewController?.tableView.reloadData()
            
        }
    }
    
    /// 状态栏 将要 - 隐藏以及显示状态改变
    func readMenuWillShowOrHidden(readMenu: DZMReadMenu, isShow: Bool) {
        
        pageViewController?.tapGestureRecognizerEnabled = !isShow
        
        coverController?.tapGestureRecognizerEnabled = !isShow
        
        if isShow {
            
            // 选中章节列表
            readMenu.leftView.topView.selectIndex = 0
            
            // 检查当前是否存在书签
            readMenu.topView.mark.isSelected = readModel.checkMark()
        }
    }
    
    /// 点击书签按钮
    func readMenuClickMarkButton(readMenu: DZMReadMenu, button: UIButton) {
        
        if button.isSelected {
            
            let _ = readModel.removeMark()
            
            button.isSelected = readModel.checkMark()
            
        }else{
            
            readModel.addMark()
            
            button.isSelected = true
        }
    }
    
    // MARK: -- 创建 PageController
    
    /// 创建效果控制器 传入初始化显示控制器
    func creatPageController(_ displayController:UIViewController?) {
        
        // 清理
        if pageViewController != nil {
            
            pageViewController?.view.removeFromSuperview()
            
            pageViewController?.removeFromParentViewController()
            
            pageViewController = nil
        }
        
        if coverController != nil {
            
            coverController?.view.removeFromSuperview()
            
            coverController?.removeFromParentViewController()
            
            coverController = nil
        }
        
        // 创建
        if DZMReadConfigure.shared().effectType == DZMRMEffectType.simulation.rawValue { // 仿真
            
            let options = [UIPageViewControllerOptionSpineLocationKey:NSNumber(value: UIPageViewControllerSpineLocation.min.rawValue as Int)]
            
            pageViewController = UIPageViewController(transitionStyle:UIPageViewControllerTransitionStyle.pageCurl,navigationOrientation:UIPageViewControllerNavigationOrientation.horizontal,options: options)
            
            pageViewController!.delegate = self
            
            pageViewController!.dataSource = self
            
            // 为了翻页背面的颜色使用
            pageViewController!.isDoubleSided = true
            
            view.insertSubview(pageViewController!.view, at: 0)
            
            addChildViewController(pageViewController!)
            
            pageViewController!.setViewControllers((displayController != nil ? [displayController!] : nil), direction: UIPageViewControllerNavigationDirection.forward, animated: true, completion: nil)
            
        }else{ // 无效果 覆盖 上下
            
            coverController = DZMCoverController()
            
            coverController!.delegate = self
            
            view.insertSubview(coverController!.view, at: 0)
            
            addChildViewController(coverController!)
            
            coverController!.setController(displayController)
            
            if DZMReadConfigure.shared().effectType == DZMRMEffectType.none.rawValue {
                
                coverController!.openAnimate = false
                
            }else if DZMReadConfigure.shared().effectType == DZMRMEffectType.upAndDown.rawValue {
                
                coverController!.openAnimate = false
                
                coverController!.gestureRecognizerEnabled = false
            }
        }
        readMenu.topView.setTitle(readModel.readRecordModel.readChapterModel?.name)
        // 记录
        currentReadViewController = displayController as? DZMReadViewController
    }
    
    // MARK: -- DZMCoverControllerDelegate
    
    /// 切换结果
    func coverController(_ coverController: DZMCoverController, currentController: UIViewController?, finish isFinish: Bool) {
        
        // 记录
        currentReadViewController = currentController as? DZMReadViewController
        
        // 更新阅读记录
        readOperation.readRecordUpdate(readViewController: currentReadViewController)
        
        // 更新进度条
        readMenu.bottomView.sliderUpdate()
    }
    
    /// 将要显示的控制器
    func coverController(_ coverController: DZMCoverController, willTransitionToPendingController pendingController: UIViewController?) {
        
        readMenu.menuSH(isShow: false)
    }
    
    /// 获取上一个控制器
    func coverController(_ coverController: DZMCoverController, getAboveControllerWithCurrentController currentController: UIViewController?) -> UIViewController? {
        
        return readOperation.GetAboveReadViewController()
    }
    
    /// 获取下一个控制器
    func coverController(_ coverController: DZMCoverController, getBelowControllerWithCurrentController currentController: UIViewController?) -> UIViewController? {
        
        return readOperation.GetBelowReadViewController()
    }
    
    // MARK: -- UIPageViewControllerDelegate
    
    /// 切换结果
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        if !completed {
            
            // 记录
            currentReadViewController = previousViewControllers.first as? DZMReadViewController
            
            // 更新阅读记录
            readOperation.readRecordUpdate(readViewController: currentReadViewController)
            
        }else{
            
            // 记录
            currentReadViewController = pageViewController.viewControllers?.first as? DZMReadViewController
            
            // 更新阅读记录
            readOperation.readRecordUpdate(readViewController: currentReadViewController)
            
            // 更新进度条
            readMenu.bottomView.sliderUpdate()
        }
    }
    
    /// 准备切换
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        
        readMenu.menuSH(isShow: false)
        
        // 更新阅读记录
        readOperation.readRecordUpdate(readViewController: pageViewController.viewControllers?.first as? DZMReadViewController, isSave: false)
    }
    
    
    // MARK: -- UIPageViewControllerDataSource
    
    /// 用于区分正反面的值(固定)
    private var TempNumber:NSInteger = 1
    
    /// 获取上一页
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        TempNumber -= 1
        
        if abs(TempNumber) % 2 == 0 { // 背面
            
            let vc = UIViewController()
            // 配置背景颜色
            if DZMUserDefaults.boolForKey(DZMKey_IsNighOrtDay) {
                vc.view.backgroundColor =  DZMReadHeaderAndFooterTextColor_NIGHT
            }else{
                vc.view.backgroundColor =  DZMReadConfigure.shared().readColor()
            }
            return vc
            
        }else{ // 内容
            
            return readOperation.GetAboveReadViewController()
        }
    }
    
    /// 获取下一页
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        TempNumber += 1
        
        if abs(TempNumber) % 2 == 0 { // 背面
            
            let vc = UIViewController()
            
            // 配置背景颜色
            if DZMUserDefaults.boolForKey(DZMKey_IsNighOrtDay) {
                vc.view.backgroundColor =  DZMReadHeaderAndFooterTextColor_NIGHT
            }else{
                vc.view.backgroundColor =  DZMReadConfigure.shared().readColor()
            }
            return vc
            
        }else{ // 内容
            
            return readOperation.GetBelowReadViewController()
        }
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }
    
    deinit {
        
        // 清理模型
        readModel = nil
    }
}
