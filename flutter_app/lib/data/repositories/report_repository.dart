import '../models/report_item.dart';
import '../mock/mock_data.dart';

abstract class ReportRepository {
  Future<List<ReportItem>> getReports({String? type});
  Future<ReportItem?> getReportById(String id);
  Future<ReportItem> getLatestDailyReport();
}

class MockReportRepository implements ReportRepository {
  @override
  Future<List<ReportItem>> getReports({String? type}) async {
    if (type == null || type == 'All') {
      return MockData.reports;
    }
    return MockData.reports.where((r) => r.type.toLowerCase() == type.toLowerCase()).toList();
  }

  @override
  Future<ReportItem?> getReportById(String id) async {
    try {
      return MockData.reports.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ReportItem> getLatestDailyReport() async {
    return MockData.reports.firstWhere((r) => r.type == 'Daily');
  }
}
