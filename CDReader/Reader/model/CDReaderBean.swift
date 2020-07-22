//
//  CDReaderModel.swift
//  MyBox
//
//  Created by changdong on 2020/7/1.
//  Copyright changdong 2012-2019. All rights reserved.
//

import UIKit
import CoreText

let TopSpacing:CGFloat = 40.0
let BottomSpacing:CGFloat = 40.0
let LeftSpacing:CGFloat = 20.0
let RightSpacing:CGFloat =  20.0
let CDSCREEN_WIDTH = UIScreen.main.bounds.size.width
let CDSCREEN_HEIGTH = UIScreen.main.bounds.size.height
let CDViewHeight = CDSCREEN_HEIGTH - NavigationHeight - StatusHeight
let iPhoneX = (UIScreen.main.bounds.size.width == 375.0 && UIScreen.main.bounds.size.height == 812.0) || (UIScreen.main.bounds.size.width == 414.0 && UIScreen.main.bounds.size.height == 869.0)

let StatusHeight:CGFloat = iPhoneX ? 44.0 : 20.0
let NavigationHeight:CGFloat = 44

class CDReaderModel: NSObject,NSCoding {

    public var resourceUrl:URL! //小说路径
    public var name:String!    //小说名
    public var gcontent:String! //小说内容
    @objc dynamic var chaptersArr:[CDChapterModel] = []  //小说章节
    public var chapterModel:CDChapterModel! //小说当前章节chapterModel = chaptersArr[chapterIndex]
    public var pageIndex:Int = 0 //当前阅读的页数
    public var chapterIndex:Int = 0 //当前阅读的章节数
    private var chapterThread:Thread!
    init(content:String) {
        super.init()
        gcontent = content
        self.addObserver(self, forKeyPath: "chaptersArr", options: [.new,.old], context: nil)
        chapterThread = Thread(target: self, selector: #selector(separateChapter), object: nil)
        chapterThread.name = "chapterThread"
        chapterThread.start()

        
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        let new = change?[NSKeyValueChangeKey.newKey] as? [CDChapterModel]
        let old = change?[NSKeyValueChangeKey.oldKey] as? [CDChapterModel]
        if old?.count == 0 && new?.count ?? 0 > 0 {
            chapterModel = new?[0]
            NotificationCenter.default.post(name: NSNotification.Name("TXTLoadToModel"), object: nil)
        }
        
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(gcontent, forKey: "gcontent")
        coder.encode(chaptersArr, forKey: "chaptersArr")
        coder.encode(pageIndex, forKey: "pageIndex")
        coder.encode(chapterIndex, forKey: "chapterIndex")
        coder.encode(resourceUrl, forKey: "resource")
        coder.encode(name, forKey: "name")
    }
    
    /**
    解析
    */
    required init?(coder: NSCoder) {
        super.init()
        gcontent = coder.decodeObject(forKey: "gcontent") as? String
        name = coder.decodeObject(forKey: "name") as? String
        chaptersArr = coder.decodeObject(forKey: "chaptersArr") as! [CDChapterModel]
        chapterIndex = coder.decodeInteger(forKey: "chapterIndex")
        pageIndex = coder.decodeInteger(forKey: "pageIndex")
        resourceUrl = coder.decodeObject(forKey: "resource") as? URL
        chapterModel = chaptersArr[chapterIndex]
    }
    
    /**
    将资源更新保存到本地
    */
    static func updateLocalModel(model:CDReaderModel,url:URL){
        let key = (url.path as NSString).lastPathComponent
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWith: data)
        archiver.encode(model, forKey: key)
        archiver.finishEncoding()
        UserDefaults.standard.set(data, forKey: key)
        
    }
    
    /**
    从本地获取资源
    */
    static func getLocalModel(url:URL) ->CDReaderModel{
        let key = (url.path as NSString).lastPathComponent
        let data = UserDefaults.standard.object(forKey: key) as? Data
        if data == nil {
            let model = CDReaderModel(content: encodeUrl(url: url)!)
            model.resourceUrl = url
            model.name = (key as NSString).deletingPathExtension
            CDReaderModel.updateLocalModel(model: model, url: url)
            return model
        }
        let unarchive = NSKeyedUnarchiver(forReadingWith: data!)
        let model = unarchive.decodeObject(forKey: key) as! CDReaderModel
        model.chapterModel = model.chaptersArr[model.chapterIndex]
        return model
    }
    
