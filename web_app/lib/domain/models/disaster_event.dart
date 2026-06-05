/// 災害アーカイブの 1 イベント (例: 能登半島地震)。
/// before / during / after の Tellus 観測フェーズを束ねる。
class DisasterEvent {
  const DisasterEvent({
    required this.id,
    required this.name,
    required this.summary,
    required this.lat,
    required this.lon,
    required this.eventDatetime,
    required this.demoFocus,
    required this.phases,
  });

  final String id;
  final String name;
  final String summary;
  final double lat;
  final double lon;
  final String eventDatetime;
  final String demoFocus;
  final List<DisasterPhase> phases;

  DisasterPhase? phaseFor(DisasterPhaseLabel label) {
    for (final p in phases) {
      if (p.label == label) return p;
    }
    return null;
  }
}

enum DisasterPhaseLabel { before, during, after }

class DisasterPhase {
  const DisasterPhase({
    required this.label,
    required this.datasetId,
    required this.sceneId,
    required this.acquisitionDate,
    required this.acquisitionDatetime,
    required this.orbitDirection,
    required this.polarization,
    required this.note,
    this.thumbnailUrl,
  });

  final DisasterPhaseLabel label;
  final String datasetId;
  final String sceneId;
  final String acquisitionDate;
  final String acquisitionDatetime;
  final String orbitDirection;
  final String polarization;
  final String note;
  final String? thumbnailUrl;
}
