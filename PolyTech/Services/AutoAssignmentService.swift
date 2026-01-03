//
//  AutoAssignmentService.swift
//  PolyTech
//
//  Created by BP-36-213-19 on 03/01/2026.
//


import Foundation
import FirebaseFirestore

class AutoAssignmentService {
    
    static let shared = AutoAssignmentService()
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Auto Assign Technician
    
    /// Automatically assign an available technician to a request
    func autoAssignTechnician(
        requestId: String,
        requestType: String, // "maintenance" or "inventory"
        category: String,
        location: String,
        urgency: String = "normal",
        completion: @escaping (Bool, String?) -> Void
    ) {
        print("🤖 Starting auto-assignment for request: \(requestId)")
        
        // Get available technicians
        getAvailableTechnicians { [weak self] availableTechs in
            guard let self = self else { return }
            
            if availableTechs.isEmpty {
                print("⚠️ No available technicians found")
                completion(false, "No available technicians at this time")
                return
            }
            
            // Find best match
            let bestMatch = self.findBestTechnician(
                technicians: availableTechs,
                category: category,
                urgency: urgency
            )
            
            guard let technician = bestMatch else {
                print("⚠️ No suitable technician found")
                completion(false, "No suitable technician available")
                return
            }
            
            print("✅ Best match found: \(technician.name)")
            
            // Assign the technician
            self.assignTechnician(
                requestId: requestId,
                requestType: requestType,
                technician: technician,
                location: location,
                urgency: urgency,
                category: category,
                completion: completion
            )
        }
    }
    
    // MARK: - Get Available Technicians
    
