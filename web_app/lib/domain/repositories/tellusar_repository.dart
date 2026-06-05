import '../models/tellusar_job.dart';

/// TelluSAR ジョブの送信・ステータス取得を抽象化する。
/// 実装は本番 BFF / dry-run / モックを差し替え可能にする。
abstract class TellusarRepository {
  Future<TellusarJob> submitJob(TellusarPairRequest request);
  Future<TellusarJob> fetchStatus(String jobId);
}
