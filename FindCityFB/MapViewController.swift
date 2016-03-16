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


class MapViewController: UIViewController, MKMapViewDelegate {
    var city : City.LazyAccess! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let location = CLLocationCoordinate2D(latitude: Double(city.latitude), longitude: Double(city.longitude))
        let region = MKCoordinateRegionMakeWithDistance (location, 10000, 10000);
        
        self.title = "\(city.name!) in \(city.countryCode!)"
        
        map.setRegion(region, animated: true)
    }
    @IBOutlet weak var map: MKMapView!
}