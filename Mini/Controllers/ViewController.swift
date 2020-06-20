//
//  ViewController.swift
//  Mini
//
//  Created by Rishi Palivela on 16/06/20.
//  Copyright © 2020 StarDust. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import FirebaseUI

class ViewController: UIViewController {
    
    var locationManager: CLLocationManager?
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var zoomToUserLocationButton: UIButton!
    @IBOutlet weak var shareLocationButton: UIButton!
    @IBOutlet weak var alignNorthButton: RoundButton!
    @IBOutlet weak var emergencyButton: RoundButton!
    
    var user: User?
    var authUI: FUIAuth!
    var authStateHandle: AuthStateDidChangeListenerHandle?
    
    /// Called after view is loaded into memory
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startLocation()
        
        mapView.delegate = self
        mapView.showsCompass = false
        zoomToUserLocationTapped(self)
        
        searchBar.textField?.backgroundColor = .searchBarBackground
        zoomToUserLocationButton.backgroundColor = .mapButtonBackground
        alignNorthButton.backgroundColor = .mapButtonBackground
        
        searchBar.delegate = self
        
        authUI = (UIApplication.shared.delegate as! AppDelegate).authUI
        addAuthObserver()
        NotificationCenter.default.addObserver(self, selector: #selector(addAuthObserver),
                                               name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(removeAuthObserver),
                                               name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    
    /// Called after view appears on screen
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    /// Called after view is removed from screen
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        locationManager?.delegate = self
        locationManager?.stopUpdatingLocation()
    }
    
    @objc func addAuthObserver() {
        guard authStateHandle == nil else { return }
        print("\(Date()) \(URL(fileURLWithPath: #file).deletingPathExtension().lastPathComponent).\(#function)")
        
        authStateHandle = authUI.auth?.addStateDidChangeListener { [unowned self] (auth, user) in
            if let user = user {
                self.user = user
            } else {
                self.user = nil
                self.present(self.authUI.authViewController(), animated: true)
            }
            
        }
    }
    
    @objc func removeAuthObserver() {
        if let _ = authStateHandle {
            print("\(Date()) \(URL(fileURLWithPath: #file).deletingPathExtension().lastPathComponent).\(#function)")
            
            authUI.auth?.removeStateDidChangeListener(authStateHandle!)
            authStateHandle = nil
        }
    }
    
    /// Function to check for Location Permissions. If permission is granted, starts user location monitoring, else asks for permission
    fileprivate func startLocation() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager?.requestAlwaysAuthorization()
        } else if CLLocationManager.authorizationStatus() == .authorizedAlways || CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            locationManager?.startUpdatingLocation()
            
            shareLocationButton.isEnabled = true
            zoomToUserLocationButton.isEnabled = true
            alignNorthButton.isEnabled = true
        }
    }
    
    @IBAction func zoomToUserLocationTapped(_ sender: Any) {
        if let location = locationManager?.location {
            let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
            mapView.setRegion(region, animated: true)
        }
    }
    
    @IBAction func shareLocationTapped(_ sender: Any) {
//        TODO: Implement Location sharing update
    }
    
    @IBAction func alignNothTapped(_ sender: Any) {
        let camera = mapView.camera.copy() as! MKMapCamera
        camera.heading = 0
        mapView.setCamera(camera, animated: true)
    }
    
    @IBAction func emergencyTapped(_ sender: Any) {
//        TODO: Implement Emergency Feature
    }
    
    func getNavigation(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
//        CLLocationCoordinate2D(latitude:17.1964133, longitude:78.5972509)
//        CLLocationCoordinate2D(latitude: 17.40115915, longitude:78.5588766)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: source, addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination, addressDictionary: nil))
        request.requestsAlternateRoutes = true
        request.transportType = .automobile

        let directions = MKDirections(request: request)

        directions.calculate { [unowned self] response, error in
            guard let unwrappedResponse = response else { return }

            for _ in unwrappedResponse.routes {
//                self.mapView.addOverlay(route.polyline)
//                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
    }
    
}

extension ViewController: CLLocationManagerDelegate {
    /// Called after user grants or rejects location permission
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            locationManager?.startUpdatingLocation()
        } else {
//            TODO: Add prompt to show user how to give location permissions later
        }
    }
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        self.searchBar.endEditing(true)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let polyline = overlay as! MKPolyline
        let renderer = MKPolylineRenderer(polyline: polyline)
        renderer.strokeColor = Route.preferenceColors[Route.Preference(rawValue: polyline.subtitle ?? Route.Preference.last.rawValue)!]
        return renderer
    }
}

extension ViewController: UISearchBarDelegate {
    
    /// Called when user types into Search Bar
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
//        Update search results
    }
    
    /// Called when user hits search button
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchBar.text
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            guard let response = response else {
                print(error?.localizedDescription ?? "Unknown Error")
//                TODO: show error message to user
                return
            }
            
            print("\(Date()) \(URL(fileURLWithPath: #file).deletingPathExtension().lastPathComponent).\(#function) . \(response.mapItems.count)")
            let destination = response.mapItems[0]
            
            let directionsRequest = MKDirections.Request()
            directionsRequest.source = MKMapItem(placemark: MKPlacemark(coordinate: self.mapView.userLocation.coordinate))
            directionsRequest.destination = destination
            directionsRequest.requestsAlternateRoutes = true
            directionsRequest.transportType = .automobile
            
            self.mapView.removeOverlays(self.mapView.overlays)
            
            let directions = MKDirections(request: directionsRequest)
            directions.calculate { [unowned self] response, error in
                guard let routes = response?.routes else { return }

                for i in stride(from: routes.count-1, to: -1, by: -1) {
                    let route = routes[i]
                    let polyline = route.polyline
                    polyline.subtitle = ((i == 0) ? Route.Preference.first :
                        (i == 1) ? Route.Preference.second : Route.Preference.last).rawValue
                    
                    if i == 0 {
                        let formatter = DateComponentsFormatter()
                        formatter.allowedUnits = [.day, .hour, .minute, .second]
                        formatter.unitsStyle = .short
                        let str = formatter.string(from: route.expectedTravelTime)!
                        print("\(Date()) \(URL(fileURLWithPath: #file).deletingPathExtension().lastPathComponent).\(#function) >\(str)")
                    }
                    
                        
                    self.mapView.addOverlay(polyline)
                    self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                }
            }
        }
    }
    
}

extension UISearchBar {
    var textField: UITextField? { return value(forKey: "searchField") as? UITextField }
}
