-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

-- include libraries
local widget = require "widget"
widget.setTheme( "theme_ios" )

-- include our files
local lib = require "library"
local cfg = require "settings"
local txt = require "text_int"

display.setStatusBar( display.HiddenStatusBar )

-- LOGO
local logo = display.newImage("logo.jpg")
function onLogo(event)
	if (event.phase == "ended") or (not event.phase) then
		mdl_init()
		view_init()
		logo:removeSelf()
		logo = nil
	end
end
logo:addEventListener("touch", onLogo)
logo:addEventListener("tap", onLogo)


-- MODEL
local language_num     -- selected language number
local object_num = cfg.DEFAULT_OBJ   -- selected object number
local languages = {}   -- languages data
local language         -- selected language data
local objects = {}     -- objects data for given language
local object           -- selected object data
local lector           -- object's mp3 file handle
local info             -- object's text info
local audio_state = cfg.AUDIO_STATE_STOPPED   -- state of lector recording
local audio_length     -- lnegth of mp3 file in seconds
local audio_progress   -- current position in mp3 file

local t={}
function t:timer(event)
	if audio_state == cfg.AUDIO_STATE_PLAYING then
		audio_progress = audio_progress + 1
		view_update_progress()
	end
end
timer.performWithDelay(1000,t,0)

function onTimeChange(event)
	audio_progress = lib.round(event.target.value/100*audio_length)
	audio.seek(audio_progress * 1000, lector)
	view_update_progress()
end

function mdl_init()
	for line in io.lines(system.pathForFile( "lang.cfg" )) do
		local tmp = lib.ParseCSVLine(line)
		languages[tonumber(tmp[cfg.LANG_NUM_COL])] = tmp
	end
	mdl_select_language(cfg.DEFAULT_LANG)
end
	
function mdl_select_language(new_language_num)
	if language_num == new_language_num then
		return
	end
	local tmp
	language_num = new_language_num
	for k, tmp in ipairs(languages) do
		if (k == language_num) then
			language = tmp
			break
		end
	end
	objects = {}
	for line in io.lines(system.pathForFile( language[cfg.LANG_FILE_COL] )) do
		tmp = lib.ParseCSVLine(line,",")
		objects[tonumber(tmp[cfg.OBJ_NUM_COL])] = tmp
	end
	mdl_select_object(object_num, 1)
end

function mdl_update_object_vars(object)
	if lector then
		if audio_state ~= cfg.AUDIO_STATE_STOPPED then
			audio_state = cfg.AUDIO_STATE_STOPPED
			audio.stop(cfg.AUDIO_CH_LECTOR)
		end
		audio.dispose(lector)
		lector = nil
	end
	lector = audio.loadStream(object[cfg.OBJ_MP3_COL])
	audio_length = lib.round(audio.getDuration(lector) / 1000)
	audio_progress = 0
	local file = io.open( system.pathForFile( object[cfg.OBJ_TXT_COL] ), "r" )
	if file then
	   info = file:read( "*a" )
	   io.close( file )
	end
end

function mdl_select_object(new_object_num, force)
	if not force and object_num == new_object_num then
		return
	end
	if not objects[new_object_num] then
		return
	end
	local tmp
	object_num = new_object_num
	for k, tmp in ipairs(objects) do
		if (k == object_num) then
			object = tmp
			break
		end
	end
	mdl_update_object_vars(object)
end

function mdl_object_dec()
	local tmp; local prev_k
	for k, tmp in ipairs(objects) do
		if (k == object_num) then
			if prev_k then
				object = objects[prev_k]
				object_num = prev_k
				break
			end
		end
		prev_k = k
	end
	mdl_update_object_vars(object)
end

function mdl_object_inc()
	local tmp; local found_k = 0
	for k, tmp in ipairs(objects) do
		if (k == object_num) then
			found_k = 1
		elseif found_k == 1 then
			object = tmp
			object_num = k
			break
		end
	end
	mdl_update_object_vars(object)
end


-- VIEW, but for some reason it needs to be here
local ui_mode = cfg.UI_MODE_NORMAL   -- current mode of user interface
local table_view                     -- common table view element for many modes
local input                          -- input text control
local input_num                      -- current input value
local slider                         -- common slider element for many modes


-- CONTROLLER
-- UI_MODE_NORMAL
function onExitEvent(event)
	if event.phase == "ended" then
		os.exit()
	end
end

function onHelpEvent(event)
	if event.phase == "ended" then
		ui_mode = cfg.UI_MODE_HELP
		view_update_ui()
	end
end

function onFlagEvent(event)
	if event.phase == "ended" then
		ui_mode = cfg.UI_MODE_LANGUAGE
		view_update_ui()
	end
end

