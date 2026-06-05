import 'dart:math' as math;

import '../../domain/models/tellusar_job.dart';
import '../../domain/repositories/tellusar_repository.dart';
import '../services/tellus_bff_client.dart';

/// BFF が未設定 / 失敗時は決定論的な擬似ジョブを返すフェイルセーフ実装。
/// 本物の TelluSAR を試したいときは BFF_URL を環境変数で渡す
/// (内部で X-Demo-Dry-Run を立てるので実課金なし)。
class TellusarRepositoryImpl implements TellusarRepository {
  TellusarRepositoryImpl({TellusBffClient? client, this.useDryRun = true})
      : _client = client ?? TellusBffClient();

  final TellusBffClient _client;
  final bool useDryRun;

  @override
  Future<TellusarJob> submitJob(TellusarPairRequest request) async {
    final submittedAt = DateTime.now().toUtc().toIso8601String();

    if (_client.isConfigured) {
      try {
        final resp = await _client.submitTellusarJob(
          referenceSceneId: request.referenceSceneId,
          secondarySceneId: request.secondarySceneId,
          regionId: request.regionId,
          dryRun: useDryRun,
        );
        final jobId = resp['jobId']?.toString() ??
            resp['id']?.toString() ??
            _localJobId(request);
        return TellusarJob(
          jobId: jobId,
          status: TellusarJobStatus.queued,
          submittedAt: submittedAt,
          statusMessage: resp['message']?.toString() ?? 'BFF dry-run 受理',
        );
      } catch (e) {
        return TellusarJob(
          jobId: _localJobId(request),
          status: TellusarJobStatus.queued,
          submittedAt: submittedAt,
          statusMessage: 'BFF 未到達 → ローカル擬似ジョブで継続 ($e)',
        );
      }
    }

    return TellusarJob(
      jobId: _localJobId(request),
      status: TellusarJobStatus.queued,
      submittedAt: submittedAt,
      statusMessage: 'BFF 未設定 — ローカル擬似ジョブ',
    );
  }

  @override
  Future<TellusarJob> fetchStatus(String jobId) async {
    if (_client.isConfigured && !jobId.startsWith('DEMO-')) {
      try {
        final resp = await _client.getTellusarJobStatus(jobId);
        final statusStr = (resp['status'] as String? ?? '').toLowerCase();
        return TellusarJob(
          jobId: jobId,
          submittedAt: resp['submittedAt'] as String? ?? '',
          status: _statusFromString(statusStr),
          statusMessage: resp['message'] as String?,
          result: _maybeResult(resp['result'] as Map<String, dynamic>?),
        );
      } catch (e) {
        return _syntheticTerminal(jobId, 'BFF status 取得失敗 → 擬似結果で継続 ($e)');
      }
    }
    return _syntheticTerminal(jobId, '擬似 InSAR 結果 (BFF 未設定)');
  }

  TellusarJob _syntheticTerminal(String jobId, String note) {
    final seed = jobId.codeUnits.fold<int>(0, (a, b) => (a + b) & 0xffff);
    final rnd = math.Random(seed);
    final coherence = 0.55 + rnd.nextDouble() * 0.30;
    final maxDisp = 3.0 + rnd.nextDouble() * 12.0;
    final minDisp = -(2.0 + rnd.nextDouble() * 6.0);
    final baseline = 50 + rnd.nextDouble() * 350;
    final tdays = 24 + rnd.nextInt(72);
    return TellusarJob(
      jobId: jobId,
      status: TellusarJobStatus.succeeded,
      submittedAt: DateTime.now().toUtc().toIso8601String(),
      statusMessage: note,
      result: TellusarInterferogram(
        coherenceMean: double.parse(coherence.toStringAsFixed(3)),
        maxDisplacementMm: double.parse(maxDisp.toStringAsFixed(2)),
        minDisplacementMm: double.parse(minDisp.toStringAsFixed(2)),
        perpendicularBaselineM: double.parse(baseline.toStringAsFixed(1)),
        temporalBaselineDays: tdays,
        notes: const [
          '本結果は決定論的に生成した擬似干渉解析サマリーです。',
          '本番では TelluSAR ジョブ完了後の GeoTIFF / coherence マップを取得します。',
        ],
      ),
    );
  }

  TellusarJobStatus _statusFromString(String raw) {
    switch (raw) {
      case 'queued':
      case 'pending':
        return TellusarJobStatus.queued;
      case 'running':
      case 'in_progress':
        return TellusarJobStatus.running;
      case 'succeeded':
      case 'success':
      case 'done':
        return TellusarJobStatus.succeeded;
      case 'failed':
      case 'error':
        return TellusarJobStatus.failed;
      default:
        return TellusarJobStatus.queued;
    }
  }

  TellusarInterferogram? _maybeResult(Map<String, dynamic>? json) {
    if (json == null) return null;
    return TellusarInterferogram(
      coherenceMean: (json['coherenceMean'] as num?)?.toDouble() ?? 0,
      maxDisplacementMm: (json['maxDisplacementMm'] as num?)?.toDouble() ?? 0,
      minDisplacementMm: (json['minDisplacementMm'] as num?)?.toDouble() ?? 0,
      perpendicularBaselineM:
          (json['perpendicularBaselineM'] as num?)?.toDouble() ?? 0,
      temporalBaselineDays:
          (json['temporalBaselineDays'] as num?)?.toInt() ?? 0,
      notes: (json['notes'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(growable: false),
    );
  }

  String _localJobId(TellusarPairRequest request) =>
      'DEMO-${request.regionId}-${DateTime.now().millisecondsSinceEpoch}';
}
