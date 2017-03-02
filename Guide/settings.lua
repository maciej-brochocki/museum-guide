module(..., package.seeall)

-- columns in lang.cfg file
LANG_NUM_COL = 1
LANG_KEY_COL = 2
LANG_FILE_COL = 3
LANG_NAME_COL = 4
LANG_IMAGE_COL = 5
LANG_HELP_IMAGE_COL = 6

-- columns in file with objects
OBJ_NUM_COL = 1
OBJ_NAME_COL = 2
OBJ_IMG_COL = 3
OBJ_TXT_COL = 4
OBJ_MP3_COL = 5

-- aplication settings
DEFAULT_LANG = 1
DEFAULT_OBJ = 1

-- ui modes
UI_MODE_NORMAL = 0
UI_MODE_LANGUAGE = 1
UI_MODE_SETTINGS = 2
UI_MODE_HELP = 3
UI_MODE_LIST = 4
UI_MODE_INPUT = 5
UI_MODE_MAP = 6
UI_MODE_QR = 7
UI_MODE_NFC = 8
UI_MODE_AR = 9

-- audio channels
AUDIO_CH_LECTOR = 1

-- audio state
AUDIO_STATE_STOPPED = 0
AUDIO_STATE_PLAYING = 1
AUDIO_STATE_PAUSED = 2

-- additional features, 1 to enable and 0 to disable feature
FEATURE_SELECT_LIST = 1
FEATURE_SELECT_INPUT = 0
FEATURE_SELECT_MAP = 0
FEATURE_SELECT_QR = 0
FEATURE_SELECT_NFC = 0
FEATURE_SELECT_AR = 0