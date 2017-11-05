//
//  MenuViewController.swift
//  FindCityFB
//
//  Created by Maxim Zaks on 05.11.17.
//  Copyright © 2017 maxim.zaks. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if
            let vc = segue.destination as? ByteCabinetViewController {
            vc.loadFromFile = segue.identifier == "fileBC"
        }
    }
}
