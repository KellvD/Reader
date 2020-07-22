//
//  ViewController.swift
//  CDReader
//
//  Created by changdong cwx889303 on 2020/6/9.
//  Copyright © 2020 (c) Huawei Technologies Co., Ltd. 2012-2019. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .gray
        let itemBtn = UIButton(type:.custom)
        
        itemBtn.frame = CGRect(x: 100, y: 100, width: 100, height: 45.0)
        itemBtn.setTitle("点击", for: .normal)
        itemBtn.addTarget(self, action: #selector(onOptionClick(_:)), for: .touchUpInside)
        self.view.addSubview(itemBtn)
    }
    
    @objc func onOptionClick(_ sender:UIButton){
        let readVC = CDReaderPageViewController()
        readVC.hidesBottomBarWhenPushed = true
        readVC.resource = Bundle.main.path(forResource: "黑道特种兵 2", ofType: "txt")
        self.navigationController?.pushViewController(readVC, animated: true)
    }

    
}

