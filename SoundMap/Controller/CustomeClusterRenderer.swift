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
    private let minClusterSize: Int = 5
    private let maxVisibleMarkers: Int = 30  // Limit total visible markers
    private let clusteringDistanceMultiplier: Double = 1.5
    weak var delegate: GMUClusterRendererDelegate?
    
    init(mapView: GMSMapView) {
        self.mapView = mapView
    }
    
    func renderClusters(_ clusters: [GMUCluster]) {
        clearMarkers()
        
        guard let mapView = mapView else { return }
        
        // Get visible bounds
        let visibleRegion = mapView.projection.visibleRegion()
        let bounds = GMSCoordinateBounds(coordinate: visibleRegion.farLeft, coordinate: visibleRegion.nearRight)
        
        // Sort clusters by size (larger clusters first) and filter to visible region
        let visibleClusters = clusters
            .filter { bounds.contains($0.position) }
            .sorted { $0.count > $1.count }
        
        var totalMarkersShown = 0
        var processedClusters: [GMSMarker] = []
        
        for cluster in visibleClusters {
            // Stop if we've hit our marker limit
            if totalMarkersShown >= maxVisibleMarkers {
                // Force clustering for remaining items
                let remainingMarker = createClusterMarker(for: cluster)
                if let marker = remainingMarker {
                    processedClusters.append(marker)
                }
                continue
            }
            
            let position = cluster.position
            let zoomLevel = Double(mapView.camera.zoom)
            
            // Determine if we should cluster based on zoom level and count
            if shouldCluster(cluster: cluster, zoomLevel: zoomLevel) {
                if let marker = createClusterMarker(for: cluster) {
                    processedClusters.append(marker)
                    totalMarkersShown += 1
                }
            } else {
                // Calculate how many individual markers we can still show
                let remainingSlots = maxVisibleMarkers - totalMarkersShown
                let markersToShow = min(cluster.items.count, remainingSlots)
                
                // Show individual markers
                for i in 0..<markersToShow {
                    if let item = cluster.items[i] as? GMSMarker {
                        let marker = GMSMarker(position: item.position)
                        marker.title = item.title
                        marker.snippet = item.snippet
                        marker.icon = item.icon
                        marker.groundAnchor = item.groundAnchor
                        marker.userData = item.userData
                        marker.map = mapView
                        processedClusters.append(marker)
                    }
                }
                
                totalMarkersShown += markersToShow
                
                // If we couldn't show all markers in this cluster, create a cluster for the remaining ones
                if markersToShow < cluster.items.count {
                    let remainingCount = cluster.items.count - markersToShow
                    let marker = GMSMarker(position: position)
                    marker.icon = imageWithText(text: "\(remainingCount)", color: .systemBlue)
                    marker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
                    marker.map = mapView
                    processedClusters.append(marker)
                }
            }
        }
        
        markers = processedClusters
    }
    
    private func shouldCluster(cluster: GMUCluster, zoomLevel: Double) -> Bool {
        // Base clustering on zoom level and cluster size
        if cluster.count >= minClusterSize {
            switch zoomLevel {
            case ...12: // Zoomed way out
                return true
            case 13...15: // Mid zoom
                return cluster.count > 3
            case 16...17: // Closer zoom
                return cluster.count > 8
            default: // Very close zoom
                return cluster.count > 15
            }
        }
        return false
    }
    
    private func createClusterMarker(for cluster: GMUCluster) -> GMSMarker? {
        let marker = GMSMarker(position: cluster.position)
        marker.icon = imageWithText(text: "\(cluster.count)", color: .systemBlue)
        marker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
        marker.map = mapView
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