    /**
    对章节分页
    */
    public func getPageIndex(offset:NSInteger,chapterIndex:NSInteger) -> NSInteger {
        let chapter = chaptersArr[chapterIndex]
        let pageArr = chapter.pageArray
        for i in 0..<pageArr.count {
            if offset >= pageArr[i] && offset < pageArr[i + 1] {
                return i
            }
        }
        if offset >= pageArr[pageArr.count - 1] {
            return pageArr.count - 1
        }
        return 0
    }
    
    /**
     正则匹配解析目录
     */
    @objc func separateChapter() {
        chaptersArr.removeAll()
    
        let parten = "\n第?[0-9一二三四五六七八九十百千]+[章].*"
        guard let regex = try? NSRegularExpression(pattern: parten, options: []) else {
            return
        }
        let nsContent = gcontent as NSString
        let match = regex.matches(in: gcontent, options: .reportCompletion, range: NSRange(location: 0, length: gcontent.count))
        if match.count != 0 {
            var lastRange = NSRange(location: 0, length: 0)
            
            for idx in 0..<match.count {
                let obj = match[idx]
                let range = obj.range
                let location = range.location
                if idx == 0 {
                    let model = CDChapterModel()
                    model.title = "开始"
                    let len = location
                    model.content = nsContent.substring(with: NSRange(location: 0, length: len))
                    self.chaptersArr.append(model)
                }
                
                if idx > 0 {
                    let model = CDChapterModel()
                    model.title = nsContent.substring(with: lastRange)
                    let len = location - lastRange.location
                    model.content = nsContent.substring(with: NSRange(location: lastRange.location, length: len))
                    self.chaptersArr.append(model)
                }
                if idx == match.count - 1 {
                    let model = CDChapterModel()
                    model.title = nsContent.substring(with: range)
                    model.content = nsContent.substring(with: NSRange(location: location, length: nsContent.length - location))
                    self.chaptersArr.append(model)
                }
                lastRange = range
            }
            self.chapterThread.cancel()
        } else {
            let model = CDChapterModel()
            model.content = gcontent
            self.chaptersArr.append(model)
            chapterThread.cancel()
        }
        
    }
}


class CDChapterModel: NSObject,NSCopying,NSCoding {
    var pageArray:[Int] = []
    var title = String()
    var pageCount = Int()
    private var gcontent:String?
    override init() {
        super.init()
        
    }
    var content:String?{
        get {
            return gcontent
        }
        set{
            gcontent = newValue
            paginate(bounds:CGRect(x: LeftSpacing, y: TopSpacing, width: UIScreen.main.bounds.width - LeftSpacing - RightSpacing, height: UIScreen.main.bounds.height - TopSpacing - BottomSpacing))
            
        }
    }
    func copy(with zone: NSZone? = nil) -> Any {
        let model = CDChapterModel.copy() as! CDChapterModel
        model.content = content
        model.title = title
        model.pageCount = pageCount
        return model
    }

    
    func encode(with coder: NSCoder) {
        coder.encode(content, forKey: "content")
        coder.encode(title, forKey: "title")
        coder.encode(pageCount, forKey: "pageCount")
        coder.encode(pageArray, forKey: "pageArray")
    }
    
    required init?(coder: NSCoder) {
        super.init()
        content = coder.decodeObject(forKey: "content") as? String
        title = coder.decodeObject(forKey: "title") as! String
        pageCount = coder.decodeInteger(forKey: "pageCount")
        pageArray = coder.decodeObject(forKey: "pageArray") as! [Int]
    }
    
