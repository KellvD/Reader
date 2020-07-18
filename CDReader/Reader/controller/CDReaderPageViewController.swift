//
//  CDReaderPageViewController.swift
//  MyBox
//
//  Created by changdong on 2020/7/13.
//  Copyright changdong 2012-2019. All rights reserved.
//

import UIKit

class CDReaderPageViewController: UIViewController,CDReaderToolBarDelegate, UIPageViewControllerDelegate,UIPageViewControllerDataSource,CDChapterViewControllerDelegate {
    
    
    
    public var gresource:String!
    
    private var greaderModel:CDReaderModel!
    private var greadView:CDReaderViewController!  //当前视图
    private var toolsView:CDReaderToolBar!
    private var _hiddenNavBar:Bool = false
    private var _chapterIndex:Int = 0 //s当前显示章节
    private var _pageIndex:Int = 0 //当前显示页数
    private var _changeChapterIndex:Int = 0//将要变化的章节
    private var _changePageIndex:Int = 0 //将要变化的页数
    private var _isTransition:Bool = false //是否开始翻页
    
    
    override var prefersStatusBarHidden: Bool{
        return _hiddenNavBar
    }
    override func viewWillDisappear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .default
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(named: "上导航栏-背景@2x"), for: .default)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addChild(self.pageVC)
        DispatchQueue.global().async {
            self.greaderModel = CDReaderModel.getLocalModel(url: URL(fileURLWithPath: self.gresource))

            DispatchQueue.main.async {
                self.pageVC.setViewControllers([self.readViewChapter(chapter: self.greaderModel.record.chapterIndex, page: self.greaderModel.record.pageIndex)], direction: .forward, animated: true, completion: nil)
                self._chapterIndex = self.greaderModel.record.chapterIndex
                self._pageIndex = self.greaderModel.record.pageIndex
                self.toolsView.loadRecord(record: self.greaderModel.record)
            }
        }
        let height:CGFloat = iPhoneX ? 300 : 220
        self.toolsView = CDReaderToolBar(frame: CGRect(x: 0, y: CDSCREEN_HEIGTH - height, width: CDSCREEN_WIDTH, height: height))
        self.toolsView.delegate = self
        self.view.addSubview(self.toolsView)
        let popBtn = UIButton(type: .custom)
        popBtn.frame = CGRect(x: 0, y: 0, width: 45, height: 45)
        popBtn.setImage(UIImage(named:"back_normal"), for: .normal)
        popBtn.setImage(UIImage(named: "back_pressed"), for: .selected)
        popBtn.addTarget(self, action: #selector(backButtonClick), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: popBtn)
        
        
        self.onChangeTheme()
        self.hiddenNavBar(nil)
        
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(hiddenNavBar(_:)))
        self.pageVC.view.addGestureRecognizer(tap)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onChangeTheme), name: NSNotification.Name("changeTheme"), object: nil)

    }
    
    lazy var pageVC: UIPageViewController = {
        let page = UIPageViewController(transitionStyle: .pageCurl, navigationOrientation: .horizontal, options: nil)
        page.delegate = self
        page.dataSource = self
        self.view.addSubview(page.view)
        return page
    }()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLayoutSubviews() {
        self.pageVC.view.frame = CGRect(x: 0, y: 0, width: CDSCREEN_WIDTH, height: CDSCREEN_HEIGTH)
    }
    
    @objc private func backButtonClick(){
        self.navigationController?.popViewController(animated: true)
    }
    @objc private func onChangeTheme(){
        self.view.backgroundColor = CDReaderConfig.shared.theme
        self.pageVC.view.backgroundColor = CDReaderConfig.shared.theme
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        self.navigationController?.navigationBar.barTintColor = CDReaderConfig.shared.theme
        if CDReaderConfig.shared.theme == night {
            UIApplication.shared.statusBarStyle = .lightContent
        } else {
           UIApplication.shared.statusBarStyle = .darkContent
        }
    }
    
    func onDidChangeFont() {
        greaderModel.record.chapterModel.updateFont()

        let page = greaderModel.record.pageIndex > (greaderModel.record.chapterModel.pageCount - 1) ? greaderModel.record.chapterModel.pageCount - 1 :greaderModel.record.pageIndex
        pageVC.setViewControllers([readViewChapter(chapter: greaderModel.record.chapterIndex, page: page)], direction: .forward, animated: false, completion: nil)
        updateReadModel(chapterIndex: greaderModel.record.chapterIndex, page: page)

    }
    
    @objc func hiddenNavBar(_ tap:UITapGestureRecognizer?){
        
        _hiddenNavBar = !_hiddenNavBar
        self.toolsView.isHidden = _hiddenNavBar
        self.navigationController?.navigationBar.isHidden = _hiddenNavBar
    }
    
    
    //CDReaderToolBarDelegate
    func onDidSelectedChapter() {
        hiddenNavBar(nil)
        let chapterVC = CDChapterViewController()
        chapterVC.myDelegate = self
        chapterVC.readModel = greaderModel
        chapterVC.modalPresentationStyle = .popover
        self.present(chapterVC, animated: true, completion: nil)
    }
    
    func onDidChangeChapterProcess(process: Int) {
        updateReadModel(chapterIndex: process, page: 0)
        pageVC.setViewControllers([readViewChapter(chapter: process, page: 0)], direction: .forward, animated: true, completion: nil)
    }
    //CDChapterViewControllerDelegate
    func onDidSelectdChapter(chapterIndex: Int) {
        updateReadModel(chapterIndex: chapterIndex, page: 0)
        pageVC.setViewControllers([readViewChapter(chapter: chapterIndex, page: 0)], direction: .forward, animated: true, completion: nil)
    }
    
    
    //
    func readViewChapter(chapter:Int,page:Int) -> CDReaderViewController {
        if greaderModel.record.chapterIndex != chapter {
            updateReadModel(chapterIndex: chapter, page: page)
            greaderModel.record.chapterModel.updateFont()
        }
        greadView = CDReaderViewController()
        greadView.recordModel = greaderModel.record
        greadView.content = greaderModel.chaptersArr[chapter].stringOfPage(index: page)
        greadView.hiddenNavBar = _hiddenNavBar
        return greadView
    }
    
    func updateReadModel(chapterIndex:Int,page:Int) {
        _chapterIndex = chapterIndex
        _pageIndex = page
        greaderModel.record.chapterModel = greaderModel.chaptersArr[chapterIndex]
        greaderModel.record.chapterIndex = chapterIndex
        greaderModel.record.pageIndex = page
        CDReaderModel.updateLocalModel(model: greaderModel, url: URL(fileURLWithPath: gresource))
        self.toolsView.loadRecord(record: greaderModel.record)

    }
    
    //TODO:UIPageViewController
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if !completed {
            let readView = previousViewControllers.first as! CDReaderViewController
            greadView = readView
            _pageIndex = readView.recordModel.pageIndex
            _chapterIndex = readView.recordModel.chapterIndex
            
        } else {
           updateReadModel(chapterIndex: _chapterIndex, page: _pageIndex)
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        _chapterIndex = _changeChapterIndex
        _pageIndex = _changePageIndex
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if !_hiddenNavBar  { hiddenNavBar(nil)}
        _changeChapterIndex = _chapterIndex
        _changePageIndex = _pageIndex
        if _changeChapterIndex == 0 && _changeChapterIndex == 0 {
            return nil
        }
        
        //页数为0章节-1
        if _changePageIndex == 0 {
            _changeChapterIndex -= 1
            _changePageIndex = greaderModel.chaptersArr[_changeChapterIndex].pageCount - 1
        } else {
            _changePageIndex -= 1
        }
        return readViewChapter(chapter: _changeChapterIndex, page: _changePageIndex)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if !_hiddenNavBar { hiddenNavBar(nil)}
        _changeChapterIndex = _chapterIndex
        _changePageIndex = _pageIndex
        if _changePageIndex == greaderModel.chaptersArr.last!.pageCount - 1 &&
            _changeChapterIndex == greaderModel.chaptersArr.count - 1
            {
            return nil
        }
        
        if _changePageIndex == greaderModel.chaptersArr[_changeChapterIndex].pageCount - 1 {
            _changeChapterIndex += 1
            _changePageIndex = 0
        } else {
            _changePageIndex += 1
        }
        return readViewChapter(chapter: _changeChapterIndex, page: _changePageIndex)
    }
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
    */

}
