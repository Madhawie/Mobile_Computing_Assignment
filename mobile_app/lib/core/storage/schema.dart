/// SQLite schema of the phone's local database.
///
/// Column names are exactly the keys of each model's `toMap()`
/// (lib/data/models), so a model can be inserted and read back directly.
/// The database tests check this for every table.
///
/// No FOREIGN KEY constraints on purpose: records arrive from the server
/// in change order, and a child could be pulled before its mother after a
/// merge. Integrity is checked by the server (`PARENT_NOT_FOUND`).
library;

/// Table names.
class Tables {
  Tables._();

  static const mothers = 'mothers';
  static const maternalVisits = 'maternal_visits';
  static const children = 'children';
  static const growthMeasurements = 'growth_measurements';
  static const vaccinations = 'vaccinations';
  static const outbox = 'outbox';
  static const syncLog = 'sync_log';
  static const meta = 'meta';

  /// Tables holding synced records, by `entity` name used in the API.
  static const byEntity = {
    'mother': mothers,
    'maternalVisit': maternalVisits,
    'child': children,
    'growthMeasurement': growthMeasurements,
    'vaccination': vaccinations,
  };
}

/// Keys of the `meta` table (small key / value settings).
class MetaKeys {
  MetaKeys._();

  /// UUID of this phone, made once on first start.
  static const deviceId = 'device_id';

  /// `cursor` from the last pull (api.md section 5). Missing = never pulled.
  static const pullCursor = 'pull_cursor';

  /// Time of the last successful sync, for the sync screen.
  static const lastSyncAt = 'last_sync_at';

  /// Strategy in use: S1, S2 or S3 (changed on the tester screen).
  static const syncStrategy = 'sync_strategy';

  /// API address chosen on the phone; overrides AppConstants.apiBaseUrl.
  static const apiBaseUrl = 'api_base_url';

  /// Language picked on the first screen: `si`, `ta` or `en`.
  static const language = 'language';
}

/// Columns every synced record table has (SyncRecord + phone-only fields).
///
/// `server_version` is phone only and not in the model: the last version the
/// server confirmed. S3 sends it as `baseVersion`, while `version` goes up
/// with every local edit.
const _recordColumns = '''
  id TEXT PRIMARY KEY,
  version INTEGER NOT NULL,
  server_version INTEGER NOT NULL DEFAULT 0,
  updated_at TEXT NOT NULL,
  device_id TEXT NOT NULL,
  deleted INTEGER NOT NULL DEFAULT 0,
  is_dirty INTEGER NOT NULL DEFAULT 0''';

/// Version 1 of the schema: run once when the database is created.
const schemaV1 = <String>[
  '''
CREATE TABLE ${Tables.mothers} (
$_recordColumns,
  full_name TEXT NOT NULL,
  phone TEXT NOT NULL,
  age INTEGER NOT NULL,
  address TEXT NOT NULL,
  area_id TEXT NOT NULL,
  is_pregnant INTEGER NOT NULL DEFAULT 0,
  gestation_weeks INTEGER,
  due_date TEXT
)''',
  '''
CREATE TABLE ${Tables.maternalVisits} (
$_recordColumns,
  mother_id TEXT NOT NULL,
  visit_date TEXT NOT NULL,
  gestation_weeks INTEGER NOT NULL,
  weight_kg REAL NOT NULL,
  bp_systolic INTEGER NOT NULL,
  bp_diastolic INTEGER NOT NULL,
  notes TEXT,
  next_visit TEXT
)''',
  '''
CREATE TABLE ${Tables.children} (
$_recordColumns,
  mother_id TEXT NOT NULL,
  name TEXT NOT NULL,
  sex TEXT NOT NULL CHECK (sex IN ('boy', 'girl')),
  date_of_birth TEXT NOT NULL,
  birth_weight_kg REAL NOT NULL,
  born_at TEXT,
  chdr_number TEXT
)''',
  '''
CREATE TABLE ${Tables.growthMeasurements} (
$_recordColumns,
  child_id TEXT NOT NULL,
  measured_on TEXT NOT NULL,
  weight_kg REAL NOT NULL,
  height_cm REAL,
  notes TEXT
)''',
  '''
CREATE TABLE ${Tables.vaccinations} (
$_recordColumns,
  child_id TEXT NOT NULL,
  vaccine TEXT NOT NULL,
  dose INTEGER NOT NULL,
  given_on TEXT NOT NULL,
  batch_no TEXT
)''',
  // Outbox: one row per local change. AUTOINCREMENT id = send order.
  // operation_id is UNIQUE so the same change can never be queued twice.
  '''
CREATE TABLE ${Tables.outbox} (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  operation_id TEXT NOT NULL UNIQUE,
  entity TEXT NOT NULL,
  op TEXT NOT NULL CHECK (op IN ('upsert', 'delete')),
  record_id TEXT NOT NULL,
  base_version INTEGER NOT NULL,
  changed_fields TEXT NOT NULL,
  payload TEXT NOT NULL,
  created_at TEXT NOT NULL,
  attempts INTEGER NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'failed')),
  last_error TEXT
)''',
  // One row per sync run: the raw data of the experiments.
  '''
CREATE TABLE ${Tables.syncLog} (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  strategy TEXT NOT NULL,
  started_at TEXT NOT NULL,
  duration_ms INTEGER NOT NULL,
  record_count INTEGER NOT NULL,
  changed_count INTEGER NOT NULL,
  bytes_sent INTEGER NOT NULL,
  bytes_received INTEGER NOT NULL,
  network_profile TEXT NOT NULL,
  success INTEGER NOT NULL,
  conflicts INTEGER NOT NULL DEFAULT 0,
  duplicates INTEGER NOT NULL DEFAULT 0,
  retries INTEGER NOT NULL DEFAULT 0,
  error_code TEXT,
  run_label TEXT
)''',
  '''
CREATE TABLE ${Tables.meta} (
  key TEXT PRIMARY KEY,
  value TEXT
)''',
  // Indexes for the queries the app runs often.
  'CREATE INDEX idx_mothers_area ON ${Tables.mothers} (area_id)',
  'CREATE INDEX idx_mothers_dirty ON ${Tables.mothers} (is_dirty)',
  'CREATE INDEX idx_visits_mother ON ${Tables.maternalVisits} (mother_id)',
  'CREATE INDEX idx_visits_dirty ON ${Tables.maternalVisits} (is_dirty)',
  'CREATE INDEX idx_children_mother ON ${Tables.children} (mother_id)',
  'CREATE INDEX idx_children_dirty ON ${Tables.children} (is_dirty)',
  'CREATE INDEX idx_growth_child ON ${Tables.growthMeasurements} (child_id, measured_on)',
  'CREATE INDEX idx_growth_dirty ON ${Tables.growthMeasurements} (is_dirty)',
  'CREATE INDEX idx_vacc_child ON ${Tables.vaccinations} (child_id)',
  'CREATE INDEX idx_vacc_dirty ON ${Tables.vaccinations} (is_dirty)',
  'CREATE INDEX idx_outbox_status ON ${Tables.outbox} (status, id)',
  'CREATE INDEX idx_outbox_record ON ${Tables.outbox} (record_id)',
];

/// Changes for later versions. Index 0 upgrades version 1 to 2, and so on.
/// Never edit a released step; add a new one and raise [schemaVersion].
const migrations = <List<String>>[];

/// Current database version. Must equal 1 + migrations.length
/// (a test checks this).
const schemaVersion = 1;
