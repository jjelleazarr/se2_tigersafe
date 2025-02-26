import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GeneralReportList {
  // generateReportsList():
  //     when admin selects "Generate Report List":
  //         reports = FirebaseFirestore.collection("reports").get()
  //
  //         reportList = []
  //         for report in reports:
  //             reportList.append(report.data())
  //
  //         exportReportsToPDF(reportList)
  //
  // exportReportsToPDF(reportList):
  //     pdf = generatePDF(reportList)
  //     savePDFToFile(pdf)
  //     displaySuccess("Report List Generated")
}