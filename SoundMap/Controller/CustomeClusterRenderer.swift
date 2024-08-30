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
    weak var delegate: GMUClusterRendererDelegate?
    
    init(mapView: GMSMapView) {
        self.mapView = mapView
    }
    
    func renderClusters(_ clusters: [GMUCluster]) {
            clearMarkers()
            markers = clusters.map { cluster in
                let position = cluster.position
                let marker = GMSMarker(position: position)
                if cluster.count > 1 {
                    // Customize cluster marker appearance
                    marker.icon = self.imageWithText(text: "\(cluster.count)", color: UIColor.blue)
                    marker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
                } else if let item = cluster.items.first as? GMSMarker {
                    // Single marker, use the original marker's properties
                    marker.title = item.title
                    marker.snippet = item.snippet
                    marker.icon = item.icon
                    marker.userData = item.userData
                }
                marker.map = mapView
                return marker
            }
        }
    
    func update() {
        // Not needed for this implementation
    }
    
    private func clearMarkers() {
            markers.forEach { $0.map = nil }
            markers.removeAll()
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
                let textRect = CGRect(x: (size.width - textSize.width) / 2,
                                      y: (size.height - textSize.height) / 2,
                                      width: textSize.width,
                                      height: textSize.height)
                text.draw(in: textRect, withAttributes: attributes)
            }
        }
    
}
