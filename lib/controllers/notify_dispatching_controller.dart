import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotifyDispatchingController {
  // assignResponseTeam(incidentId, teamId):
  //     when the command center assigns a response team:
  //         FirebaseFirestore.collection("incidents").document(incidentId).update({
  //             "assigned_team": teamId,
  //             "status": "Dispatched"
  //         })
  //
  //         notifyTeamOfAssignment(teamId, incidentId)
  //         displaySuccess("Team Assigned")
  //
  // notifyTeamOfAssignment(teamId, incidentId):
  //     // Notify the assigned team about the new incident
  //     notification = {
  //         "title": "New Incident Assigned",
  //         "message": "You have been assigned to incident #" + incidentId,
  //         "timestamp": Timestamp.now()
  //     }
  //     FirebaseFirestore.collection("teams").document(teamId).collection("notifications").add(notification)
  //
  // responderStatusUpdate(incidentId, statusUpdate):
  //     when a responder updates their status (e.g., "On the way", "At the scene"):
  //         FirebaseFirestore.collection("incidents").document(incidentId).update({
  //             "status": statusUpdate
  //         })
  //         logERTActivity(incidentId, statusUpdate)
  //         displaySuccess("Status Updated")
  //
  // logERTActivity(incidentId, activity):
  //     logEntry = {
  //         "incident_id": incidentId,
  //         "activity": activity,
  //         "timestamp": Timestamp.now(),
  //         "performed_by": currentUser.uid
  //     }
  //     FirebaseFirestore.collection("incidents").document(incidentId).collection("logs").add(logEntry)
}