function onPreviousEvent(event)
	if event.phase == "ended" then
		mdl_object_dec()
		view_update_object()
	end
end

function onLectorDone()
	audio_state = cfg.AUDIO_STATE_STOPPED
	audio_progress = 0
	view_update_ui(1)
end

function onPlayEvent(event)
	if event.phase == "ended" then
		if audio_state == cfg.AUDIO_STATE_STOPPED then
			audio.play( lector, {channel = cfg.AUDIO_CH_LECTOR, onComplete=onLectorDone})
		else
			audio.resume(cfg.AUDIO_CH_LECTOR)
		end
		audio_state = cfg.AUDIO_STATE_PLAYING
		view_update_ui(1)
	end
end

function onPauseEvent(event)
	if event.phase == "ended" then
		audio.pause(cfg.AUDIO_CH_LECTOR)
		audio_state = cfg.AUDIO_STATE_PAUSED
		view_update_ui(1)
	end
end

function onNextEvent(event)
	if event.phase == "ended" then
		mdl_object_inc()
		view_update_object()
	end
end

function onSettingsEvent(event)
	if event.phase == "ended" then
		ui_mode = cfg.UI_MODE_SETTINGS
		view_update_ui()
	end
end

function onListEvent(event)
	if event.phase == "ended" then
		ui_mode = cfg.UI_MODE_LIST
		view_update_ui()
	end
end

function onInputEvent(event)
	if event.phase == "ended" then
		ui_mode = cfg.UI_MODE_INPUT
		view_update_ui()
	end
end

function onMapEvent(event)
	if event.phase == "ended" then
		-- TBD
	end
end

function onQrEvent(event)
	if event.phase == "ended" then
		-- TBD
	end
end

function onNfcEvent(event)
	if event.phase == "ended" then
		-- TBD
	end
end

function onArEvent(event)
	if event.phase == "ended" then
		-- TBD
	end
end

-- all modes - exit to UI_MODE_NORMAL
function onCancelEvent(event)
	if event.phase == "ended" then
		ui_mode = cfg.UI_MODE_NORMAL
		view_update_ui()
	end
end

-- UI_MODE_HELP
-- nothing here just reused stuff from other modes

-- UI_MODE_LANGUAGE
function onSelectLanguage(event)
	if (event.phase == "release") or (event.phase == "tap") then
		-- TBD: event.id
		local f = function() mdl_select_language(event.index); ui_mode = cfg.UI_MODE_NORMAL; view_update_ui(); end
		timer.performWithDelay(0,f)
	end
end

-- UI_MODE_LIST
function onSelectObject(event)
	if (event.phase == "release") or (event.phase == "tap") then
		-- TBD: event.id
		local f = function() mdl_select_object(event.index); ui_mode = cfg.UI_MODE_NORMAL; view_update_ui(); end
		timer.performWithDelay(0,f)
	end
end

-- UI_MODE_INPUT
function onInputX(event)
	if event.phase == "ended" then
		if input_num < 1000 then
			input_num = input_num * 10 + event.target.id
			view_update_input()
		end
	end
end

function onInputDelete(event)
	if event.phase == "ended" then
		if input_num then
			input_num = (input_num - input_num%10) / 10
			view_update_input()
		end
	end
end

function onInputSelect(event)
	if event.phase == "ended" then
		if input_num then
			mdl_select_object(input_num)
			ui_mode = cfg.UI_MODE_NORMAL
			view_update_ui()
		end
	end
end

-- UI_MODE_SETTINGS
function onSelectSettings(event)
	if event.phase == "ended" then
		audio.setVolume( slider.value / 100 )
		ui_mode = cfg.UI_MODE_NORMAL
		view_update_ui()
	end
end


-- VIEW
local screen_height = 480   -- screen height
local bg                    -- background image
local ui                    -- group for gui components
local scrollView            -- scrollview to store content

function view_update_object()
	if scrollView then
		scrollView:removeSelf()
		scrollView = nil
	end
	
	local s_top; local s_height; local mask_name
	if ui_mode == cfg.UI_MODE_NORMAL then
		s_top = 47
		s_height = 345
		mask_name = "mask.png"
	end
	
	scrollView = widget.newScrollView{ top=s_top, height=s_height, maskFile=mask_name}

	local picture = display.newImage( object[cfg.OBJ_IMG_COL], 0, s_top )
	scrollView:insert( picture )

	local title = display.newText(object[cfg.OBJ_NUM_COL] .. " " .. object[cfg.OBJ_NAME_COL], 5, s_top + picture.height +5, native.systemFontBold, 16)
	title:setTextColor(0, 0, 0)
	scrollView:insert( title )

	local text = display.newText(info, 5, s_top+ picture.height +5+16+5, 310, 0, native.systemFont, 16)
	text:setTextColor(0, 0, 0)
	scrollView:insert( text )
