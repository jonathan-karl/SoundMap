//
//  DetailedViewController.swift
//  Noise
//
//  Created by Jonathan on 24/02/2024.
//

import UIKit
import Charts

class DetailedViewController: UIViewController {
    
    @IBOutlet weak var placeNameLabel: UILabel!
    @IBOutlet weak var noiseDetectedBarChart: BarChartView!
    @IBOutlet weak var conversationDifficultyBarChart: BarChartView!
    
    var conversationDifficultyElements: [String] = []
    var conversationDifficultyFrequencies: [Int] = []
    var noiseSourcesElements: [String] = []
    var noiseSourcesFrequencies: [Int] = []
    var placeName: String?
    var placeAddress: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        placeNameLabel.text = placeName
  
        // Setup noiseDetectedBarChart
        setupBarChart(
            barChartView: conversationDifficultyBarChart,
            elements: Array(conversationDifficultyElements),
            frequencies: Array(conversationDifficultyFrequencies),
            label: "Conversation Difficulty"
        )
        
        // Setup conversationDifficultyBarChart
        setupBarChart(
            barChartView: noiseDetectedBarChart,
            elements: Array(noiseSourcesElements),
            frequencies: Array(noiseSourcesFrequencies),
            label: "Noise Sources"
        )
    }
    
    private func setupBarChart(barChartView: BarChartView, elements: [String], frequencies: [Int], label: String) {
        // Combine elements and frequencies, then sort by frequencies in descending order
        let combined = zip(elements, frequencies).sorted(by: { $0.1 > $1.1 })
        // Take the top 4 elements
        let topFour = combined.prefix(4)
        
        var dataEntries: [BarChartDataEntry] = []
        var barColors: [UIColor] = []
        
        for (index, (element, frequency)) in topFour.enumerated() {
            let dataEntry = BarChartDataEntry(x: Double(index), y: Double(frequency))
            dataEntries.append(dataEntry)
            
            // Assign colors based on the element label
            switch element {
            case "Comfortable":
                barColors.append(UIColor(red: 67/255.0, green: 190/255.0, blue: 90/255.0, alpha: 1))
            case "Manageable":
                barColors.append(UIColor(red: 232/255.0, green: 185/255.0, blue: 5/255.0, alpha: 1))
            case "Challenging":
                barColors.append(UIColor(red: 236/255.0, green: 55/255.0, blue: 45/255.0, alpha: 1))
            default:
                barColors.append(UIColor.blue) // Default color for any other labels
            }
        }
        
        let dataSet = BarChartDataSet(entries: dataEntries, label: label)
        dataSet.colors = barColors
        dataSet.valueTextColor = UIColor.black
        dataSet.valueFont = .systemFont(ofSize: 12)
        
        let valueFormatter = NumberFormatter()
        valueFormatter.numberStyle = .none
        let chartFormatter = DefaultValueFormatter(formatter: valueFormatter)
        
        let data = BarChartData(dataSets: [dataSet])
        data.setValueFormatter(chartFormatter) // Here we set the formatter to the BarChartData
        barChartView.data = data
        
        // Extract just the element names for the xAxis labels
        let topElements = topFour.map { $0.0 }
        customizeChartAppearance(barChartView: barChartView, elements: topElements)
    }

    
    private func customizeChartAppearance(barChartView: BarChartView, elements: [String]) {
        barChartView.extraBottomOffset = 100 // Adjust the value as needed
        barChartView.scaleXEnabled = false
        barChartView.scaleYEnabled = false
        barChartView.pinchZoomEnabled = false
        barChartView.doubleTapToZoomEnabled = false
        
        barChartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: elements)
        barChartView.xAxis.setLabelCount(elements.count, force: false) // Try without force first
        //barChartView.xAxis.granularity = 1
        barChartView.xAxis.labelPosition = .bottom
        barChartView.xAxis.drawGridLinesEnabled = false
        barChartView.leftAxis.enabled = false
        barChartView.rightAxis.enabled = false
        barChartView.chartDescription.enabled = false
        barChartView.legend.enabled = false
        barChartView.xAxis.labelRotationAngle = -45 // Optional: rotate labels if necessary
        
    }
    
}

