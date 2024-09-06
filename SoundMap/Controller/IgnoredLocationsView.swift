//
//  IgnoredLocationsView.swift
//  SoundMap
//
//  Created by Jonathan on 06/09/2024.
//

import SwiftUI
import CoreLocation

struct IgnoredLocationsView: View {
    @State private var ignoredLocations: [IgnoredLocation] = []
    @State private var newLocationName: String = ""
    @State private var showingAddAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        List {
            Section(header: Text("Ignored Locations")) {
                ForEach(ignoredLocations, id: \.id) { location in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(location.name)
                                .font(.headline)
                            Text("Lat: \(location.coordinate.latitude), Lon: \(location.coordinate.longitude)")
                                .font(.caption)
                        }
                        Spacer()
                        Button(action: {
                            removeLocation(location)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            
            Section {
                Button(action: {
                    requestLocation()
                }) {
                    Label("Add Current Location", systemImage: "plus")
                }
            }
        }
        .onAppear(perform: loadLocations)
        .alert("Add Ignored Location", isPresented: $showingAddAlert) {
            TextField("Location Name", text: $newLocationName)
            Button("Add", action: addCurrentLocation)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter a name for this location")
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func loadLocations() {
        ignoredLocations = LocationNotificationManager.shared.getIgnoredLocations()
    }
    
    private func removeLocation(_ location: IgnoredLocation) {
        LocationNotificationManager.shared.removeIgnoredLocation(withId: location.id)
        loadLocations()
    }
    
    private func requestLocation() {
        LocationNotificationManager.shared.requestOneTimeLocation { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let location):
                    showingAddAlert = true
                case .failure(let error):
                    errorMessage = "Failed to get location: \(error.localizedDescription)"
                    showingErrorAlert = true
                }
            }
        }
    }
    
    private func addCurrentLocation() {
        LocationNotificationManager.shared.requestOneTimeLocation { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let location):
                    LocationNotificationManager.shared.addIgnoredLocation(name: newLocationName, coordinate: location.coordinate)
                    newLocationName = ""
                    loadLocations()
                case .failure(let error):
                    errorMessage = "Failed to add location: \(error.localizedDescription)"
                    showingErrorAlert = true
                }
            }
        }
    }
}
