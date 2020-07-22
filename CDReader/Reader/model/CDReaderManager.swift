//
//  CDReaderManager.swift
//  MyBox
//
//  Created by changdong on 2020/7/1.
//  Copyright changdong 2012-2019. All rights reserved.
//

import UIKit


class CDReaderManager: NSObject {
    
    var config:CDReaderConfig!
    var readModel:CDReaderModel!
    static let shared = CDReaderManager()

    override init() {
        super.init()
        config = CDReaderConfig()
    }
    
    func laodFile(filePath:String){
        readModel = CDReaderModel.getLocalModel(url: URL(fileURLWithPath: filePath))
    }
    
    func parserContent(content:String,bounds:CGRect) -> CTFrame{
        
        let attribute = parserAttribute()
        let attributeString = NSMutableAttributedString(string: content)
        attributeString.setAttributes(attribute, range: NSRange(location: 0, length: content.count))
        let setterRef:CTFramesetter = CTFramesetterCreateWithAttributedString(attributeString as CFAttributedString)
        let pathRef = CGPath(rect: bounds, transform: nil)
        let frmaeRef:CTFrame = CTFramesetterCreateFrame(setterRef, CFRangeMake(0, 0), pathRef, nil)
        
        return frmaeRef
    }
}

@inline(__always) func encodeUrl(url:URL?) -> String? {
    if url == nil {
        return nil
    }
    // utf8,GB 18030,GBK
    let encodingArr:[String.Encoding] = [.utf8,String.Encoding(rawValue: 0x80000632),String.Encoding(rawValue: 0x80000631)]
    for i in 0..<encodingArr.count{
        do {
            let content = try String(contentsOf: url!, encoding: encodingArr[i])
            return content
        } catch  {
            print("encodeUrl-error:",error)
        }
    }
    return nil
}

@inline(__always) func parserAttribute() -> [NSAttributedString.Key:Any]{
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineSpacing = CDReaderManager.shared.config.lineSpace
    paragraphStyle.alignment = .justified
    
    let dict = [NSAttributedString.Key.foregroundColor:CDReaderManager.shared.config.fontColor!,
                NSAttributedString.Key.font:UIFont(name: "Helvetica", size: CGFloat(CDReaderManager.shared.config.fontSize))!,
            NSAttributedString.Key.paragraphStyle:paragraphStyle
        ] as [NSAttributedString.Key : Any]
    
    return dict
}
