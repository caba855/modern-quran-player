.pragma library

.import QtQuick.LocalStorage 2.0 as Sql

var DB_NAME = "quran_player_widget";
var DB_VERSION = "1.0";
var DB_DESCRIPTION = "Quran player settings";
var DB_ESTIMATED_SIZE = 2 * 1024 * 1024;

function _db() {
  return Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_ESTIMATED_SIZE);
}

function initialize() {
  var db = _db();
  db.transaction(function(tx) {
    tx.executeSql("CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)");
    tx.executeSql("CREATE TABLE IF NOT EXISTS bookmarks (id TEXT PRIMARY KEY, payload TEXT NOT NULL)");
    tx.executeSql("CREATE TABLE IF NOT EXISTS presets (id TEXT PRIMARY KEY, payload TEXT NOT NULL)");
    tx.executeSql("CREATE TABLE IF NOT EXISTS ayah_text_cache (key TEXT PRIMARY KEY, text TEXT NOT NULL, cached_at INTEGER NOT NULL)");
    tx.executeSql("CREATE TABLE IF NOT EXISTS khatm_progress (surah INTEGER PRIMARY KEY, completed_at INTEGER NOT NULL, listen_count INTEGER NOT NULL DEFAULT 1)");
  });
}

function setSetting(key, value) {
  var db = _db();
  var payload = JSON.stringify(value);
  db.transaction(function(tx) {
    tx.executeSql("INSERT OR REPLACE INTO settings(key, value) VALUES (?, ?)", [key, payload]);
  });
}

function getSetting(key, fallbackValue) {
  var db = _db();
  var result = fallbackValue;

  db.readTransaction(function(tx) {
    var rows = tx.executeSql("SELECT value FROM settings WHERE key = ?", [key]);
    if (rows.rows.length > 0) {
      try {
        result = JSON.parse(rows.rows.item(0).value);
      } catch (error) {
        result = fallbackValue;
      }
    }
  });

  return result;
}

function _createId(prefix) {
  return prefix + ":" + Date.now() + ":" + Math.floor(Math.random() * 1000000);
}

function saveBookmark(bookmark) {
  var db = _db();
  var item = bookmark || {};

  if (!item.id) {
    item.id = _createId("bookmark");
  }
  if (!item.createdAt) {
    item.createdAt = new Date().toISOString();
  }

  db.transaction(function(tx) {
    tx.executeSql("INSERT OR REPLACE INTO bookmarks(id, payload) VALUES (?, ?)", [item.id, JSON.stringify(item)]);
  });

  return item;
}

function removeBookmark(id) {
  var db = _db();
  db.transaction(function(tx) {
    tx.executeSql("DELETE FROM bookmarks WHERE id = ?", [id]);
  });
}

function listBookmarks() {
  var db = _db();
  var list = [];

  db.readTransaction(function(tx) {
    var rows = tx.executeSql("SELECT payload FROM bookmarks ORDER BY id DESC");
    for (var i = 0; i < rows.rows.length; i += 1) {
      try {
        list.push(JSON.parse(rows.rows.item(i).payload));
      } catch (error) {
        // Skip corrupted rows.
      }
    }
  });

  return list;
}

function savePreset(preset) {
  var db = _db();
  var item = preset || {};

  if (!item.id) {
    item.id = _createId("preset");
  }
  if (!item.createdAt) {
    item.createdAt = new Date().toISOString();
  }

  db.transaction(function(tx) {
    tx.executeSql("INSERT OR REPLACE INTO presets(id, payload) VALUES (?, ?)", [item.id, JSON.stringify(item)]);
  });

  return item;
}

function removePreset(id) {
  var db = _db();
  db.transaction(function(tx) {
    tx.executeSql("DELETE FROM presets WHERE id = ?", [id]);
  });
}

function listPresets() {
  var db = _db();
  var list = [];

  db.readTransaction(function(tx) {
    var rows = tx.executeSql("SELECT payload FROM presets ORDER BY id DESC");
    for (var i = 0; i < rows.rows.length; i += 1) {
      try {
        list.push(JSON.parse(rows.rows.item(i).payload));
      } catch (error) {
        // Skip corrupted rows.
      }
    }
  });

  return list;
}

function ayahTextKey(surahNumber, ayahNumber, prefix) {
  return (prefix || "") + String(surahNumber) + ":" + String(ayahNumber);
}

function getCachedAyahText(surahNumber, ayahNumber, maxAgeMs, prefix) {
  var db = _db();
  var key = ayahTextKey(surahNumber, ayahNumber, prefix);
  var result = "";
  var ttl = maxAgeMs || (30 * 24 * 60 * 60 * 1000);

  db.readTransaction(function(tx) {
    var rows = tx.executeSql("SELECT text, cached_at FROM ayah_text_cache WHERE key = ?", [key]);
    if (rows.rows.length > 0) {
      var item = rows.rows.item(0);
      if ((Date.now() - Number(item.cached_at)) <= ttl) {
        result = item.text;
      }
    }
  });

  return result;
}

function saveAyahText(surahNumber, ayahNumber, text, prefix) {
  if (!text || text.length === 0) {
    return;
  }

  var db = _db();
  var key = ayahTextKey(surahNumber, ayahNumber, prefix);
  db.transaction(function(tx) {
    tx.executeSql(
      "INSERT OR REPLACE INTO ayah_text_cache(key, text, cached_at) VALUES (?, ?, ?)",
      [key, text, Date.now()]
    );
    tx.executeSql(
      "DELETE FROM ayah_text_cache WHERE key NOT IN (SELECT key FROM ayah_text_cache ORDER BY cached_at DESC LIMIT 600)"
    );
  });
}

// ---- Khatm (full-Quran listening) progress -------------------------------
function markSurahCompleted(surahNumber) {
  var db = _db();
  db.transaction(function(tx) {
    var rows = tx.executeSql("SELECT listen_count FROM khatm_progress WHERE surah = ?", [surahNumber]);
    var count = rows.rows.length > 0 ? (rows.rows.item(0).listen_count + 1) : 1;
    tx.executeSql(
      "INSERT OR REPLACE INTO khatm_progress(surah, completed_at, listen_count) VALUES (?, ?, ?)",
      [surahNumber, Date.now(), count]
    );
  });
}

// Returns { [surahNumber]: { completedAt, listenCount } }.
function listKhatm() {
  var db = _db();
  var map = {};
  db.readTransaction(function(tx) {
    var rows = tx.executeSql("SELECT surah, completed_at, listen_count FROM khatm_progress");
    for (var i = 0; i < rows.rows.length; i += 1) {
      var row = rows.rows.item(i);
      map[row.surah] = { completedAt: row.completed_at, listenCount: row.listen_count };
    }
  });
  return map;
}

function removeKhatm(surahNumber) {
  var db = _db();
  db.transaction(function(tx) {
    tx.executeSql("DELETE FROM khatm_progress WHERE surah = ?", [surahNumber]);
  });
}

function clearKhatm() {
  var db = _db();
  db.transaction(function(tx) {
    tx.executeSql("DELETE FROM khatm_progress");
  });
}