    private func getAvailableTechnicians(completion: @escaping ([TechnicianInfo]) -> Void) {
        print("🔍 Fetching available technicians...")
        
        db.collection("technicians")
            .whereField("availability", isEqualTo: "available")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching technicians: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                let now = Date()
                let calendar = Calendar.current
                let currentHour = calendar.component(.hour, from: now)
                let currentMinute = calendar.component(.minute, from: now)
                let currentTime = currentHour * 60 + currentMinute // Convert to minutes
                
                let technicians = snapshot?.documents.compactMap { doc -> TechnicianInfo? in
                    let data = doc.data()
                    
                    guard let name = data["name"] as? String else { return nil }
                    
                    // Parse working hours (format: "6:00 - 12:00")
                    guard let hours = data["hours"] as? String,
                          let timeRange = self.parseWorkingHours(hours) else {
                        print("⚠️ Invalid hours format for \(name): \(data["hours"] ?? "nil")")
                        return nil
                    }
                    
                    // Check if technician is currently working
                    let isWorking = currentTime >= timeRange.start && currentTime <= timeRange.end
                    
                    if !isWorking {
                        print("⏰ \(name) is not working now (Current: \(currentHour):\(currentMinute), Hours: \(hours))")
                        return nil
                    }
                    
                    print("✅ \(name) is available (Hours: \(hours))")
                    
                    return TechnicianInfo(
                        id: doc.documentID,
                        name: name,
                        hours: hours,
                        availability: data["availability"] as? String ?? "available",
                        solvedTasks: data["solvedTasks"] as? Int ?? 0,
                        tasks: data["tasks"] as? Int ?? 0
                    )
                } ?? []
                
                print("📊 Found \(technicians.count) available technicians")
                completion(technicians)
            }
    }
    
    // MARK: - Parse Working Hours
    
    private func parseWorkingHours(_ hoursString: String) -> (start: Int, end: Int)? {
        // Format: "6:00 - 12:00" or "6:00-12:00"
        let components = hoursString.components(separatedBy: "-").map { $0.trimmingCharacters(in: .whitespaces) }
        
        guard components.count == 2 else { return nil }
        
        guard let startTime = parseTime(components[0]),
              let endTime = parseTime(components[1]) else {
            return nil
        }
        
        return (start: startTime, end: endTime)
    }
    
    private func parseTime(_ timeString: String) -> Int? {
        // Format: "6:00" or "12:00"
        let components = timeString.components(separatedBy: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return nil
        }
        
        return hour * 60 + minute // Convert to minutes since midnight
    }
    
    // MARK: - Find Best Technician
    
    private func findBestTechnician(
        technicians: [TechnicianInfo],
        category: String,
        urgency: String
    ) -> TechnicianInfo? {
        
        guard !technicians.isEmpty else { return nil }
        
        // Sort by workload (fewer current tasks = better)
        let sorted = technicians.sorted { tech1, tech2 in
            // First priority: fewer current tasks
            if tech1.tasks != tech2.tasks {
                return tech1.tasks < tech2.tasks
            }
            
            // Second priority: more solved tasks (experience)
            if tech1.solvedTasks != tech2.solvedTasks {
                return tech1.solvedTasks > tech2.solvedTasks
            }
            
            // Third priority: alphabetical
            return tech1.name < tech2.name
        }
        
        let selected = sorted.first!
        print("🎯 Selected: \(selected.name) (Tasks: \(selected.tasks), Solved: \(selected.solvedTasks))")
        
        return selected
    }
    
    // MARK: - Assign Technician
    
    private func assignTechnician(
        requestId: String,
        requestType: String,
        technician: TechnicianInfo,
        location: String,
        urgency: String,
        category: String,
        completion: @escaping (Bool, String?) -> Void
    ) {
        let collection = requestType == "maintenance" ? "maintenanceRequest" : "inventoryRequest"
        
        let updates: [String: Any] = [
            "assignedTechnicianId": technician.id,
            "assignedTechnicianName": technician.name,
            "status": "in_progress",
            "assignedAt": Timestamp(),
            "updatedAt": Timestamp()
        ]
        
        db.collection(collection).document(requestId).updateData(updates) { [weak self] error in
            if let error = error {
                print("❌ Failed to assign: \(error.localizedDescription)")
                completion(false, error.localizedDescription)
                return
            }
            
            print("✅ Auto-assigned \(technician.name) to request \(requestId)")
            
            // Increment technician's task count
            self?.incrementTechnicianTasks(technicianId: technician.id)
            
            // Get request name for notification
            self?.db.collection(collection).document(requestId).getDocument { document, error in
                guard let data = document?.data(),
                      let requestName = data["requestName"] as? String else {
                    completion(true, nil)
                    return
                }
                
                // 🔔 Notify the technician
                TechnicianNotificationService.shared.notifyTechnicianAssignment(
                    technicianId: technician.id,
                    technicianName: technician.name,
                    requestId: requestId,
                    requestName: requestName,
                    location: location,
                    urgency: urgency,
                    category: category
                )
                
                completion(true, nil)
            }
        }
    }
    
    // MARK: - Increment Task Count
    
    private func incrementTechnicianTasks(technicianId: String) {
        db.collection("technicians").document(technicianId).updateData([
            "tasks": FieldValue.increment(Int64(1))
        ]) { error in
            if let error = error {
                print("⚠️ Failed to increment tasks: \(error.localizedDescription)")
            } else {
                print("✅ Incremented task count for technician")
            }
        }
    }
    
    // MARK: - Check if Auto-Assignment is Needed
    
    /// Check if a request needs auto-assignment
    func checkAndAutoAssign(requestId: String, requestType: String) {
        let collection = requestType == "maintenance" ? "maintenanceRequest" : "inventoryRequest"
        
        db.collection(collection).document(requestId).getDocument { [weak self] document, error in
            guard let self = self,
                  let data = document?.data() else { return }
            
            // Check if already assigned
            if data["assignedTechnicianId"] != nil {
                print("ℹ️ Request already assigned, skipping auto-assignment")
                return
            }
            
            // Check if status is pending
            let status = data["status"] as? String ?? "pending"
            guard status == "pending" else {
                print("ℹ️ Request status is \(status), not pending")
                return
            }
            
            let category = data["category"] as? String ?? "general"
            let location = data["location"] as? String ?? "Unknown"
            let urgency = data["urgency"] as? String ?? "normal"
            
            print("🤖 Auto-assigning request \(requestId)...")
            
            self.autoAssignTechnician(
                requestId: requestId,
                requestType: requestType,
                category: category,
                location: location,
                urgency: urgency
            ) { success, error in
                if success {
                    print("✅ Auto-assignment successful")
                } else {
                    print("⚠️ Auto-assignment failed: \(error ?? "Unknown error")")
                }
            }
        }
    }
}

// MARK: - Supporting Models

struct TechnicianInfo {
    let id: String
    let name: String
    let hours: String          // "6:00 - 12:00"
    let availability: String   // "available" or "unavailable"
    let solvedTasks: Int
    let tasks: Int             // Current active tasks
}