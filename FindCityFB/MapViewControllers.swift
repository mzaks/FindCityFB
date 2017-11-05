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

class MapViewController: UIViewController {
    var name: String!
    var countryCode: String!
    var lng: Double!
    var lat: Double!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let location = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        let region = MKCoordinateRegionMakeWithDistance (location, 10000, 10000)
        
        self.title = "\(name!) in \(countryCode!)"
        
        map.setRegion(region, animated: true)
    }
    @IBOutlet weak var map: MKMapView!
}
