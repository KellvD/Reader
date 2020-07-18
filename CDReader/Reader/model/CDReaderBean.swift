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
    public var chaptersArr:[CDChapterModel] = []  //小说章节
    public var record:CDRecordModel!
    
    init(content:String) {
        super.init()
        gcontent = content
        var charpterArr:[CDChapterModel] = []
        CDReaderUtilites.separateChapter(&charpterArr, content: content)
        chaptersArr = charpterArr
        record = CDRecordModel()
        record.chapterModel = chaptersArr.first
        record.chapterTotalCount = chaptersArr.count
    }
    func encode(with coder: NSCoder) {
        coder.encode(gcontent, forKey: "gcontent")
        coder.encode(chaptersArr, forKey: "chaptersArr")
        coder.encode(record, forKey: "record")
        coder.encode(resourceUrl, forKey: "resource")
        coder.encode(name, forKey: "name")
    }
    required init?(coder: NSCoder) {
        super.init()
        gcontent = coder.decodeObject(forKey: "gcontent") as? String
        name = coder.decodeObject(forKey: "name") as? String
        chaptersArr = coder.decodeObject(forKey: "chaptersArr") as! [CDChapterModel]
        record = coder.decodeObject(forKey: "record") as? CDRecordModel
        resourceUrl = coder.decodeObject(forKey: "resource") as? URL
    }
    static func updateLocalModel(model:CDReaderModel,url:URL){
        let key = (url.path as NSString).lastPathComponent
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWith: data)
        archiver.encode(model, forKey: key)
        archiver.finishEncoding()
        UserDefaults.standard.set(data, forKey: key)
        
    }
    static func getLocalModel(url:URL) ->CDReaderModel{
        let key = (url.path as NSString).lastPathComponent
        let data = UserDefaults.standard.object(forKey: key) as? Data
        if data == nil {
            let model = CDReaderModel(content: CDReaderUtilites.encodeUrl(url: url)!)
            model.resourceUrl = url
            model.name = (key as NSString).deletingPathExtension
            CDReaderModel.updateLocalModel(model: model, url: url)
            return model
        }
        let unarchive = NSKeyedUnarchiver(forReadingWith: data!)
        let model = unarchive.decodeObject(forKey: key) as! CDReaderModel
        return model
    }
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

}


class CDChapterModel: NSObject,NSCopying,NSCoding {
    var pageArray:[Int] = []
    var title = String()
    var pageCount = Int()
    var process = Double()
    var chapterIndex = Int()
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
        coder.encode(gcontent, forKey: "gcontent")
        coder.encode(title, forKey: "title")
        coder.encode(pageCount, forKey: "pageCount")
        coder.encode(pageArray, forKey: "pageArray")
    }
    
    required init?(coder: NSCoder) {
        super.init()
        gcontent = coder.decodeObject(forKey: "gcontent") as? String
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
        let attribute = CDReaderUtilites.parserAttribute(config: CDReaderConfig.shared)
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

class CDRecordModel: NSObject,NSCopying,NSCoding {
    
    var chapterModel:CDChapterModel!;  //当前阅读的章节
    var pageIndex  = Int() //当前阅读的页数
    var chapterIndex = Int() //当前阅读的章节数
    var chapterTotalCount = Int()//总章节数
    
    override init() {
        super.init()
    }
    func copy(with zone: NSZone? = nil) -> Any {
        let model = self.copy(with: zone) as! CDRecordModel
        model.chapterModel = chapterModel.copy() as? CDChapterModel
        model.pageIndex = pageIndex
        model.chapterIndex = chapterIndex
        return model
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(chapterModel, forKey: "currentChapterModel")
        coder.encode(pageIndex, forKey: "currentPageIndex")
        coder.encode(chapterIndex, forKey: "currentChapterIndex")
        coder.encode(chapterTotalCount, forKey: "chapterTotalCount")
    }
    
    required init?(coder: NSCoder) {
        super.init()
        chapterIndex = coder.decodeInteger(forKey: "currentChapterIndex")
        pageIndex = coder.decodeInteger(forKey: "currentPageIndex")
        chapterTotalCount = coder.decodeInteger(forKey: "chapterTotalCount")
        chapterModel = coder.decodeObject(forKey: "currentChapterModel") as? CDChapterModel
    }
}
