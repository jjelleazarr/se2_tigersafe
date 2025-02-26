import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TrackPastReportsController {
  // viewPastReports(userId):
  //     when user navigates to "Past Reports":
  //         reports = FirebaseFirestore.collection("reports").where("created_by", "==", userId).get()
  //
  //         for report in reports:
  //             displayReport(report)
  //
  // displayReport(report):
  //     print("Report #" + report.id + " - Status: " + report.status + " - " + report.created_at)
}