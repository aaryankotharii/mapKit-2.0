//
//  ViewController.swift
//  Maps 2.0
//
//  Created by Aaryan Kothari on 08/02/20.
//  Copyright © 2020 Aaryan Kothari. All rights reserved.
//


import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, UITabBarControllerDelegate{

     //OUTLETS
    @IBOutlet weak var loc1: UIButton!
    @IBOutlet weak var loc2: UIButton!
    @IBOutlet weak var loc3: UIButton!
    
    @IBOutlet weak var lab1: UILabel!
    @IBOutlet weak var lab2: UILabel!
    @IBOutlet weak var lab3: UILabel!
    
    @IBOutlet weak var goButton: UIButton!
    @IBOutlet weak var pinImage: UIImageView!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var addressLabel: UILabel!
    
    
    //VARIABLES
    let locationManager = CLLocationManager()
    var previousLocation : CLLocation?
    var directionsArray : [MKDirections] = []
    var senderArray = [UIButton]()
    var labels = [UILabel]()
    var item = 0
    var toggle = true

    
    override func viewDidLoad() {
    super.viewDidLoad()
    initialSetup()
    checkLocationServicesEnables()
    }
    
    
    //Misc Setup
    func initialSetup(){
    loc1.tintColor = UIColor.black
    lab1.textColor = UIColor.black
    pinImage.isHidden = true
    goButton.isHidden = true
    addressLabel.isHidden = true
    senderArray = [loc1,loc2,loc3]
    labels = [lab1,lab2,lab3]
    }
    
    //setup location manager
    func setupLocationManager(){
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
        
    //verify location status
    func checkLocationServicesEnables(){
    if CLLocationManager.locationServicesEnabled() {
        setupLocationManager()
        checkLocationAuthorization()
    } else {
        createAlert(message: "Please Turn on Locations from settings")
            }
        }
        
    //check location authorization
    func checkLocationAuthorization(){
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
        mapView.showsUserLocation = true
        centreViewOnUsersLocation()
        locationManager.startUpdatingLocation()
        previousLocation = getCentreLocation(for: mapView)
        break
        case .denied:
        break
        case .notDetermined:
        locationManager.requestWhenInUseAuthorization()
        break
        case .restricted:
        break
        case .authorizedAlways:
        break
        @unknown default:
            fatalError()
        }
    }
        
    
    func centreViewOnUsersLocation(){
    if let location = locationManager.location?.coordinate {
        let region = MKCoordinateRegion.init(center: location, latitudinalMeters: 10000, longitudinalMeters: 1000)
        mapView.setRegion(region, animated: true)
        }
    }

    
    
  func getCentreLocation(for mapView : MKMapView) -> CLLocation {
      let latitude = mapView.centerCoordinate.latitude
      let longitude = mapView.centerCoordinate.longitude
      return CLLocation(latitude: latitude, longitude: longitude)
  }
    
    //directions
    func getDirection(){
    guard let location = locationManager.location?.coordinate else {
        createAlert(message: "Couldnt get your location")
        return
       }
        
    let request = createDirectionsRequest(from: location)
    let directions = MKDirections(request: request)
    resetMapView(withNew: directions)
    directions.calculate { (response, error) in
        guard let response = response else { return } // response not available
        for route in response.routes {
            self.mapView.addOverlay(route.polyline)
            self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
           }
        }
    }
       
    
   func createDirectionsRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request {
       let destinationCoordinate    =    getCentreLocation(for: mapView).coordinate
       let startingLocation         =    MKPlacemark(coordinate: coordinate)
       let destination              =    MKPlacemark(coordinate: destinationCoordinate)
       let request = MKDirections.Request()
       request.source = MKMapItem(placemark: startingLocation)
       request.destination = MKMapItem(placemark: destination)
       request.transportType = .automobile
       request.requestsAlternateRoutes = true
       return request
   }
   
    //erase previous overlays
   func resetMapView(withNew directions: MKDirections){
       mapView.removeOverlays(mapView!.overlays)
       directionsArray.append(directions)
       let _ = directionsArray.map {$0.cancel() }
   }
   

    //GO
    @IBAction func showDirections(_ sender: Any) {
    toggle.toggle()
    if toggle == false {
        getDirection()
        pinImage.isHidden = true
        goButton.setTitle("X", for: .normal)
    }else{
        mapView.removeOverlays(mapView!.overlays)
        centreViewOnUsersLocation()
        pinImage.isHidden = false
        goButton.setTitle("Go", for: .normal)
        }
    }
    
    
    @IBAction func tabBar(_ sender: UIButton) {
        print("Tab selected is",sender.tag)
        item = sender.tag
        checkLocationServicesEnables()
        for i in senderArray {
            if senderArray.firstIndex(of: i) == sender.tag {
                i.tintColor = UIColor.black
                labels[sender.tag].textColor = UIColor.black
            }
            else{
                i.tintColor = UIColor.gray
                labels[senderArray.firstIndex(of: i)!].textColor = UIColor.gray
            }
        }
        
        switch sender.tag {
        case 0:
            goButton.isHidden = true
            addressLabel.text = ""
            addressLabel.isHidden = true
            mapView.removeOverlays(mapView!.overlays)
            pinImage.isHidden = true
        case 1:
            goButton.isHidden = true
            addressLabel.isHidden = false
            addressLabel.text = "move pin..."
            mapView.removeOverlays(mapView!.overlays)
            pinImage.isHidden = false
        case 2:
            goButton.isHidden = false
            addressLabel.text = ""
            addressLabel.isHidden = true
            pinImage.isHidden = false
        default:
            print("no other case")
        }
    }
    
    //Create alert function
    func createAlert(message: String){
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "ok", style: .default, handler: nil)
        alert.addAction(action)
    }
    }


extension ViewController : CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        if self.item == 0 {
            let centre = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let region = MKCoordinateRegion(center: centre, latitudinalMeters: 5000, longitudinalMeters: 5000)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {  checkLocationAuthorization()  }
}



extension ViewController : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let centre = getCentreLocation(for: mapView)
        let geoCoder = CLGeocoder()
        
        guard let _ = self.previousLocation else { return }
        guard centre.distance(from: self.previousLocation!) > 50 else { return }
        self.previousLocation = centre
        
        geoCoder.reverseGeocodeLocation(centre) { [weak self] (placemarks,error) in
            guard let self = self else { return }
            if let _ = error {
                self.createAlert(message: "ERROR")
            }
            guard let placemark = placemarks?.first else { return }
            let streetNumber = placemark.subThoroughfare ?? ""
            let streetName = placemark.thoroughfare ?? ""
            
            DispatchQueue.main.async {
                if self.item == 1 {
                    self.addressLabel.text = "\(streetNumber) \(streetName)"
                }
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: (overlay as? MKPolyline)!)
        renderer.strokeColor = .blue
        return renderer
    }
}
