#include <sqlite3.h>

// Isolated test process only. Model a host whose global URI default is off.
int taskpulse_disable_default_uri(void) {
    int result = sqlite3_shutdown();
    return result == SQLITE_OK ? sqlite3_config(SQLITE_CONFIG_URI, 0) : result;
}
