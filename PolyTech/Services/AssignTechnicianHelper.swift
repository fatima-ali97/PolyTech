//
//  AssignTechnicianHelper.swift
//  PolyTech
//
//  Created by BP-36-213-19 on 03/01/2026.
//


import Foundation
import FirebaseFirestore

// MARK: - Example: How to assign technician and trigger notification

class AssignTechnicianHelper {
    
    private let db = Firestore.firestore()
    
    // MARK: - Assign Technician to Request
    
    /// Assign a technician to a request (call this from any admin view)
    func assignTechnician(
        requestId: String,
        technicianId: String,
        technicianName: String,
        completion: @escaping (Bool, String?) -> Void
    ) {
        // First, get the request details
        db.collection("requests").document(requestId).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Error fetching request: \(error.localizedDescription)")
                completion(false, "Failed to fetch request details")
                return
            }
            
            guard let data = document?.data(),
                  let requestName = data["requestName"] as? String,
                  let location = data["location"] as? String else {
                print("❌ Missing required fields")
                completion(false, "Missing request information")
                return
            }
            
            let urgency = data["urgency"] as? String ?? "normal"
            let category = data["category"] as? String ?? "general"
            
            // Update the request with assignment
            let updates: [String: Any] = [
                "assignedTechnicianId": technicianId,
                "assignedTechnicianName": technicianName,
                "status": "in_progress",
                "updatedAt": FieldValue.serverTimestamp()
            ]
            
            self.db.collection("requests").document(requestId).updateData(updates) { error in
                if let error = error {
                    print("❌ Failed to assign technician: \(error.localizedDescription)")
                    completion(false, "Failed to assign technician")
                    return
                }
                
                print("✅ Successfully assigned \(technicianName) to request \(requestId)")
                
                // 🔔 Send notification to technician
                TechnicianNotificationService.shared.notifyTechnicianAssignment(
                    technicianId: technicianId,
                    technicianName: technicianName,
                    requestId: requestId,
                    requestName: requestName,
                    location: location,
                    urgency: urgency,
                    category: category
                )
                
                completion(true, nil)
                
                // 🔔 Student will automatically receive "Work Started" notification
                // via RequestStatusNotificationService (status changed to in_progress)
            }
        }
    }
    
    // MARK: - Get Available Technicians
    
    /// Get list of available technicians
    func getAvailableTechnicians(completion: @escaping ([Technician]) -> Void) {
        db.collection("technicians")
            .order(by: "name")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching technicians: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                let technicians = snapshot?.documents.compactMap { doc -> Technician? in
                    let data = doc.data()
                    guard let name = data["name"] as? String else { return nil }
                    
                    return Technician(
                        id: doc.documentID,
                        name: name,
                        email: data["email"] as? String,
                        specialization: data["specialization"] as? String
                    )
                } ?? []
                
                completion(technicians)
            }
    }
    
    // MARK: - Reassign Technician
    
    /// Reassign a request to a different technician
    func reassignTechnician(
        requestId: String,
        newTechnicianId: String,
        newTechnicianName: String,
        reason: String? = nil,
        completion: @escaping (Bool, String?) -> Void
    ) {
        // Get request details
        db.collection("requests").document(requestId).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            guard let data = document?.data(),
                  let requestName = data["requestName"] as? String,
                  let location = data["location"] as? String else {
                completion(false, "Failed to fetch request")
                return
            }
            
            let oldTechnicianName = data["assignedTechnicianName"] as? String ?? "previous technician"
            let urgency = data["urgency"] as? String ?? "normal"
            let category = data["category"] as? String ?? "general"
            
            // Update assignment
            let updates: [String: Any] = [
                "assignedTechnicianId": newTechnicianId,
                "assignedTechnicianName": newTechnicianName,
                "reassignmentReason": reason ?? "Reassigned by admin",
                "reassignedAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ]
            
            self.db.collection("requests").document(requestId).updateData(updates) { error in
                if let error = error {
                    print("❌ Failed to reassign: \(error.localizedDescription)")
                    completion(false, "Failed to reassign technician")
                    return
                }
                
                print("✅ Reassigned from \(oldTechnicianName) to \(newTechnicianName)")
                
                // 🔔 Notify new technician
                TechnicianNotificationService.shared.notifyTechnicianAssignment(
                    technicianId: newTechnicianId,
                    technicianName: newTechnicianName,
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
}

// MARK: - Supporting Models

struct Technician {
    let id: String
    let name: String
    let email: String?
    let specialization: String?
}

// MARK: - Example Usage in View Controller

/*
 
 // In your Admin View Controller:
 
 class AdminRequestViewController: UIViewController {
     
     private let assignHelper = AssignTechnicianHelper()
     
     // Example 1: Show technician picker and assign
     @IBAction func assignButtonTapped(_ sender: UIButton) {
         let requestId = "some_request_id"
         
         // Get available technicians
         assignHelper.getAvailableTechnicians { [weak self] technicians in
             guard !technicians.isEmpty else {
                 self?.showAlert("No technicians available")
                 return
             }
             
             // Show picker
             self?.showTechnicianPicker(technicians: technicians) { selectedTech in
                 // Assign the technician
                 self?.assignHelper.assignTechnician(
                     requestId: requestId,
                     technicianId: selectedTech.id,
                     technicianName: selectedTech.name
                 ) { success, error in
                     if success {
                         self?.showAlert("✅ \(selectedTech.name) has been assigned and notified")
                     } else {
                         self?.showAlert("❌ \(error ?? "Failed to assign")")
                     }
                 }
             }
         }
     }
     
     // Example 2: Reassign technician
     @IBAction func reassignButtonTapped(_ sender: UIButton) {
         let requestId = "some_request_id"
         
         assignHelper.getAvailableTechnicians { [weak self] technicians in
             self?.showTechnicianPicker(technicians: technicians) { selectedTech in
                 self?.assignHelper.reassignTechnician(
                     requestId: requestId,
                     newTechnicianId: selectedTech.id,
                     newTechnicianName: selectedTech.name,
                     reason: "Workload rebalancing"
                 ) { success, error in
                     if success {
                         self?.showAlert("✅ Reassigned to \(selectedTech.name)")
                     }
                 }
             }
         }
     }
     
     private func showTechnicianPicker(
         technicians: [Technician],
         completion: @escaping (Technician) -> Void
     ) {
         let alert = UIAlertController(
             title: "Select Technician",
             message: "Choose a technician to assign",
             preferredStyle: .actionSheet
         )
         
         for tech in technicians {
             alert.addAction(UIAlertAction(title: tech.name, style: .default) { _ in
                 completion(tech)
             })
         }
         
         alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
         present(alert, animated: true)
     }
     
     private func showAlert(_ message: String) {
         let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
         alert.addAction(UIAlertAction(title: "OK", style: .default))
         present(alert, animated: true)
     }
 }
 
 */