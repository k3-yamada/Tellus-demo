import 'package:flutter_test/flutter_test.dart';
import 'package:tellus_demo/domain/models/asset_template.dart';
import 'package:tellus_demo/domain/models/infrastructure_snapshot.dart';
import 'package:tellus_demo/domain/models/observation.dart';
import 'package:tellus_demo/domain/models/region.dart';
import 'package:tellus_demo/domain/repositories/infrastructure_repository.dart';
import 'package:tellus_demo/ui/features/dashboard/view_models/dashboard_view_model.dart';

class _FakeRepo implements InfrastructureRepository {
  @override
  Future<InfrastructureSnapshot> load({AssetTemplate? template}) async {
    return InfrastructureSnapshot(
      generatedAt: '2026-01-01',
      regions: [
        Region(
          id: 'joganji',
          name: 'Test',
          type: 'embankment',
          lat: 36.6,
          lng: 137.3,
          observations: [
            Observation(
              dataId: 'a',
              datasetId: 'ds1',
              acquisitionDate: '2024-06-15',
              startDatetime: '2024-06-15T00:00:00Z',
              orbitDirection: 'ascending',
              polarization: 'HH',
              offNadir: 30,
              monitoringIndex: 0.5,
            ),
            Observation(
              dataId: 'b',
              datasetId: 'ds1',
              acquisitionDate: '2024-01-10',
              startDatetime: '2024-01-10T00:00:00Z',
              orbitDirection: 'descending',
              polarization: 'VV',
              offNadir: 35,
              monitoringIndex: 0.6,
            ),
          ],
        ),
      ],
      timelineSteps: const [],
      sliderDates: const ['2024-01-10T00:00:00Z', '2024-06-15T00:00:00Z'],
      qualityReport: const QualityReport(
        overallScore: 0.8,
        totalObservations: 2,
        regionsWithGeometry: 2,
        regionsWithThumbnails: 0,
        notes: [],
      ),
    );
  }
}

void main() {
  test('rainy season filters non-summer months', () async {
    final vm = DashboardViewModel(repository: _FakeRepo());
    await vm.load();
    vm.setScenario(DemoScenario.rainySeason);
    final region = vm.regions.first;
    final filtered = vm.filteredObservations(region);
    expect(filtered.length, 1);
    expect(filtered.first.dataId, 'a');
  });

  test('long term keeps roughly last 90 days window', () async {
    final vm = DashboardViewModel(repository: _FakeRepo());
    await vm.load();
    vm.setScenario(DemoScenario.longTerm);
    final region = vm.regions.first;
    final filtered = vm.filteredObservations(region);
    expect(filtered.length, greaterThanOrEqualTo(1));
  });

  test('summary insights lists capabilities', () async {
    final vm = DashboardViewModel(repository: _FakeRepo());
    await vm.load();
    expect(vm.summaryInsights.canUnderstand, isNotEmpty);
    expect(vm.summaryInsights.cannotUnderstand, isNotEmpty);
  });
}
