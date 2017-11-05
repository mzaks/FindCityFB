//
//  ByteCabinetViewController.swift
//  FindCityFB
//
//  Created by Maxim Zaks on 20.10.17.
//  Copyright © 2017 maxim.zaks. All rights reserved.
//

import UIKit

class ByteCabinetViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    var loadFromFile: Bool = false
    
    // MARK: mutable state, initialy set on viewViewDidLoad
    var bc : ByteCabinet!
    
    // MARK: ViewController stuff
    override func viewDidLoad() {
        super.viewDidLoad()
        // Don't forget to download the cities.bin from https://www.dropbox.com/s/tk1uff3ozr9asxz/cities.bin?dl=0
        let url = Bundle.main.url(forResource: "cities", withExtension: "bc")!
        
        if loadFromFile {
            bc = try!ByteCabinet(url: url)
        } else {
            let data = try!Data(contentsOf: url)
            bc = try!ByteCabinet(data: data)
        }
        self.title = loadFromFile ? "Cities File Reader" : "Cities Memory Reader"
        
        reload()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: DataSource and other delegates
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        let index: UInt32
        if category == 0 {
            index = UInt32(indexPath.row + (range.first ?? 0))
        } else {
            let indexCompartment: NumericCompartment<UInt32> = bc.compartment(5)!
            index = indexCompartment[UInt32(indexPath.row + (range.first ?? 0))]!
        }
        
        if
            let cityName = bc.compartment(2, StringCompartment.self)![index],
            let countryCode = bc.compartment(0, StringCompartment.self)![index] {
            cell?.textLabel?.text = "\(cityName) in \(countryCode)";
        }
        
        return cell!
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let cell = sender as? UITableViewCell,
            let indexPath = tableView.indexPath(for: cell),
            let mapVC = segue.destination as? MapViewController {
            
            let index: UInt32
            if category == 0 {
                index = UInt32(indexPath.row + (range.first ?? 0))
            } else {
                let indexCompartment: NumericCompartment<UInt32> = bc.compartment(5)!
                index = indexCompartment[UInt32(indexPath.row + (range.first ?? 0))]!
            }
            
            if
                let cityName = bc.compartment(2, StringCompartment.self)?[index],
                let countryCode = bc.compartment(0, StringCompartment.self)?[index],
                let lat = bc.compartment(3, NumericCompartment<Float32>.self)?[index],
                let lng = bc.compartment(4, NumericCompartment<Float32>.self)?[index] {
                mapVC.name = cityName
                mapVC.countryCode = countryCode
                mapVC.lat = Double(lat)
                mapVC.lng = Double(lng)
            }
        }
    }
    
    // MARK: Private functions, mutating data
    
    override func computeRange() {
        
        guard let text = searchTextField.text else { return }
        if text.isEmpty {
            let count = bc.compartment(0, StringCompartment.self)!.count
            range =  0..<count
        }
        else {
            if category == 0 {
                range = findRangeForCountryCode(prefix: text)
            } else {
                range = findRangeForCityName(prefix: text)
            }
        }
    }
    
    func findRangeForCountryCode(prefix: String) -> CountableRange<Int> {
        
        let compartment = bc.compartment(0, StringCompartment.self)!
        
        func computePrefix(code: String?, prefix: String) -> PrefixResult{
            guard let code = code?.utf8.map({$0}) else {return .Smaller}
            var i = 0
            for c in prefix.utf8 {
                guard i < code.count else {return .Smaller}
                if code[i] < c  {
                    return .Smaller
                }
                if code[i] > c  {
                    return .Bigger
                }
                i += 1
            }
            return .Equal
        }
        
        func start(_ _left : Int,_ _right : Int,_ _mid : Int) -> Int {
            var left = _left
            var right = _right
            var result = _mid
            while((left <= right)){
                let mid = (right + left) >> 1
                let prefixResult = computePrefix(code:compartment[UInt32(mid)],prefix:prefix)
                switch prefixResult {
                case .Equal:
                    result = mid
                    right = mid - 1
                case .Smaller:
                    left = mid + 1
                case .Bigger:
                    right = mid - 1
                }
            }
            return result
        }
        
        func end(_ _left : Int,_ _right : Int,_ _mid : Int) -> Int {
            var left = _left
            var right = _right
            var result = _mid
            while((left <= right)){
                let mid = (right + left) >> 1
                
                let prefixResult = computePrefix(code:compartment[UInt32(mid)],prefix:prefix)
                switch prefixResult {
                case .Equal:
                    result = mid
                    left = mid + 1
                case .Smaller:
                    left = mid + 1
                case .Bigger:
                    right = mid - 1
                }
            }
            return result
        }
        
        let count = compartment.count
        var left : Int = 0
        var right : Int = count - 1
        while((left <= right)) {
            let mid = (right + left) >> 1
            
            let code = compartment[UInt32(mid)]
            
            
            let prefixResult = computePrefix(code:code ,prefix:prefix)
            switch prefixResult {
            case .Equal:
                return start(left, right, mid)..<(end(left, right, mid)+1)
            case .Smaller:
                left = mid + 1
            case .Bigger:
                right = mid - 1
            }
        }
        return 0..<0
    }
    
    func findRangeForCityName(prefix: String) -> CountableRange<Int> {
        
        let compartment = bc.compartment(1, StringCompartment.self)!
        let compartmentIndex: NumericCompartment<UInt32> = bc.compartment(5)!
        
        func computePrefix(code: String?, prefix: String) -> PrefixResult{
            guard let code = code?.utf8.map({$0}) else {return .Smaller}
            var i = 0
            for c in prefix.utf8 {
                guard i < code.count else {return .Smaller}
                if code[i] < c  {
                    return .Smaller
                }
                if code[i] > c  {
                    return .Bigger
                }
                i += 1
            }
            return .Equal
        }
        
        func start(_ _left : Int,_ _right : Int,_ _mid : Int) -> Int {
            var left = _left
            var right = _right
            var result = _mid
            while((left <= right)){
                let mid = (right + left) >> 1
                let index = compartmentIndex[UInt32(mid)]!
                let prefixResult = computePrefix(code:compartment[index],prefix:prefix)
                switch prefixResult {
                case .Equal:
                    result = mid
                    right = mid - 1
                case .Smaller:
                    left = mid + 1
                case .Bigger:
                    right = mid - 1
                }
            }
            return result
        }
        
        func end(_ _left : Int,_ _right : Int,_ _mid : Int) -> Int {
            var left = _left
            var right = _right
            var result = _mid
            while((left <= right)){
                let mid = (right + left) >> 1
                
                let index = compartmentIndex[UInt32(mid)]!
                let prefixResult = computePrefix(code:compartment[index],prefix:prefix)
                switch prefixResult {
                case .Equal:
                    result = mid
                    left = mid + 1
                case .Smaller:
                    left = mid + 1
                case .Bigger:
                    right = mid - 1
                }
            }
            return result
        }
        
        let count = compartment.count
        var left : Int = 0
        var right : Int = count - 1
        while((left <= right)) {
            let mid = (right + left) >> 1
            
            let index = compartmentIndex[UInt32(mid)]!
            let prefixResult = computePrefix(code:compartment[index],prefix:prefix)
            
            switch prefixResult {
            case .Equal:
                return start(left, right, mid)..<(end(left, right, mid)+1)
            case .Smaller:
                left = mid + 1
            case .Bigger:
                right = mid - 1
            }
        }
        return 0..<0
    }
}
