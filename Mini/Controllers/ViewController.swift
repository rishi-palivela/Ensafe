//
//  ViewController.swift
//  Mini
//
//  Created by Rishi Palivela on 16/06/20.
//  Copyright © 2020 StarDust. All rights reserved.
//

import UIKit
import MapKit
import UserNotifications
import CoreLocation
import FirebaseUI

class ViewController: UIViewController {
    
    enum CardState {
        case expanded
        case collapsed
    }
    
    var locationManager: CLLocationManager?
    var notificationCenter: UNUserNotificationCenter?
    var directions: MKDirections?
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var zoomToUserLocationButton: UIButton!
    @IBOutlet weak var shareLocationButton: UIButton!
    @IBOutlet weak var alignNorthButton: RoundButton!
    @IBOutlet weak var emergencyButton: RoundButton!
    
    var user: User?
    var authUI: FUIAuth!
    var authStateHandle: AuthStateDidChangeListenerHandle?
    
    var cardViewController: CardViewController!
    var visualEffectView: UIVisualEffectView!
    var cardHeight: CGFloat {
        view.frame.height * 0.9
    }
    var cardHandleAreaHeight: CGFloat {
        cardViewController.cardHandleAreaHeight
    }
    var cardVisible: Bool {
        get {
            cardViewController.cardVisible
        }
        set {
            cardViewController.cardVisible = newValue
        }
    }
    var nextState: CardState {
        cardVisible ? .collapsed : .expanded
    }
    
    var runningAnimations = [UIViewPropertyAnimator]()
    var animationProgressWhenInterrupted: CGFloat = 0
    
    /// Called after view is loaded into memory
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCard()
        setupNotifications()
        startLocation()
        
        mapView.delegate = self
        mapView.showsCompass = false
        zoomToUserLocationTapped(self)
        
        zoomToUserLocationButton.backgroundColor = .mapButtonBackground
        alignNorthButton.backgroundColor = .mapButtonBackground
        
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
    
    func setupNotifications() {
        notificationCenter = UNUserNotificationCenter.current()
        notificationCenter?.delegate = self
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        notificationCenter!.requestAuthorization(options: options) {
            (didAllow, error) in
            if !didAllow {
                print("User has declined notifications")
            }
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
    
    @IBAction func alignNorthTapped(_ sender: Any) {
        let camera = mapView.camera.copy() as! MKMapCamera
        camera.heading = 0
        mapView.setCamera(camera, animated: true)
    }
    
    @IBAction func emergencyTapped(_ sender: Any) {
//        TODO: Implement Emergency Feature
        guard let notificationCenter = notificationCenter else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Emergency"
        content.body = "Near CVR College of Engineering.\nSeverity Level: 5"
        content.sound = .default
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let identifier = "Emergency Notifications"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        notificationCenter.add(request) { (error) in
            if let error = error {
                print("Error \(error.localizedDescription)")
            }
        }
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

extension ViewController: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        completionHandler([.alert, .badge, .sound])
    }
}

extension ViewController {
    
    func setupCard() {
        visualEffectView = UIVisualEffectView()
        visualEffectView.frame = self.view.frame
        visualEffectView.isUserInteractionEnabled = false
        self.view.addSubview(visualEffectView)
        
        cardViewController = CardViewController(nibName: "CardViewController", bundle: nil)
        cardViewController.delegate = self
        addChild(cardViewController)
        view.addSubview(cardViewController.view)
        
        cardViewController.view.frame = CGRect(x: 0, y: view.frame.height - cardHandleAreaHeight,
                                               width: view.bounds.width, height: cardHeight)
        
        cardViewController.view.clipsToBounds = true
        
        cardViewController.handleArea.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleCardTap(recognzier:))))
        cardViewController.handleArea.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handleCardPan(recognzier:))))
    }
    
    @objc func handleCardTap(recognzier: UITapGestureRecognizer) {
        if(cardVisible) {
            cardViewController.prepareToCollapse()
        } else {
            cardViewController.prepareToExpand()
        }
        
        switch recognzier.state {
        case .ended:
            animateTransitionIfNeeded(state: nextState, duration: 0.9)
        default:
            break
        }
    }
    
    @objc func handleCardPan(recognzier: UIPanGestureRecognizer) {
        if(cardVisible) {
            cardViewController.prepareToCollapse()
        } else {
            cardViewController.prepareToExpand()
        }
        
        switch recognzier.state {
        case .began:
            startInteractiveTransition(state: nextState, duration: 0.9)
            
        case .changed:
            let translation = recognzier.translation(in: self.cardViewController.handleArea)
            var fractionComplete = translation.y / cardHeight
            fractionComplete = cardVisible ? fractionComplete : -fractionComplete
            updateInteractiveTransition(fractionCompleted: fractionComplete)
            
        case .ended:
            continueInteractiveTransition()
            
        default:
            break
        }
    }
    
    func animateTransitionIfNeeded(state: CardState, duration: TimeInterval) {
        if runningAnimations.isEmpty {
            let frameAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .expanded:
                    self.cardViewController.view.frame.origin.y = self.view.frame.height - self.cardHeight
                case .collapsed:
                    self.cardViewController.view.frame.origin.y = self.view.frame.height - self.cardHandleAreaHeight
                }
            }
            
            frameAnimator.addCompletion { _ in
                self.cardVisible.toggle()
                self.runningAnimations.removeAll()
            }
            
            frameAnimator.startAnimation()
            runningAnimations.append(frameAnimator)
            
            let cornerRadiusAnimator = UIViewPropertyAnimator(duration: duration, curve: .linear) {
                switch state {
                case .expanded:
                    self.cardViewController.view.layer.cornerRadius = 12
                case .collapsed:
                    self.cardViewController.view.layer.cornerRadius = 0
                }
            }
            
            cornerRadiusAnimator.startAnimation()
            runningAnimations.append(cornerRadiusAnimator)
            
            let blurAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .expanded:
                    self.visualEffectView.effect = UIBlurEffect(style: .dark)
                case .collapsed:
                    self.visualEffectView.effect = nil
                }
            }
            
            blurAnimator.startAnimation()
            runningAnimations.append(blurAnimator)
        }
    }
    
    func startInteractiveTransition(state: CardState, duration: TimeInterval) {
        if runningAnimations.isEmpty {
            animateTransitionIfNeeded(state: state, duration: duration)
        }
        
        for animator in runningAnimations {
            animator.pauseAnimation()
            animationProgressWhenInterrupted = animator.fractionComplete
        }
    }
    
    func updateInteractiveTransition(fractionCompleted: CGFloat) {
        for animator in runningAnimations {
            animator.fractionComplete = fractionCompleted + animationProgressWhenInterrupted
        }
    }
    
    func continueInteractiveTransition() {
        for animator in runningAnimations {
            animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
        }
    }
    
}

