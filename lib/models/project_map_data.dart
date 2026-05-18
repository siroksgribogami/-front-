/// Контракт JSONB `marketplace_projects.map_data` (PostgreSQL).
///
/// ```json
/// {
///   "before": { "apartmentId", "rooms", "tasks", ... },
///   "after": { "apartmentId", "rooms", "tasks", ... },
///   "rooms": [ { "roomId", "displayName", ... } ],
///   "source": "post_register_survey",
///   "last_unity_patch": { "patchVersion", "roomsUpsert", ... },
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
  static const lastUnityPatch = 'last_unity_patch';
  static const aiMapSource = 'ai_map_source';
  static const aiFocusRoomId = 'ai_focus_room_id';
}
