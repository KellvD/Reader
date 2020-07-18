//
//  CDReaderViewController.swift
//  MyBox
//
//  Created by changdong on 2020/7/1.
//  Copyright changdong 2012-2019. All rights reserved.
//

import UIKit


class CDReaderViewController: UIViewController {

    public var content:String!
    public var recordModel:CDRecordModel!
    var hiddenNavBar:Bool!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = CDReaderConfig.shared.theme
        self.view.addSubview(self.readView)
        NotificationCenter.default.addObserver(self, selector: #selector(onChangeTheme(_:)), name: NSNotification.Name("changeTheme"), object: nil)
    }
    
    @objc private func onChangeTheme(_ noti:Notification){
        self.view.backgroundColor = CDReaderConfig.shared.theme
        readView.frameRef = CDReaderUtilites.parserContent(content: content, config: CDReaderConfig.shared, bounds: readView.bounds)
        readView.setNeedsDisplay()
    }
    

    lazy var readView: CDReadView = {
        
        let Y = NavigationHeight + StatusHeight//hiddenNavBar ? NavigationHeight + StatusHeight : 20
        let readView = CDReadView(frame: CGRect(x: LeftSpacing, y: Y, width: CDSCREEN_WIDTH - LeftSpacing * 2, height: CDViewHeight - BottomSpacing))
        let ctFrame = CDReaderUtilites.parserContent(content: content, config: CDReaderConfig.shared, bounds: readView.bounds)
        readView.loadCTFrame(ctFrame: ctFrame)
        return readView
    }()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

}


class CDReadView: UIView {
    public var frameRef:CTFrame!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func loadCTFrame(ctFrame:CTFrame){
        if frameRef != ctFrame {
            if frameRef != nil {
                frameRef = nil
            }
        }
        frameRef = ctFrame
    }
    override func draw(_ rect: CGRect) {
        if frameRef == nil {
            return
        }
        let context = UIGraphicsGetCurrentContext()
        context?.textMatrix = .identity
        context?.translateBy(x: 0, y: self.bounds.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        CTFrameDraw(frameRef,context!)
    }
}