end

function view_update_progress()
	if ui_mode == cfg.UI_MODE_NORMAL then
		slider.value = lib.round(100*audio_progress/audio_length)
	end
end

function view_update_input()
	if input_num>0 then
		local tmp = input_num..""
		local tmp2 = tmp
		for i = 1,(4-#tmp) do
			tmp2 = "_" .. tmp2
		end
		tmp = string.sub(tmp2, 1, 1) .. " " .. string.sub(tmp2, 2, 2) .. " " .. string.sub(tmp2, 3, 3) .. " " .. string.sub(tmp2, 4, 4)
		input.text = tmp
	else
		input.text = "_ _ _ _"
	end
end

function onLanguageRowRender(event)
	local group = event.view
	local row = event.target
	local index = event.index
	local id = event.id

	-- TBD: event.id
	local text = display.newText((languages[index])[cfg.LANG_NAME_COL], 0, 0, native.systemFont, 18 )
	text:setReferencePoint( display.CenterLeftReferencePoint )
	text.y = row.height * 0.5
	text.x = 15
	text:setTextColor( 0 )

	-- must insert everything into event.view:
	group:insert( text )
end

function onObjectRowRender(event)
	local group = event.view
	local row = event.target
	local index = event.index
	local id = event.id

	-- TBD: event.id
	local text = display.newText((objects[index])[cfg.OBJ_NUM_COL] .. " " .. (objects[index])[cfg.OBJ_NAME_COL], 0, 0, native.systemFont, 18 )
	text:setReferencePoint( display.CenterLeftReferencePoint )
	text.y = row.height * 0.5
	text.x = 15
	text:setTextColor( 0 )

	-- must insert everything into event.view:
	group:insert( text )
end

function view_update_ui(skipObjects)
	if table_view then
		table_view:removeSelf()
		table_view = nil
	end
	if slider then
		slider:removeSelf()
		slider = nil
	end
	if not skipObjects and scrollView then
		scrollView:removeSelf()
		scrollView = nil
	end
	if ui then
		ui:removeSelf()
		ui = nil
	end
	ui = display.newGroup()

	if ui_mode == cfg.UI_MODE_NORMAL then
		local btn_exit = display.newImage(ui, "ui_exit.png", 11, 5)
		btn_exit:addEventListener("touch", onExitEvent)
		local btn_flag = display.newImage(ui, language[cfg.LANG_IMAGE_COL], 93, 5)
		btn_flag:addEventListener("touch", onFlagEvent)
		local btn_settings = display.newImage(ui,"ui_settings.png", 190, 5)
		btn_settings:addEventListener("touch", onSettingsEvent)
		local btn_help = display.newImage(ui, "ui_help.png", 272, 5)
		btn_help:addEventListener("touch", onHelpEvent)
		local btn_previous = display.newImage(ui, "ui_previous.png", 5, screen_height-53)
		btn_previous:addEventListener("touch", onPreviousEvent)
		if audio_state == cfg.AUDIO_STATE_PLAYING then
			local btn_play = display.newImage(ui, "ui_pause.png", 92, screen_height-53)
			btn_play:addEventListener("touch", onPauseEvent)
		else
			local btn_play = display.newImage(ui, "ui_play.png", 92, screen_height-53)
			btn_play:addEventListener("touch", onPlayEvent)
		end
		local btn_next = display.newImage(ui, "ui_next.png", 179, screen_height-53)
		btn_next:addEventListener("touch", onNextEvent)
		if cfg.FEATURE_SELECT_LIST > 0 then
			local btn_list = display.newImage(ui, "ui_list.png", 266 , screen_height-53)
			btn_list:addEventListener("touch", onListEvent)
		end
		if cfg.FEATURE_SELECT_INPUT > 0 then
			local btn_input = display.newImage(ui, "ui_input.png", 266 , screen_height-53)
			btn_input:addEventListener("touch", onInputEvent)
		end
		if cfg.FEATURE_SELECT_MAP > 0 then
			local btn_map = display.newImage(ui, "ui_map.png", 266 , screen_height-53)
			btn_map:addEventListener("touch", onMapEvent)
		end
		if cfg.FEATURE_SELECT_QR > 0 then
			local btn_qr = display.newImage(ui, "ui_qr.png", 266 , screen_height-53)
			btn_qr:addEventListener("touch", onQrEvent)
		end
		if cfg.FEATURE_SELECT_NFC > 0 then
			local btn_nfc = display.newImage(ui, "ui_nfc.png", 266 , screen_height-53)
			btn_nfc:addEventListener("touch", onNfcEvent)
		end
		if cfg.FEATURE_SELECT_AR > 0 then
			local btn_ar = display.newImage(ui, "ui_ar.png", 266 , screen_height-53)
			btn_ar:addEventListener("touch", onArEvent)
		end
		slider = widget.newSlider{ x = 160, y = 410, width=290, value = 0, callback=onTimeChange }
		view_update_progress()
		if not skipObjects then
			view_update_object()
		end
	elseif ui_mode == cfg.UI_MODE_HELP then
		local btn_cancel = display.newImage(ui,languages[language_num][cfg.LANG_HELP_IMAGE_COL], 0, 0)
		btn_cancel:addEventListener("touch", onCancelEvent)
	elseif ui_mode == cfg.UI_MODE_LANGUAGE then
		table_view = widget.newTableView{ height=392, width=320, maskFile="mask_list.png"}
		for k, tmp in ipairs(languages) do
			table_view:insertRow{id=k, onEvent=onSelectLanguage, onRender=onLanguageRowRender}
		end
		local btn_cancel = display.newImage(ui, "ui_cancel.png", 136, screen_height-68)
		btn_cancel:addEventListener("touch", onCancelEvent)
	elseif ui_mode == cfg.UI_MODE_LIST then
		table_view = widget.newTableView{ height=392, width=320, maskFile="mask_list.png"}
		for k, tmp in ipairs(objects) do
			table_view:insertRow{id=k, onEvent=onSelectObject, onRender=onObjectRowRender}
		end
		local btn_cancel = display.newImage(ui, "ui_cancel.png", 136, screen_height-68)
		btn_cancel:addEventListener("touch", onCancelEvent)
	elseif ui_mode == cfg.UI_MODE_INPUT then
		input = display.newText(ui, "_ _ _ _", 60, screen_height-460, "Courier", 48)
		input_num = 0
		local btn_1 = display.newImage(ui, "ui_1.png", 44, screen_height-358)
		btn_1.id = 1; btn_1:addEventListener("touch", onInputX)
		local btn_2 = display.newImage(ui, "ui_2.png", 136, screen_height-358)
		btn_2.id = 2; btn_2:addEventListener("touch", onInputX)
		local btn_3 = display.newImage(ui, "ui_3.png", 228, screen_height-358)
		btn_3.id = 3; btn_3:addEventListener("touch", onInputX)
		local btn_4 = display.newImage(ui, "ui_4.png", 44, screen_height-300)
		btn_4.id = 4; btn_4:addEventListener("touch", onInputX)
		local btn_5 = display.newImage(ui, "ui_5.png", 136, screen_height-300)
		btn_5.id = 5; btn_5:addEventListener("touch", onInputX)
		local btn_6 = display.newImage(ui, "ui_6.png", 228, screen_height-300)
		btn_6.id = 6; btn_6:addEventListener("touch", onInputX)
		local btn_7 = display.newImage(ui, "ui_7.png", 44, screen_height-242)
		btn_7.id = 7; btn_7:addEventListener("touch", onInputX)
		local btn_8 = display.newImage(ui, "ui_8.png", 136, screen_height-242)
		btn_8.id = 8; btn_8:addEventListener("touch", onInputX)
		local btn_9 = display.newImage(ui, "ui_9.png", 228, screen_height-242)
		btn_9.id = 9; btn_9:addEventListener("touch", onInputX)
		local btn_0 = display.newImage(ui, "ui_0.png", 136, screen_height-184)
		btn_0.id = 0; btn_0:addEventListener("touch", onInputX)
		local btn_delete = display.newImage(ui, "ui_delete.png", 228, screen_height-184)
		btn_delete:addEventListener("touch", onInputDelete)
		local btn_cancel = display.newImage(ui, "ui_cancel.png", 44, screen_height-84)
		btn_cancel:addEventListener("touch", onCancelEvent)
		local btn_ok = display.newImage(ui, "ui_ok.png", 228, screen_height-84)
		btn_ok:addEventListener("touch", onInputSelect)
	elseif ui_mode == cfg.UI_MODE_SETTINGS then
		local cap_volume = display.newText(ui, txt.TEXT_SETTING_VOLUME[language[cfg.LANG_KEY_COL]], 10, 60, native.systemFont, 16)
		slider = widget.newSlider{ x = 160, y = 110, width=290, value = lib.round(audio.getVolume() * 100) }
		local btn_cancel = display.newImage(ui, "ui_cancel.png", 44, screen_height-84)
		btn_cancel:addEventListener("touch", onCancelEvent)
		local btn_ok = display.newImage(ui, "ui_ok.png", 228, screen_height-84)
		btn_ok:addEventListener("touch", onSelectSettings)
	end
end

function view_init()
	bg = display.newImage("ui_bg.png")
	view_update_ui()
end
