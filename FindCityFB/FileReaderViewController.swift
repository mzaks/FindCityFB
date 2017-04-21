//
//  ViewController.swift
//  FindCityApp
//
//  Created by Maxim Zaks on 05.03.16.
//  Copyright © 2016 maxim.zaks. All rights reserved.
//

import UIKit

class FileReaderViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {

// MARK: mutable state, initialy set on viewViewDidLoad
    var list : CityList_Direct<FlatBuffersFileReader>!
    
    var cityList : FlatBuffersTableVector<City_Direct<FlatBuffersFileReader>, FlatBuffersFileReader> {
        if category == 0 {
            return list.cityByCountryCode
        }
        return list.cityByName
    }

// MARK: ViewController stuff
    override func viewDidLoad() {
        super.viewDidLoad()
        // Don't forget to download the cities.bin from https://www.dropbox.com/s/tk1uff3ozr9asxz/cities.bin?dl=0
        let url = Bundle.main.url(forResource: "cities", withExtension: "bin")!
        
        let fh = try!FileHandle(forReadingFrom: url)
        let reader = FlatBuffersFileReader(fileHandle: fh)
        
        list = CityList_Direct(reader)
        
        reload()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
// MARK: DataSource and other delegates
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        if let city = cityList[indexPath.row + (range.first ?? 0)],
            let cityNameBuffer = city.name,
            let cityName = cityNameBuffer§,
            let countryCodeBuffer = city.countryCode,
            let countryCode = countryCodeBuffer§ {
            cell?.textLabel?.text = "\(cityName) in \(countryCode)";
        }
        
        return cell!
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let cell = sender as? UITableViewCell,
            let indexPath = tableView.indexPath(for: cell),
            let mapVC = segue.destination as? FileReaderMapViewController {
            
            mapVC.city = cityList[indexPath.row + (range.first ?? 0)]
        }
    }
    
// MARK: Private functions, mutating data
    
    override func computeRange() {
        guard let text = searchTextField.text else { return }
        if text.isEmpty {
            range = 0..<cityList.count
        } else {
            if category == 0 {
                range = cityList.itemsWithStringPrefix(text.lowercased()){
                    return $0?.countryCode
                }
            } else {
                range = cityList.itemsWithStringPrefix(text.lowercased()){
                    return $0?.searchName

                }
            }
        }
    }
}