    func updateFont() {
        paginate(bounds:CGRect(x: LeftSpacing, y: TopSpacing, width: UIScreen.main.bounds.width - LeftSpacing - RightSpacing, height: UIScreen.main.bounds.height - TopSpacing - BottomSpacing))
    }
    
    
    func paginate(bounds:CGRect) {
        pageArray.removeAll()
        let attrString = NSMutableAttributedString(string: gcontent!)
        let attribute = parserAttribute()
        attrString.setAttributes(attribute, range: NSRange(location: 0, length: attrString.length))
        let frameSetter = CTFramesetterCreateWithAttributedString(attrString)
        let path = CGPath.init(rect: bounds, transform: nil)
        
        var currentOffset = 0;
        var currentInnerOffset = 0;
        var hasMorePages = true;
        // 防止死循环，如果在同一个位置获取CTFrame超过2次，则跳出循环
        let preventDeadLoopSign = currentOffset;
        var samePlaceRepeatCount = 0;
        while hasMorePages {
            if preventDeadLoopSign == currentOffset {
                samePlaceRepeatCount += 1
            } else {
                samePlaceRepeatCount = 0
            }
            
            if samePlaceRepeatCount > 1 {
                if pageArray.count == 0 {
                    pageArray.append(currentOffset)
                } else {
                    let lastOffset = pageArray.last
                    if lastOffset != currentOffset {
                        pageArray.append(currentOffset)
                    }
                }
                break
            }
            pageArray.append(currentOffset)
            let frame = CTFramesetterCreateFrame(frameSetter, CFRange(location: currentInnerOffset, length: 0), path, nil)
            let range = CTFrameGetVisibleStringRange(frame)
            
            if range.location + range.length != attrString.length {
                currentOffset += range.length
                currentInnerOffset += range.length
            } else {
                hasMorePages = false;
            }
        }
        pageCount = pageArray.count
    }
    
    
    func stringOfPage(index:Int) -> String {
        assert(true, "stringOfPage-Index out of range")
        let local = pageArray[index]
        var length = 0
        if index < pageCount - 1 {
            length = pageArray[index + 1] - pageArray[index]
        } else {
            length = gcontent!.count - pageArray[index]
        }
        let subStr = (gcontent! as NSString).substring(with: NSRange(location: local, length: length))
        return subStr as String
    }
    
}

let day = UIColor(red: 246/255.0, green: 245/255.0, blue: 249/255.0, alpha: 1.0)
let night = UIColor.black
let eye = UIColor(red: 193/255.0, green: 238/255.0, blue: 196/255.0, alpha: 1.0)

let dayBorder = UIColor(red: 62/255.0, green: 137/255.0, blue: 237/255.0, alpha: 1.0)
let nightBorder = UIColor(red: 62/255.0, green: 137/255.0, blue: 237/255.0, alpha: 1.0)
let eyeBorder = UIColor(red: 64/255.0, green: 153/255.0, blue: 44/255.0, alpha: 1.0)

let MaxFont:Float = 40
let MinFont:Float = 14
let LineSpace:CGFloat = 10
class CDReaderConfig: NSObject,NSCoding {
    var lineSpace:CGFloat! //行宽
    var theme:UIColor!     //背景色
    var fontColor:UIColor! //字体色
    var fontSize:Float!    //字体大小
    
    override init() {
        super.init()
        let data = UserDefaults.standard.object(forKey: "CDReaderConfig") as? Data
        if data != nil {
            let unchive = NSKeyedUnarchiver(forReadingWith: data!)
            let config = unchive.decodeObject(forKey: "CDReaderConfig") as! CDReaderConfig
            lineSpace = config.lineSpace
            fontSize = config.fontSize
            fontColor = config.fontColor
            theme = config.theme
            
        } else {
            //初始化 默认
            lineSpace = LineSpace
            fontSize = MinFont
            fontColor = night
            theme = day
            CDReaderConfig.updateLocalConfig(conflg: self)
        }
        
    }
    
    static func updateLocalConfig(conflg:CDReaderConfig) {
        let data = NSMutableData()
        let archive = NSKeyedArchiver(forWritingWith: data)
        archive.encode(conflg, forKey: "CDReaderConfig")
        archive.finishEncoding()
        UserDefaults.standard.set(data, forKey: "CDReaderConfig")
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(fontSize, forKey: "fontSize")
        coder.encode(lineSpace, forKey: "lineSpace")
        coder.encode(fontColor, forKey: "fontColor")
        coder.encode(theme, forKey: "theme")
    }
    
    required init?(coder: NSCoder) {
        super.init()
        fontColor = coder.decodeObject(forKey: "fontColor") as? UIColor
        fontSize = coder.decodeObject(forKey: "fontSize") as? Float
        lineSpace = coder.decodeObject(forKey: "lineSpace") as? CGFloat
        theme = coder.decodeObject(forKey: "theme") as? UIColor
    }
}
