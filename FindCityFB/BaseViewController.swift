//
//  BaseViewController.swift
//  FindCityFB
//
//  Created by Maxim Zaks on 17.04.17.
//  Copyright © 2017 maxim.zaks. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController {
    var category = 0
    var range : CountableRange<Int>!
    var _queryTime : Double = 0
    
    // MARK: IB Outlets and Actions
    @IBOutlet weak var searchTextField: UITextField!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var numberOfCitiesLabel: UILabel!
    
    @IBAction func changeCategory(_ sender: UISegmentedControl) {
        searchTextField.text = ""
        category = sender.selectedSegmentIndex
        reload()
    }
    
    @IBAction func searchTermChanged(_ sender: UITextField) {
        reload()
    }
    
    @IBAction func closeKeyboard(_ sender: UITextField) {
        self.view.endEditing(true)
    }
    
    // MARK: DataSource and other delegates
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return range.count
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if velocity.y > 0 {
            self.searchTextField.resignFirstResponder()
        }
    }
    
    // MARK: Private functions, mutating data
    
    func reload(){
        let before = Date()
        computeRange()
        let after = Date()
        _queryTime = round((after.timeIntervalSince1970 - before.timeIntervalSince1970) * 1_000_000) / 1_000
        numberOfCitiesLabel.text = "\(range.count) cities found in \(_queryTime)ms"
        tableView.reloadData()
        if range.isEmpty == false {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: UITableViewScrollPosition.top, animated: true)
        }
    }
    
    func computeRange() {
    }
}
