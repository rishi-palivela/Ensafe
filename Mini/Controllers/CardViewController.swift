//
//  CardViewController.swift
//  Mini
//
//  Created by Sai Hemanth Bheemreddy on 22/06/20.
//  Copyright © 2020 StarDust. All rights reserved.
//

import UIKit
import MapKit

protocol CardViewControllerDelegate {
    func expandCard()
    func collapseCard()
    func show(placemark: MKPlacemark)
    func getTime(to destination: MKMapItem, withCompletion completionHandler: @escaping ((_ time: TimeInterval, _ distance: CLLocationDistance) -> Void))
    func navigate(to placemark: MKMapItem)
}

class CardViewController: UIViewController {
    
    enum Mode {
        case search
        case showPlacemark
        case directions
    }

    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    @IBOutlet weak var handleArea: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchBarHeight: NSLayoutConstraint!
    
    @IBOutlet weak var getDirections: UIButton!
    @IBOutlet weak var cancelDirections: UIButton!
    @IBOutlet weak var directionButtonView: UIStackView!
    @IBOutlet weak var directionButtonViewHeight: NSLayoutConstraint!
    
    var canCollapse = true
    var delegate: CardViewControllerDelegate?
    
    private var localSearch: MKLocalSearch?
    private var searchResults = [MKMapItem]()
    private var selectedIndex: Int!
    private var mode: Mode = .search
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let blurEffect: UIBlurEffect!
        if #available(iOS 13.0, *) {
            blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        } else {
            blurEffect = UIBlurEffect(style: .light)
        }
        visualEffectView.effect = blurEffect

        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        getDirections.layer.cornerRadius = 12
        getDirections.clipsToBounds = true
        getDirections.titleLabel?.lineBreakMode = .byWordWrapping
        getDirections.titleLabel?.numberOfLines = 0
        getDirections.titleLabel?.textAlignment = .center
        
        hideGetDirectionsView()
    }
    
    func prepareToExpand() {
        if(searchBar.isHidden) {
            showSearchBar()
            hideGetDirectionsView()
        }
    }
    
    func prepareToCollapse() {
        if(mode != .search) {
            hideSearchBar()
            showGetDirectionsView()
        }
        
        searchBarCancelButtonClicked(searchBar)
    }
    
    func showSearchBar() {
        searchBar.isHidden = false
        searchBarHeight.constant = 56
    }
    
    func hideSearchBar() {
        searchBar.isHidden = true
        searchBarHeight.constant = 0
    }
    
    func showGetDirectionsView() {
        directionButtonView.isHidden = false
        directionButtonViewHeight.constant = 72
    }
    
    func hideGetDirectionsView() {
        directionButtonView.isHidden = true
        directionButtonViewHeight.constant = 0
    }
    
    func prepareForNavigation(to destination: MKMapItem) {
        mode = .showPlacemark
        hideSearchBar()
        showGetDirectionsView()
        
        print("\(Date()) \(URL(fileURLWithPath: #file).deletingPathExtension().lastPathComponent).\(#function)")
        
        delegate?.getTime(to: destination) { time, distance in
            print("\(Date()) \(URL(fileURLWithPath: #file).deletingPathExtension().lastPathComponent).\(#function)")
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.day, .hour, .minute, .second]
            formatter.unitsStyle = .short
            
            let attrString = NSMutableAttributedString(string: "Get Directions\n",
                                                       attributes: [ NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .headline) ])

            attrString.append(NSMutableAttributedString(string: formatter.string(from: time)!,
                                                        attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .subheadline)]))
            
            DispatchQueue.main.async {
                self.getDirections.setAttributedTitle(attrString, for: .normal)
                print("\(Date()) \(URL(fileURLWithPath: #file).deletingPathExtension().lastPathComponent).\(#function)")
            }
        }
    }
    
    @IBAction func getDirectionTapped(_ sender: UIButton) {
        delegate?.navigate(to: searchResults[selectedIndex])
    }

}

extension CardViewController: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        canCollapse = false
        delegate?.expandCard()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        canCollapse = true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        
        delegate?.collapseCard()
    }
    
    /// Called when user types into Search Bar
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        localSearch?.cancel()
        
        if(searchText.isEmpty ?? false) {
            searchResults.removeAll()
            tableView.reloadData()
        }
        
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchText
        
        localSearch = MKLocalSearch(request: searchRequest)
        localSearch!.start { response, error in
            guard let mapItems = response?.mapItems else {
                print(error?.localizedDescription ?? "Unknown Error")
//                TODO: show error message to user
                return
            }
            
            self.searchResults = mapItems
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
}

extension CardViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Search Result Cell")
        let placemark = searchResults[indexPath].placemark
        
        let addressComponents = [placemark.subLocality, placemark.locality, placemark.subAdministrativeArea,
                                 placemark.administrativeArea, placemark.postalCode]
        let addressComponentsUnwrapped  = addressComponents.filter { $0 != nil }.map { $0! }
        
        cell.textLabel?.text = placemark.name
        cell.detailTextLabel?.text = addressComponentsUnwrapped.joined(separator: ", ")
        
        cell.backgroundColor = nil
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        searchBar.resignFirstResponder()
        
        selectedIndex = indexPath.row
        prepareForNavigation(to: searchResults[indexPath])
        
        delegate?.collapseCard()
        delegate?.show(placemark: searchResults[indexPath].placemark)
    }
    
}