extension ViewController: CardViewControllerDelegate {
    
    func expandCard() {
        if(!cardVisible) {
            animateTransitionIfNeeded(state: nextState, duration: 0.9)
        }
    }
    
    func collapseCard() {
        if(cardVisible) {
            animateTransitionIfNeeded(state: nextState, duration: 0.9)
        }
    }
    
    func show(placemark: MKPlacemark) {
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotation(placemark)
        
        mapView.setRegion(MKCoordinateRegion(center: placemark.coordinate,
                                             latitudinalMeters: 500, longitudinalMeters: 500), animated: true)
    }
    
    func getTime(to destination: MKMapItem,
                withCompletion completionHandler: @escaping ((_ time: TimeInterval, _ distance: CLLocationDistance) -> Void)) {
        directions?.cancel()
        
        let directionsRequest = MKDirections.Request()
        directionsRequest.source = MKMapItem(placemark: MKPlacemark(coordinate: self.mapView.userLocation.coordinate))
        directionsRequest.destination =  destination
        directionsRequest.requestsAlternateRoutes = false
        directionsRequest.transportType = .automobile
        
        directions = MKDirections(request: directionsRequest)
        directions?.calculateETA { response, error in
            guard let response = response else {
                print(error?.localizedDescription ?? "Unknown Error")
                return
            }
            
            completionHandler(response.expectedTravelTime, response.distance)
        }
        
    }
    
    func navigate(to destination: MKMapItem, withCompletion completionHandler: @escaping ((_ routes: [MKRoute]) -> Void)) {
        directions?.cancel()

        let directionsRequest = MKDirections.Request()
        directionsRequest.source = MKMapItem(placemark: MKPlacemark(coordinate: self.mapView.userLocation.coordinate))
        directionsRequest.destination =  destination
        directionsRequest.requestsAlternateRoutes = true
        directionsRequest.transportType = .automobile
        
        directions = MKDirections(request: directionsRequest)
        directions?.calculate { response, error in
            guard let routes = response?.routes else {
                print(error?.localizedDescription ?? "Unknown Error")
                return
            }
            
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
                
                completionHandler(routes)
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
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let polyline = overlay as! MKPolyline
        let renderer = MKPolylineRenderer(polyline: polyline)
        renderer.strokeColor = Route.preferenceColors[Route.Preference(rawValue: polyline.subtitle ?? Route.Preference.last.rawValue)!]
        return renderer
    }
}

extension UISearchBar {
    var textField: UITextField? { return value(forKey: "searchField") as? UITextField }
}
