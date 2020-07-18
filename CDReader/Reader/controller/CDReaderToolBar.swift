//
//  CDReaderToolBar.swift
//  MyBox
//
//  Created by changdong on 2020/6/29.
//  Copyright changdong 2012-2019. All rights reserved.
//

import UIKit

let changeLightTag = 90
let changeChapterTag = 100
let themeTag = 110
let chapterTag = 120
let fontTag = 130
protocol CDReaderToolBarDelegate {
    func onDidSelectedChapter()
    func onDidChangeChapterProcess(process:Int)
    func onDidChangeFont()
}
class CDReaderToolBar: UIView {
    let themeTitleArr = ["白天","护眼","夜间"]
    let themeColorArr:[UIColor] = [day,eye,night]
    let themeBorderColorArr:[UIColor] = [dayBorder,eyeBorder,nightBorder]
    var delegate:CDReaderToolBarDelegate!
    
    private var processSlider:UISlider!
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let maskPath = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: [.topLeft,.topRight], cornerRadii: CGSize(width: 20, height: 20))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = self.bounds
        maskLayer.path = maskPath.cgPath
        self.layer.mask = maskLayer
        
        let lightImageView = UIImageView(frame: CGRect(x: 15, y: 15, width: 30, height: 30))
        lightImageView.image = UIImage(named: "亮度-白")
        self.addSubview(lightImageView)
        
        let lightSlider = UISlider(frame: CGRect(x: lightImageView.frame.maxX + 15,
                                                 y: 15,
                                                 width: frame.width - (lightImageView.frame.maxX + 15) * 2,
                                                 height: 30))
        lightSlider.minimumValue = 0.2
        lightSlider.maximumValue = 1
        lightSlider.value = Float(UIScreen.main.brightness)
        lightSlider.maximumTrackTintColor = .white
        lightSlider.tag = changeLightTag
        lightSlider.addTarget(self, action: #selector(onDidChangeLight(_:)), for: .valueChanged)
        self.addSubview(lightSlider)
        
        let gayImageView = UIImageView(frame: CGRect(x: lightSlider.frame.maxX + 15, y: 15, width: 30, height: 30))
        gayImageView.image = UIImage(named: "亮度-黑")
        self.addSubview(gayImageView)
        
        //
        let reduceBtn = UIButton(type:.custom)
        reduceBtn.tag = changeChapterTag
        reduceBtn.frame = CGRect(x: 10, y: lightSlider.frame.maxY + 15, width: 40, height: 30)
        reduceBtn.setTitle("上一章", for: .normal)
        reduceBtn.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        reduceBtn.addTarget(self, action: #selector(onDidChangeChapterClick(_:)), for: .touchUpInside)
        self.addSubview(reduceBtn)
        
        processSlider = UISlider(frame: CGRect(x: reduceBtn.frame.maxX + 10,
                                                   y: reduceBtn.frame.minY,
                                                   width: frame.width - (reduceBtn.frame.maxX + 10) * 2,
                                                   height: 30))
        processSlider.minimumValue = 1
        processSlider.maximumTrackTintColor = .white
        processSlider.isContinuous = false
        processSlider.addTarget(self, action: #selector(onDidChangeChapterSlider(_:)), for: .valueChanged)
        self.addSubview(processSlider)
        
        let addBtn = UIButton(type:.custom)
        addBtn.tag = changeChapterTag + 1
        addBtn.frame = CGRect(x: processSlider.frame.maxX + 10, y: reduceBtn.frame.minY, width: 40, height: 30)
        addBtn.setTitle("下一章", for: .normal)
        addBtn.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        addBtn.addTarget(self, action: #selector(onDidChangeChapterClick(_:)), for: .touchUpInside)
        self.addSubview(addBtn)
        
        
        let spqce:CGFloat = (CDSCREEN_WIDTH - 64 * 3)/4
        for i in 0..<themeTitleArr.count {
            let themeBtn = UIButton(type:.custom)
            themeBtn.tag = themeTag + i
            themeBtn.frame = CGRect(x: spqce * CGFloat((i + 1)) + CGFloat(64 * i),
                                    y: addBtn.frame.maxY + 20,
                                    width: 64,
                                    height: 40)
            themeBtn.setTitle(themeTitleArr[i], for: .normal)
            themeBtn.layer.cornerRadius = 20
            themeBtn.setTitleColor(themeTitleArr[i] == "夜间" ? day:night, for: .normal)
            themeBtn.backgroundColor = themeColorArr[i]
            themeBtn.addTarget(self, action: #selector(onThemeClick(_:)), for: .touchUpInside)
            self.addSubview(themeBtn)
        }
        
        //
        let spqce0:CGFloat = (CDSCREEN_WIDTH/2 - 45 * 2)/3
        let chapterBtn = UIButton(type:.custom)
        chapterBtn.frame = CGRect(x: spqce0, y: addBtn.frame.maxY + 30 + 45, width: 45, height: 45)
        chapterBtn.tag = chapterTag
//        chapterBtn.setImage(UIImage(named: "目录-黑"), for: .normal)
        chapterBtn.addTarget(self, action: #selector(onChapterClick(_:)), for: .touchUpInside)
        self.addSubview(chapterBtn)
        
        
        
        for i in 0..<2 {
            let fontBtn = UIButton(type:.custom)
            fontBtn.tag = fontTag + i
            fontBtn.frame = CGRect(x: CDSCREEN_WIDTH/2 + spqce0 * CGFloat((i + 1)) + CGFloat(45 * i),
                                   y: chapterBtn.frame.minY,
                                   width: 45,
                                   height: 45)
//            fontBtn.setImage(UIImage(named: i == 0 ? "字体-黑-小":"字体-黑-大"), for: .normal)
            fontBtn.addTarget(self, action: #selector(onFontClick(_:)), for: .touchUpInside)
            self.addSubview(fontBtn)
        }
        updateTheme()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func loadRecord(record:CDRecordModel){
        processSlider.maximumValue = Float(record.chapterTotalCount)
        processSlider.value = Float(record.chapterIndex)

    }
    //更改亮度
    @objc private func onDidChangeLight(_ sender:UISlider){
        
        UIScreen.main.brightness = CGFloat(sender.value)
    }
    
    
    //查看目录
    @objc private func onChapterClick(_ sender:UIButton){
        
        delegate.onDidSelectedChapter()
    }
    
    //滑动进度
    @objc private func onDidChangeChapterSlider(_ sender:UISlider){
        delegate.onDidChangeChapterProcess(process: Int(sender.value))
    }
    
    //微调进度
    @objc private func onDidChangeChapterClick(_ sender:UIButton){
        
        var currentChapter = processSlider.value
        if currentChapter == 0 && currentChapter == processSlider.maximumValue{
            return
        }
        if sender.tag == changeChapterTag{
            currentChapter -= 1
        } else {
            currentChapter += 1
        }
        processSlider.value = currentChapter
        delegate.onDidChangeChapterProcess(process: Int(processSlider.value))
    }
    
    //选择主题
    @objc private func onThemeClick(_ sender:UIButton){
        let index = sender.tag - themeTag
        let color = themeColorArr[index]
        if CDReaderConfig.shared.theme == color{
            return
        }
        CDReaderConfig.shared.theme = color
        CDReaderConfig.shared.fontColor = color == night ? .white : .black
        updateTheme()
        CDReaderConfig.updateLocalConfig(conflg: CDReaderConfig.shared)
        NotificationCenter.default.post(name: NSNotification.Name("changeTheme"), object: color)
        

    }
    
    //更改字体
    @objc private func onFontClick(_ sender:UIButton){
        var fontSize = CDReaderConfig.shared.fontSize!
        
        if sender.tag - fontTag == 0 { //减小字体
            if fontSize <= MinFont {
                return
            } else {
                fontSize -= Float(1)
            }
            
        } else {
            if fontSize >= MaxFont {
                return
            } else {
                fontSize += Float(1)
            }
            
        }
        CDReaderConfig.shared.fontSize = fontSize
        CDReaderConfig.updateLocalConfig(conflg: CDReaderConfig.shared)
        delegate.onDidChangeFont()

    }
    
    func updateTheme(){
        let fontColor:UIColor = CDReaderConfig.shared.fontColor
        //
        self.backgroundColor = CDReaderConfig.shared.theme
        //
        
        var effectView = self.viewWithTag(1000) as? UIVisualEffectView
        if effectView != nil {
            effectView?.removeFromSuperview()
        }
        let blurEffect = UIBlurEffect(style: CDReaderConfig.shared.theme == night ? .light : .dark)
        effectView = UIVisualEffectView(effect: blurEffect)
        effectView!.frame = self.bounds
        effectView?.alpha = CDReaderConfig.shared.theme == night ? 0.3 : 0.1
        self.addSubview(effectView!)
        self.sendSubviewToBack(effectView!)
        
        //
        for i in 0..<2 {
            let changeChapterBtn = self.viewWithTag(changeChapterTag + i) as! UIButton
            changeChapterBtn.setTitleColor(fontColor, for: .normal)
        }
        
        //
        for i in 0..<themeColorArr.count {
            let itemBtn = self.viewWithTag(themeTag + i) as! UIButton
            if CDReaderConfig.shared.theme == themeColorArr[i] {
                itemBtn.layer.borderColor = themeBorderColorArr[i].cgColor
                itemBtn.layer.borderWidth = 2
            }else{
                itemBtn.layer.borderColor = themeColorArr[i].cgColor
                itemBtn.layer.borderWidth = 0
            }
        }
        
        //
        let chapterBtn = self.viewWithTag(chapterTag) as! UIButton
        let image = CDReaderConfig.shared.theme == night ? "目录-白":"目录-黑"
        chapterBtn.setImage(UIImage(named: image), for: .normal)
        //

        let fontImageArr = [CDReaderConfig.shared.theme == night ? "字体-白-小":"字体-黑-小",
                            CDReaderConfig.shared.theme == night ? "字体-白-大":"字体-黑-大"]
        for i in 0..<fontImageArr.count {
            let fontBtn = self.viewWithTag(fontTag + i) as! UIButton
            fontBtn.setImage(UIImage(named: fontImageArr[i]), for: .normal)
        }
        
        let sliderImage = CDReaderConfig.shared.theme == night ? "slider-白": "slider-黑"
        let lightSlider = self.viewWithTag(changeLightTag) as! UISlider
        lightSlider.setThumbImage(UIImage(named: sliderImage), for: .normal)
        processSlider.setThumbImage(UIImage(named:sliderImage), for: .normal)
    }
}

