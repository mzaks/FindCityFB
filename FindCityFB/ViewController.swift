//
//  ViewController.swift
//  FindCityApp
//
//  Created by Maxim Zaks on 05.03.16.
//  Copyright © 2016 maxim.zaks. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

// MARK: mutable state, initialy set on viewViewDidLoad
    var _data : NSData!
    var list : CityList.LazyAccess!
    var category = 0
    var range : Range<Int>!
    var _queryTime : Double = 0
    
    var cityList : LazyVector<City.LazyAccess> {
        if category == 0 {
            return list.cityByCountryCode
        }
        return list.cityByName
    }

// MARK: ViewController stuff
    override func viewDidLoad() {
        super.viewDidLoad()
        // Don't forget to download the cities.bin from https://www.dropbox.com/s/tk1uff3ozr9asxz/cities.bin?dl=0
        let url = NSBundle.mainBundle().URLForResource("cities", withExtension: "bin")!
        _data = NSData.init(contentsOfURL: url)!
        let data = UnsafePointer<UInt8>(_data.bytes)
        list = CityList.LazyAccess(data: data)
        
        reload()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
// MARK: IB Outlets and Actions
    @IBOutlet weak var searchTextField: UITextField!

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var numberOfCitiesLabel: UILabel!
    
    @IBAction func changeCategory(sender: UISegmentedControl) {
        searchTextField.text = ""
        category = sender.selectedSegmentIndex
        reload()
    }
    
    @IBAction func searchTermChanged(sender: UITextField) {
        reload()
    }
    
    @IBAction func closeKeyboard(sender: UITextField) {
        self.view.endEditing(true)
    }
    
// MARK: DataSource and other delegates
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return range.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell")
        let city = cityList[indexPath.row + (range.first ?? 0)]!
        
        cell?.textLabel?.text = "\(city.name!) in \(city.countryCode!)";
        return cell!
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let indexPath = tableView.indexPathForCell(sender as! UITableViewCell)!
        let mapVC = segue.destinationViewController as! MapViewController
        
        mapVC.city = cityList[indexPath.row + (range.first ?? 0)]!
        
    }
    
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if velocity.y > 0 {
            self.searchTextField.resignFirstResponder()
        }
    }

// MARK: Private functions, mutating data

    func reload(){
        let before = NSDate()
        computeRange()
        let after = NSDate()
        _queryTime = round((after.timeIntervalSince1970 - before.timeIntervalSince1970) * 1_000_000) / 1_000
        numberOfCitiesLabel.text = "\(range.count) cities found in \(_queryTime)ms"
        tableView.reloadData()
        if range.isEmpty == false {
            tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: UITableViewScrollPosition.Top, animated: true)
        }
    }
    
    func computeRange() {
        if searchTextField.text!.isEmpty {
            range = 0..<cityList.count
        } else {
            if category == 0 {
                range = cityList.itemsWithStringPrefix(searchTextField.text!){
                    $0.countryCode!
                }
            } else {
                range = cityList.itemsWithStringPrefix(searchTextField.text!){
                    $0.searchName!
                }
            }
        }
    }
}

