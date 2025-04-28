-----------------------------------
-- NETWORK SETTINGS
-----------------------------------
xi = xi or {}
xi.settings = xi.settings or {}
  --
  --
  -- update ports and ip addresses where needed.
  --
  --
xi.settings.network =
{
    SQL_HOST     = "ffxi-mysql",
    SQL_PORT     = 3306,
    SQL_LOGIN    = "xiuser",
    SQL_PASSWORD = "your_passwords_here",
    SQL_DATABASE = "xidb",

    LOGIN_DATA_IP   = "0.0.0.0",
    LOGIN_DATA_PORT = 54230,
    LOGIN_VIEW_IP   = "0.0.0.0",
    LOGIN_VIEW_PORT = 54001,
    LOGIN_AUTH_IP   = "0.0.0.0",
    LOGIN_AUTH_PORT = 54231,
    LOGIN_CONF_IP   = "0.0.0.0",
    LOGIN_CONF_PORT = 51220,

    MAP_PORT = 54230,
    ZONE_IP = "update to ip or hostname",

    SEARCH_PORT = 54002,

    SQL_QUERY_RETRY_COUNT = 1,

    ENABLE_HTTP = false,
    HTTP_HOST   = "localhost",
    HTTP_PORT   = 8088,

    ZMQ_IP   = "0.0.0.0",
    ZMQ_PORT = 54003,

    UDP_DEBUG = false,

    TCP_DEBUG = false,
    TCP_STALL_TIME = 60,

    TCP_ENABLE_IP_RULES = true,
    TCP_ORDER = "deny,allow",

    TCP_ALLOW = "",
    TCP_DENY = "",

    TCP_CONNECT_INTERVAL = 3000,
    TCP_CONNECT_COUNT = 10,
    TCP_CONNECT_LOCKOUT = 600000
}
