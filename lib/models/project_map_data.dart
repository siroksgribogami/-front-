/// Контракт JSONB `marketplace_projects.map_data` (PostgreSQL).
///
/// ```json
/// {
///   "before": { "apartmentId", "rooms", "tasks", ... },
///   "after": { "apartmentId", "rooms", "tasks", ... },
///   "rooms": [ { "roomId", "displayName", ... } ],
///   "source": "post_register_survey",
///   "last_unity_patch": { "patchVersion", "roomsUpsert", ... },
///   "object_card": { "meta", "passport", "rooms", "estimate", ... },
///   "ai_foreman_stage": "discovery",
///   "ai_map_source": "stub",
///   "ai_focus_room_id": "room_kitchen"
/// }
/// ```
class ProjectMapDataKeys {
  ProjectMapDataKeys._();

  static const before = 'before';
  static const after = 'after';
  static const rooms = 'rooms';
  static const tasks = 'tasks';
  static const source = 'source';
  static const objectCard = 'object_card';
  static const lastUnityPatch = 'last_unity_patch';
  static const aiForemanStage = 'ai_foreman_stage';
  static const aiForemanSource = 'ai_foreman_source';
  static const aiMapSource = 'ai_map_source';
  static const aiFocusRoomId = 'ai_focus_room_id';
}
