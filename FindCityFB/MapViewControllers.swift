//
//  MapViewController.swift
//  FindCityName
//
//  Created by Maxim Zaks on 05.03.16.
//  Copyright © 2016 maxim.zaks. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation


class FileReaderMapViewController: UIViewController {
    var city : City_Direct<FlatBuffersFileReader>! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let location = CLLocationCoordinate2D(latitude: Double(city.latitude), longitude: Double(city.longitude))
        let region = MKCoordinateRegionMakeWithDistance (location, 10000, 10000)
        
        self.title = "\((city.name!§)!) in \((city.countryCode!§)!)"
        
        map.setRegion(region, animated: true)
    }
    @IBOutlet weak var map: MKMapView!
}

class MemoryReaderMapViewController: UIViewController {
    var city : City_Direct<FlatBuffersMemoryReader>! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let location = CLLocationCoordinate2D(latitude: Double(city.latitude), longitude: Double(city.longitude))
        let region = MKCoordinateRegionMakeWithDistance (location, 10000, 10000)
        
        self.title = "\((city.name!§)!) in \((city.countryCode!§)!)"
        
        map.setRegion(region, animated: true)
    }
    @IBOutlet weak var map: MKMapView!
}
