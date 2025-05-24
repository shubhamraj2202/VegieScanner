//
//  CoreDataManager.swift
//  VegieScanner
//
//  Created by Shubham Raj on 23/05/25.
//

import Foundation
import CoreData
import UIKit

class CoreDataManager {
    static let shared = CoreDataManager()
    private let container: NSPersistentContainer

    private init() {
        container = NSPersistentContainer(name: "ScanDataModel")
        container.loadPersistentStores { _, error in
            if let error = error {
                print("CoreData load error: \(error)")
            }
        }
    }

    func saveScan(_ scan: ScanResult) {
        let context = container.viewContext
        let entity = ScanEntity(context: context)
        entity.id = scan.id
        entity.isVegan = scan.status.rawValue
        entity.confidence = Int16(scan.confidence)
        entity.explanation = scan.explanation
        entity.imageData = scan.imageData
        entity.timestamp = Date()
        try? context.save()
    }

    func loadRecentScans(limit: Int = 10) -> [ScanResult] {
        let context = container.viewContext
        let request: NSFetchRequest<ScanEntity> = ScanEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ScanEntity.timestamp, ascending: false)]
        request.fetchLimit = limit

        do {
            return try context.fetch(request).map {
                ScanResult(
                    id: $0.id ?? UUID(),
                    status: VeganStatus(rawValue: $0.isVegan) ?? .uncertain,
                    confidence: Int($0.confidence),
                    explanation: $0.explanation ?? "",
                    imageData: $0.imageData ?? Data()
                )
            }
        } catch {
            return []
        }
    }

    func deleteAllScans() {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = ScanEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            print("Failed to delete all scans: \(error)")
        }
    }
}
