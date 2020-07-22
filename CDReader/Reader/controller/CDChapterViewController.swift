//
//  CDChapterViewController.swift
//  MyBox
//
//  Created by changdong cwx889303 on 2020/7/14.
//  Copyright © 2020 (c) Huawei Technologies Co., Ltd. 2012-2019. All rights reserved.
//

import UIKit

protocol CDChapterViewControllerDelegate {
    func onDidSelectdChapter(chapterIndex:Int)
}
class CDChapterViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {

    private var readModel:CDReaderModel!
    var myDelegate:CDChapterViewControllerDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        readModel = CDReaderManager.shared.readModel
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.headView)
        self.tableView.scrollToRow(at: IndexPath(row: readModel.chapterIndex, section: 0), at: .middle, animated: false)
    }
    
    lazy var tableView: UITableView = {
        let tabView = UITableView(frame: CGRect(x: 0, y: 64, width: CDSCREEN_WIDTH, height: self.view.frame.height - 64), style: .plain)
        tabView.dataSource = self
        tabView.delegate = self
        tabView.separatorStyle = .none
        return tabView
    }()
    
    lazy var headView: UIView = {
        let head = UIView(frame: CGRect(x: 0, y: 0, width: CDSCREEN_WIDTH, height: 64))
        head.backgroundColor = CDReaderManager.shared.config.theme
        let textNameLabel = UILabel(frame: CGRect(x: 15, y: 15, width: head.frame.width - 15 * 3 - 64, height: 30))
        textNameLabel.font = UIFont.boldSystemFont(ofSize: 18)
        textNameLabel.textColor = CDReaderManager.shared.config.fontColor
        textNameLabel.lineBreakMode = .byTruncatingMiddle
        textNameLabel.text = readModel.name
        head.addSubview(textNameLabel)
        
        let processLabel = UILabel(frame: CGRect(x: head.frame.width - 15 - 64, y: 15, width: 64, height: 30))
        processLabel.font = UIFont.boldSystemFont(ofSize: 12)
        processLabel.textColor = CDReaderManager.shared.config.fontColor
        processLabel.textAlignment = .right
        processLabel.text = String(format: "%.0f%%已读", (Float(readModel.chapterIndex) / Float(readModel.chaptersArr.count)) * 100)
        head.addSubview(processLabel)
        
        
        return head
    }()
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return readModel.chaptersArr.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 48
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell:UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "chapterCellIde")
        if cell == nil{
            cell = UITableViewCell(style: .default, reuseIdentifier: "chapterCellIde")
            cell.selectionStyle = .gray
            
            let chapterTitlelabel = UILabel(frame: CGRect(x: 15, y: 9, width: CDSCREEN_WIDTH - 30 - 60, height: 30))
            chapterTitlelabel.font = UIFont.systemFont(ofSize: 12)
            chapterTitlelabel.numberOfLines = 0
            cell.addSubview(chapterTitlelabel)
            chapterTitlelabel.tag = 100
            
            let pageLabel = UILabel(frame: CGRect(x: CDSCREEN_WIDTH - 50, y: 9, width: 48, height: 30))
            pageLabel.font = UIFont.systemFont(ofSize: 12)
            cell.addSubview(pageLabel)
            pageLabel.tag = 101
            
            let line = UIView(frame: CGRect(x: 15, y: cell.frame.height - 1, width: CDSCREEN_WIDTH - 10, height: 1))
            line.backgroundColor = .lightGray
            cell.addSubview(line)
            line.tag = 102
            
        }
        cell.backgroundColor = CDReaderManager.shared.config.theme
        
        let chapterTitlelabel = cell.viewWithTag(100) as! UILabel
        let pageLabel = cell.viewWithTag(101) as! UILabel
        let line = cell.viewWithTag(102)!
        
        chapterTitlelabel.textColor = CDReaderManager.shared.config.fontColor
        pageLabel.textColor = CDReaderManager.shared.config.fontColor
        
        let model = readModel.chaptersArr[indexPath.row]
        chapterTitlelabel.text = model.title
        pageLabel.text = "\(model.pageCount)"
        line.isHidden = indexPath.row == readModel.chaptersArr.count - 1
        if indexPath.row == readModel.chapterIndex {
            let color = CDReaderManager.shared.config.theme == night ?  nightBorder:
                CDReaderManager.shared.config.theme == day ? dayBorder : eyeBorder
            chapterTitlelabel.textColor = color
        } else {
            chapterTitlelabel.textColor = CDReaderManager.shared.config.fontColor
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        myDelegate.onDidSelectdChapter(chapterIndex: indexPath.row)
        self.dismiss(animated: true, completion: nil)
    }

}
