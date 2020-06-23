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
    func navigate(to placemark: MKMapItem, withCompletion completionHandler: @escaping ((_ routes: [MKRoute]) -> Void))
}

class CardViewController: UIViewController {
    
    enum Mode {
        case search
        case showPlacemark
        case routes
        case directions
    }

    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    @IBOutlet weak var handleArea: UIView!
    @IBOutlet weak var handleAreaHeight: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchBarHeight: NSLayoutConstraint!
    
    @IBOutlet weak var directionsTitle: UILabel!
    @IBOutlet weak var directionsSubtitle: UILabel!
    @IBOutlet weak var titleView: UIStackView!
    @IBOutlet weak var titleViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var getDirections: UIButton!
    @IBOutlet weak var cancelDirections: UIButton!
    @IBOutlet weak var directionButtonView: UIStackView!
    @IBOutlet weak var directionButtonViewHeight: NSLayoutConstraint!
    
    var canCollapse = true
    var delegate: CardViewControllerDelegate?
    var cardVisible = false
    var cardHandleAreaHeight: CGFloat {
        var const: CGFloat = 100
        
        switch mode {
        case .directions:
            const += 100
        case .routes:
            const += 150
        default:
            break
        }
        
        var val = const + handleAreaHeight.constant + searchBarHeight.constant
        val += titleViewHeight.constant + directionButtonViewHeight.constant
        return val
    }
    
    private var localSearch: MKLocalSearch?
    private var searchResults = [MKMapItem]()
    private var routes = [MKRoute]()
    private var selectedDestination: MKMapItem!
    private var selectedRoute: MKRoute!
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
        hideGetTitleView()
        
        self.tableView.estimatedRowHeight = 80
        self.tableView.rowHeight = UITableView.automaticDimension
        tableView.register(RouteCell.self, forCellReuseIdentifier: "RouteCell")
    }
    
    func prepareToExpand() {
        if(mode != .directions) {
            showSearchBar()
            hideGetDirectionsView()
            
            if(mode != .routes) {
                hideGetTitleView()
            }
        }
    }
    
    func prepareToCollapse() {
        switch mode {
//        case .search:
//            hideSearchBar()
        case .showPlacemark:
            showGetTitleView()
            showGetDirectionsView()
        case .routes:
            showGetTitleView()
        case .directions:
            hideSearchBar()
            showGetTitleView()
        default:
            break
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
    
    func showGetTitleView() {
        titleView.isHidden = false
        titleViewHeight.constant = 56
    }
    
    func hideGetTitleView() {
        titleView.isHidden = true
        titleViewHeight.constant = 0
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
        showGetTitleView()
        showGetDirectionsView()
        
        directionsTitle.text = "To \(destination.placemark.name ?? "")"
        directionsSubtitle.text = destination.placemark.areasOfInterest?.first
        
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
                self.directionsSubtitle.text = "\(destination.placemark.areasOfInterest?.first ?? "")\t"
                    + "\(MKDistanceFormatter().string(fromDistance: distance)) away"
                print("\(Date()) \(URL(fileURLWithPath: #file).deletingPathExtension().lastPathComponent).\(#function)")
            }
        }
    }
    
    @IBAction func getDirectionTapped(_ sender: UIButton) {
        mode = .routes
        hideGetDirectionsView()
        directionsTitle.text = "To \(selectedDestination.placemark.name ?? "")"
        directionsSubtitle.text = "From My Location"
        
        cardVisible = true
        delegate?.collapseCard()
        
        delegate?.navigate(to: selectedDestination) { routes in
            self.routes = routes
            self.tableView.reloadData()
        }
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
        mode = .search
        hideGetTitleView()
        hideGetDirectionsView()
        
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
        switch mode {
        case .routes:
            return routes.count
        case .directions:
            return selectedRoute.steps.count
        default:
            return searchResults.count
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return (mode == .routes || mode == .directions) ? UITableView.automaticDimension : 44
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch mode {
        case .routes:
            let cell = tableView.dequeueReusableCell(withIdentifier: "RouteCell", for: indexPath) as! RouteCell
            let route = routes[indexPath]
            
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.day, .hour, .minute, .second]
            formatter.unitsStyle = .short
            
            cell.time.text = "Route \(indexPath.row + 1)"
            cell.distance.text = "\(formatter.string(from: route.expectedTravelTime) ?? ""), \(MKDistanceFormatter().string(fromDistance: route.distance)) away"
            return cell
        
        case .directions:
            let cell = UITableViewCell(style: .value1, reuseIdentifier: "Direction Cell")
            if indexPath.row == 0 {
                cell.textLabel?.text = "Your Location"
            } else {
                cell.textLabel?.text = "\(selectedRoute.steps[indexPath.row].instructions)"
            }
            cell.detailTextLabel?.text = "In \(MKDistanceFormatter().string(fromDistance: selectedRoute.steps[indexPath.row].distance))"
            if #available(iOS 13.0, *) {
                cell.detailTextLabel?.tintColor = .label
            } else {
                cell.detailTextLabel?.tintColor = .black
            }
            
            cell.textLabel?.lineBreakMode = .byWordWrapping
            cell.textLabel?.numberOfLines = 0
            cell.backgroundColor = nil
            return cell
            
        default:
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
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        searchBar.resignFirstResponder()
        
        switch mode {
        case .routes:
            selectedRoute = routes[indexPath.row]
            mode = .directions
            delegate?.expandCard()
            tableView.reloadData()
        
        case .directions:
            break
            
        default:
            selectedDestination = searchResults[indexPath]
            prepareForNavigation(to: selectedDestination)
            
            delegate?.collapseCard()
            delegate?.show(placemark: searchResults[indexPath].placemark)
        }
        
    }
    
}

class RouteCell: UITableViewCell {
    
    let time = UILabel()
    let distance = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .clear
        accessoryType = .disclosureIndicator
        
        time.font = UIFont.preferredFont(forTextStyle: .headline)
        
        contentView.addSubview(time)
        time.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            time.textColor = .label
        } else {
            time.textColor = .black
        }
        
        distance.font = UIFont.preferredFont(forTextStyle: .subheadline)
        distance.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(distance)
        if #available(iOS 13.0, *) {
            distance.textColor = .secondaryLabel
        } else {
            distance.textColor = .darkGray
        }
        
        
        NSLayoutConstraint.activate([
            time.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            time.bottomAnchor.constraint(equalTo: distance.topAnchor, constant: -8),
            time.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            time.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            distance.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            distance.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            distance.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not Implemented")
    }
    
}
