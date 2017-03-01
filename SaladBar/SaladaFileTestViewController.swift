//
//  SaladaFileTestViewController.swift
//  Salada
//
//  Created by 1amageek on 2017/03/01.
//  Copyright © 2017年 Stamp. All rights reserved.
//

import UIKit

class SaladaFileTestViewController: UIViewController {

    @IBAction func start(_ sender: Any) {
        let image: UIImage = #imageLiteral(resourceName: "pexels-photo.jpg")
        let data: Data = UIImageJPEGRepresentation(image, 1)!
        
        let tmpURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("sample")
            .appendingPathExtension("jpg")
        
        try! data.write(to: tmpURL)

        let file: Salada.File = Salada.File(url: tmpURL)
        let item: Item = Item()
        item.file = file
        item.index = 0
        item.save { (ref, error) in
            if let error = error {
                print(error)
            }
            print("Save")
        }
        
    }
    
}
