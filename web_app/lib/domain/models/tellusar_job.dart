/// TelluSAR (InSAR 干渉解析) ジョブを表す domain モデル。
enum TellusarJobStatus { idle, submitting, queued, running, succeeded, failed }

class TellusarPairRequest {
  const TellusarPairRequest({
    required this.referenceSceneId,
    required this.secondarySceneId,
    required this.regionId,
    required this.label,
  });

  final String referenceSceneId;
  final String secondarySceneId;
  final String regionId;
  final String label;
}

class TellusarJob {
  const TellusarJob({
    required this.jobId,
    required this.status,
    required this.submittedAt,
    this.statusMessage,
    this.result,
  });

  final String jobId;
  final TellusarJobStatus status;
  final String submittedAt;
  final String? statusMessage;
  final TellusarInterferogram? result;

  bool get isTerminal =>
      status == TellusarJobStatus.succeeded ||
      status == TellusarJobStatus.failed;

  TellusarJob copyWith({
    TellusarJobStatus? status,
    String? statusMessage,
    TellusarInterferogram? result,
  }) {
    return TellusarJob(
      jobId: jobId,
      submittedAt: submittedAt,
      status: status ?? this.status,
      statusMessage: statusMessage ?? this.statusMessage,
      result: result ?? this.result,
    );
  }
}

/// 干渉解析結果の要約 (本物のラスタは取得せず、サマリーで表示する)。
class TellusarInterferogram {
  const TellusarInterferogram({
    required this.coherenceMean,
    required this.maxDisplacementMm,
    required this.minDisplacementMm,
    required this.perpendicularBaselineM,
    required this.temporalBaselineDays,
    required this.notes,
  });

  final double coherenceMean;
  final double maxDisplacementMm;
  final double minDisplacementMm;
  final double perpendicularBaselineM;
  final int temporalBaselineDays;
  final List<String> notes;
}
