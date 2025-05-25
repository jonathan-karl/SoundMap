//
//  CustomeClusterRenderer.swift
//  Pods
//
//  Created by Jonathan on 30/08/2024.
//

import UIKit
import GoogleMaps
import GoogleMapsUtils

class CustomClusterRenderer: NSObject, GMUClusterRenderer {
    private weak var mapView: GMSMapView?
    private var markers: [GMSMarker] = []
    private let minClusterSize: Int = 3
    private let maxVisibleMarkers: Int = 60  // Limit total visible markers
    private let clusteringDistanceMultiplier: Double = 1.5
    weak var delegate: GMUClusterRendererDelegate?
    
    init(mapView: GMSMapView) {
        self.mapView = mapView
    }
    
    func renderClusters(_ clusters: [GMUCluster]) {
        clearMarkers()
        
        guard let mapView = mapView else { return }
        
        let visibleRegion = mapView.projection.visibleRegion()
        let bounds = GMSCoordinateBounds(coordinate: visibleRegion.farLeft, coordinate: visibleRegion.nearRight)
        
        // Filter only visible clusters
        let visibleClusters = clusters
            .filter { bounds.contains($0.position) }
            .sorted { $0.count > $1.count } // Largest clusters first
        
        guard !visibleClusters.isEmpty else {
            print("🟡 No clusters to render in current view.")
            return
        }
        
        var markersShown = 0
        
        for cluster in visibleClusters {
            guard markersShown < maxVisibleMarkers else {
                // If limit reached, show as one collapsed cluster marker (correct count)
                if let marker = createClusterMarker(for: cluster, countOverride: Int(cluster.count)) {
                    marker.map = mapView
                    markers.append(marker)
                }
                continue
            }
            
            let zoomLevel = Double(mapView.camera.zoom)
            
            if shouldCluster(cluster: cluster, zoomLevel: zoomLevel) {
                // Render as a cluster
                if let marker = createClusterMarker(for: cluster, countOverride: Int(cluster.count)) {
                    marker.map = mapView
                    markers.append(marker)
                    markersShown += 1
                }
            } else {
                // Render individual items
                let availableSlots = maxVisibleMarkers - markersShown
                let items = Array(cluster.items.prefix(availableSlots))
                
                for item in items {
                    if let gmsMarker = item as? GMSMarker {
                        let marker = GMSMarker(position: gmsMarker.position)
                        marker.title = gmsMarker.title
                        marker.snippet = gmsMarker.snippet
                        marker.icon = gmsMarker.icon
                        marker.userData = gmsMarker.userData
                        marker.groundAnchor = gmsMarker.groundAnchor
                        marker.map = mapView
                        markers.append(marker)
                        markersShown += 1
                    }
                }
                
                // If there were remaining items, add a proper cluster marker to represent the rest
                let remainingCount = Int(cluster.count) - items.count
                if remainingCount > 0 {
                    if let marker = createClusterMarker(for: cluster, countOverride: remainingCount) {
                        marker.map = mapView
                        markers.append(marker)
                        markersShown += 1
                    }
                }
            }
        }
    }
    
    
    private func shouldCluster(cluster: GMUCluster, zoomLevel: Double) -> Bool {
        // Base clustering on zoom level and cluster size
        if cluster.count >= minClusterSize {
            switch zoomLevel {
            case ...12:
                return cluster.count > 10
            case 13...15:
                return cluster.count > 6
            case 16...17:
                return cluster.count > 12
            default:
                return cluster.count > 20
            }
        }
        return false
    }
    
    private func createClusterMarker(for cluster: GMUCluster, countOverride: Int) -> GMSMarker? {
        let marker = GMSMarker(position: cluster.position)
        marker.icon = imageWithText(text: "\(countOverride)", color: .systemBlue)
        marker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
        return marker
    }
    
    
    private func imageWithText(text: String, color: UIColor) -> UIImage {
        let size = CGSize(width: 40, height: 40)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Draw circle
            color.setFill()
            context.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
            
            // Draw text
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 14),
                .foregroundColor: UIColor.white
            ]
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            text.draw(in: textRect, withAttributes: attributes)
        }
    }
    
    func update() {
        // Optional: Implement if needed
    }
    
    private func clearMarkers() {
        markers.forEach { $0.map = nil }
        markers.removeAll()
    }
}
