local hud_sheet = {}


hud_sheet.imageData = love.image.newImageData('https://raw.githubusercontent.com/KashouC/darktheme/8b9cbf21a74a0472fcd31801fe057eaa5229de48/sheet.png')
hud_sheet.image = love.graphics.newImage(hud_sheet.imageData)
hud_sheet.image:setFilter('nearest', 'nearest')

hud_sheet.slices = {
    cursor_normal = { x = 80, y = 0, w = 16, h = 16, focusx = 0, focusy = 0 },
    cursor_normal_add = { x = 80, y = 16, w = 16, h = 16, focusx = 0, focusy = 0 },
    cursor_crosshair = { x = 96, y = 32, w = 16, h = 16, focusx = 7, focusy = 7 },
    cursor_forbidden = { x = 80, y = 32, w = 16, h = 16, focusx = 0, focusy = 0 },
    cursor_hand = { x = 80, y = 48, w = 16, h = 16, focusx = 5, focusy = 3 },
    cursor_scroll = { x = 80, y = 64, w = 16, h = 16, focusx = 8, focusy = 8 },
    cursor_move = { x = 80, y = 80, w = 16, h = 16, focusx = 0, focusy = 0 },
    cursor_move_selection = { x = 96, y = 80, w = 16, h = 16, focusx = 0, focusy = 0 },
    cursor_size_ns = { x = 80, y = 112, w = 16, h = 16, focusx = 8, focusy = 8 },
    cursor_size_we = { x = 80, y = 144, w = 16, h = 16, focusx = 8, focusy = 8 },
    cursor_size_n = { x = 80, y = 112, w = 16, h = 16, focusx = 8, focusy = 8 },
    cursor_size_ne = { x = 80, y = 128, w = 16, h = 16, focusx = 8, focusy = 8 },
    cursor_size_e = { x = 80, y = 160, w = 16, h = 16, focusx = 8, focusy = 8 },
    cursor_size_se = { x = 80, y = 208, w = 16, h = 16, focusx = 8, focusy = 8 },
    cursor_size_s = { x = 80, y = 192, w = 16, h = 16, focusx = 8, focusy = 8 },
    cursor_size_sw = { x = 80, y = 176, w = 16, h = 16, focusx = 8, focusy = 8 },
    cursor_size_w = { x = 80, y = 144, w = 16, h = 16, focusx = 8, focusy = 8 },
    cursor_size_nw = { x = 80, y = 96, w = 16, h = 16, focusx = 8, focusy = 8 },
    cursor_rotate_n = { x = 240, y = 192, w = 16, h = 16, focusx = 8, focusy = 8 },
    cursor_rotate_ne = { x = 256, y = 160, w = 16, h = 16, focusx = 8, focusy = 8 },
    cursor_rotate_e = { x = 256, y = 176, w = 16, h = 16, focusx = 8, focusy = 8 },
    cursor_rotate_se = { x = 256, y = 208, w = 16, h = 16, focusx = 8, focusy = 8 },
    cursor_rotate_s = { x = 256, y = 192, w = 16, h = 16, focusx = 8, focusy = 8 },
    cursor_rotate_sw = { x = 240, y = 208, w = 16, h = 16, focusx = 8, focusy = 8 },
    cursor_rotate_w = { x = 240, y = 176, w = 16, h = 16, focusx = 8, focusy = 8 },
    cursor_rotate_nw = { x = 240, y = 160, w = 16, h = 16, focusx = 8, focusy = 8 },
    cursor_eyedropper = { x = 80, y = 224, w = 16, h = 16, focusx = 0, focusy = 15 },
    cursor_magnifier = { x = 80, y = 240, w = 16, h = 16, focusx = 5, focusy = 5 },
    radio_normal = { x = 64, y = 64, w = 8, h = 8 },
    radio_selected = { x = 64, y = 80, w = 8, h = 8 },
    radio_disabled = { x = 64, y = 64, w = 8, h = 8 },
    check_normal = { x = 48, y = 64, w = 8, h = 8 },
    check_selected = { x = 48, y = 80, w = 8, h = 8 },
    check_disabled = { x = 48, y = 64, w = 8, h = 8 },
    check_focus = { x = 32, y = 64, w1 = 2, w2 = 6, w3 = 2, h1 = 2, h2 = 6, h3 = 2 },
    radio_focus = { x = 32, y = 64, w1 = 2, w2 = 6, w3 = 2, h1 = 2, h2 = 6, h3 = 2 },
    button_normal = { x = 48, y = 0, w1 = 4, w2 = 6, w3 = 4, h1 = 4, h2 = 6, h3 = 6 },
    button_hot = { x = 64, y = 0, w1 = 4, w2 = 6, w3 = 4, h1 = 4, h2 = 6, h3 = 6 },
    button_focused = { x = 48, y = 16, w1 = 4, w2 = 6, w3 = 4, h1 = 4, h2 = 6, h3 = 6 },
    button_selected = { x = 64, y = 16, w1 = 4, w2 = 6, w3 = 4, h1 = 4, h2 = 6, h3 = 6 },
    sunken_normal = { x = 0, y = 32, w1 = 4, w2 = 4, w3 = 4, h1 = 4, h2 = 4, h3 = 4 },
    sunken_focused = { x = 0, y = 48, w1 = 4, w2 = 4, w3 = 4, h1 = 4, h2 = 4, h3 = 4 },
    sunken2_normal = { x = 0, y = 64, w1 = 5, w2 = 6, w3 = 5, h1 = 5, h2 = 6, h3 = 5 },
    sunken2_focused = { x = 0, y = 80, w1 = 5, w2 = 6, w3 = 5, h1 = 5, h2 = 6, h3 = 5 },
    sunken_mini_normal = { x = 16, y = 64, w1 = 4, w2 = 4, w3 = 4, h1 = 3, h2 = 6, h3 = 3 },
    sunken_mini_focused = { x = 16, y = 80, w1 = 4, w2 = 4, w3 = 4, h1 = 3, h2 = 6, h3 = 3 },
    window = { x = 0, y = 0, w1 = 3, w2 = 7, w3 = 3, h1 = 15, h2 = 4, h3 = 5 },
    menu = { x = 0, y = 96, w1 = 3, w2 = 10, w3 = 3, h1 = 3, h2 = 9, h3 = 4 },
    window_button_normal = { x = 16, y = 0, w = 9, h = 11 },
    window_button_hot = { x = 25, y = 0, w = 9, h = 11 },
    window_button_selected = { x = 34, y = 0, w = 9, h = 11 },
    window_close_icon = { x = 16, y = 11, w = 5, h = 6 },
    window_play_icon = { x = 21, y = 11, w = 5, h = 6 },
    window_stop_icon = { x = 26, y = 11, w = 5, h = 6 },
    window_center_icon = { x = 31, y = 11, w = 5, h = 6 },
    slider_full = { x = 0, y = 144, w1 = 5, w2 = 6, w3 = 5, h1 = 5, h2 = 5, h3 = 6 },
    slider_empty = { x = 16, y = 144, w1 = 5, w2 = 6, w3 = 5, h1 = 5, h2 = 5, h3 = 6 },
    slider_full_focused = { x = 0, y = 160, w1 = 5, w2 = 6, w3 = 5, h1 = 5, h2 = 5, h3 = 6 },
    slider_empty_focused = { x = 16, y = 160, w1 = 5, w2 = 6, w3 = 5, h1 = 5, h2 = 5, h3 = 6 },
    mini_slider_full = { x = 32, y = 144, w1 = 2, w2 = 12, w3 = 2, h1 = 2, h2 = 11, h3 = 3 },
    mini_slider_empty = { x = 48, y = 144, w1 = 2, w2 = 12, w3 = 2, h1 = 2, h2 = 11, h3 = 3 },
    mini_slider_full_focused = { x = 32, y = 160, w1 = 2, w2 = 12, w3 = 2, h1 = 2, h2 = 11, h3 = 3 },
    mini_slider_empty_focused = { x = 48, y = 160, w1 = 2, w2 = 12, w3 = 2, h1 = 2, h2 = 11, h3 = 3 },
    mini_slider_thumb = { x = 32, y = 176, w = 5, h = 4 },
    mini_slider_thumb_focused = { x = 48, y = 176, w = 5, h = 4 },
    separator_horz = { x = 32, y = 80, w = 9, h = 5 },
    separator_vert = { x = 32, y = 96, w = 5, h = 9 },
    combobox_arrow_down = { x = 100, y = 148, w = 9, h = 9 },
    combobox_arrow_down_selected = { x = 116, y = 148, w = 9, h = 9 },
    combobox_arrow_down_disabled = { x = 132, y = 148, w = 9, h = 9 },
    combobox_arrow_up = { x = 100, y = 163, w = 9, h = 9 },
    combobox_arrow_up_selected = { x = 116, y = 163, w = 9, h = 9 },
    combobox_arrow_up_disabled = { x = 132, y = 163, w = 9, h = 9 },
    combobox_arrow_left = { x = 99, y = 180, w = 9, h = 9 },
    combobox_arrow_left_selected = { x = 115, y = 180, w = 9, h = 9 },
    combobox_arrow_left_disabled = { x = 131, y = 180, w = 9, h = 9 },
    combobox_arrow_right = { x = 99, y = 196, w = 9, h = 9 },
    combobox_arrow_right_selected = { x = 115, y = 196, w = 9, h = 9 },
    combobox_arrow_right_disabled = { x = 131, y = 196, w = 9, h = 9 },
    newfolder = { x = 99, y = 211, w = 9, h = 9 },
    newfolder_selected = { x = 115, y = 211, w = 9, h = 9 },
    toolbutton_normal = { x = 96, y = 0, w1 = 3, w2 = 10, w3 = 3, h1 = 3, h2 = 9, h3 = 4 },
    toolbutton_hot = { x = 128, y = 0, w1 = 3, w2 = 10, w3 = 3, h1 = 3, h2 = 9, h3 = 4 },
    toolbutton_last = { x = 96, y = 16, w1 = 3, w2 = 10, w3 = 3, h1 = 3, h2 = 9, h3 = 4 },
    toolbutton_pushed = { x = 112, y = 16, w1 = 3, w2 = 10, w3 = 3, h1 = 3, h2 = 9, h3 = 4 },
    toolbutton_hot_focused = { x = 128, y = 0, w1 = 3, w2 = 10, w3 = 3, h1 = 3, h2 = 9, h3 = 4 },
    toolbutton_focused = { x = 128, y = 16, w1 = 3, w2 = 10, w3 = 3, h1 = 3, h2 = 9, h3 = 4 },
    tab_normal = { x = 2, y = 112, w1 = 4, w2 = 5, w3 = 5, h1 = 4, h2 = 6, h3 = 2 },
    tab_active = { x = 16, y = 112, w1 = 4, w2 = 7, w3 = 5, h1 = 4, h2 = 6, h3 = 2 },
    tab_bottom_active = { x = 16, y = 124, w1 = 4, w2 = 7, w3 = 5, h1 = 2, h2 = 1, h3 = 2 },
    tab_bottom_normal = { x = 2, y = 124, w = 12, h = 5 },
    tab_filler = { x = 0, y = 112, w = 2, h = 12 },
    tab_modified_icon_normal = { x = 32, y = 112, w = 5, h = 5 },
    tab_modified_icon_active = { x = 32, y = 117, w = 5, h = 5 },
    tab_close_icon_normal = { x = 37, y = 112, w = 5, h = 5 },
    tab_close_icon_active = { x = 37, y = 117, w = 5, h = 5 },
    tab_icon_bg_clicked = { x = 42, y = 112, w = 14, h = 12 },
    tab_icon_bg_hover = { x = 56, y = 112, w = 14, h = 12 },
    tab_home_icon_normal = { x = 32, y = 240, w = 7, h = 8 },
    tab_home_icon_active = { x = 40, y = 240, w = 7, h = 8 },
    editor_normal = { x = 40, y = 96, w1 = 3, w2 = 10, w3 = 3, h1 = 3, h2 = 10, h3 = 3 },
    editor_selected = { x = 56, y = 96, w1 = 3, w2 = 10, w3 = 3, h1 = 3, h2 = 10, h3 = 3 },
    colorbar_0 = { x = 0, y = 192, w1 = 5, w2 = 6, w3 = 5, h1 = 5, h2 = 6, h3 = 5 },
    colorbar_1 = { x = 16, y = 192, w1 = 5, w2 = 6, w3 = 5, h1 = 5, h2 = 6, h3 = 5 },
    colorbar_2 = { x = 0, y = 208, w1 = 5, w2 = 6, w3 = 5, h1 = 5, h2 = 6, h3 = 5 },
    colorbar_3 = { x = 16, y = 208, w1 = 5, w2 = 6, w3 = 5, h1 = 5, h2 = 6, h3 = 5 },
    colorbar_selection_hot = { x = 0, y = 224, w1 = 5, w2 = 6, w3 = 5, h1 = 5, h2 = 6, h3 = 5 },
    colorbar_selection = { x = 16, y = 224, w1 = 5, w2 = 6, w3 = 5, h1 = 5, h2 = 6, h3 = 5 },
    scrollbar_bg = { x = 64, y = 144, w1 = 5, w2 = 6, w3 = 5, h1 = 5, h2 = 6, h3 = 5 },
    scrollbar_thumb = { x = 64, y = 160, w1 = 5, w2 = 6, w3 = 5, h1 = 5, h2 = 6, h3 = 5 },
    mini_scrollbar_bg = { x = 64, y = 176, w1 = 3, w2 = 2, w3 = 3, h1 = 3, h2 = 2, h3 = 3 },
    mini_scrollbar_thumb = { x = 72, y = 176, w1 = 3, w2 = 2, w3 = 3, h1 = 3, h2 = 2, h3 = 3 },
    mini_scrollbar_bg_hot = { x = 64, y = 184, w1 = 3, w2 = 2, w3 = 3, h1 = 3, h2 = 2, h3 = 3 },
    mini_scrollbar_thumb_hot = { x = 72, y = 184, w1 = 3, w2 = 2, w3 = 3, h1 = 3, h2 = 2, h3 = 3 },
    transparent_scrollbar_bg = { x = 64, y = 192, w1 = 3, w2 = 2, w3 = 3, h1 = 3, h2 = 2, h3 = 3 },
    transparent_scrollbar_thumb = { x = 72, y = 192, w1 = 3, w2 = 2, w3 = 3, h1 = 3, h2 = 2, h3 = 3 },
    transparent_scrollbar_bg_hot = { x = 64, y = 200, w1 = 3, w2 = 2, w3 = 3, h1 = 3, h2 = 2, h3 = 3 },
    transparent_scrollbar_thumb_hot = { x = 72, y = 200, w1 = 3, w2 = 2, w3 = 3, h1 = 3, h2 = 2, h3 = 3 },
    tooltip = { x = 112, y = 64, w1 = 5, w2 = 6, w3 = 5, h1 = 5, h2 = 5, h3 = 6 },
    tooltip_arrow = { x = 128, y = 64, w1 = 5, w2 = 6, w3 = 5, h1 = 5, h2 = 5, h3 = 6 },
    ani_first = { x = 144, y = 192, w = 5, h = 5 },
    ani_previous = { x = 152, y = 192, w = 5, h = 5 },
    ani_play = { x = 160, y = 192, w = 5, h = 5 },
    ani_stop = { x = 168, y = 192, w = 5, h = 5 },
    ani_next = { x = 176, y = 192, w = 5, h = 5 },
    ani_last = { x = 184, y = 192, w = 5, h = 5 },
    pal_edit = { x = 144, y = 200, w = 5, h = 5 },
    pal_sort = { x = 152, y = 200, w = 5, h = 5 },
    pal_presets = { x = 160, y = 200, w = 5, h = 5 },
    pal_options = { x = 168, y = 200, w = 5, h = 5 },
    pal_resize = { x = 176, y = 200, w = 5, h = 5 },
    target_one = { x = 144, y = 224, w = 32, h = 16 },
    target_frames = { x = 176, y = 224, w = 32, h = 16 },
    target_layers = { x = 208, y = 224, w = 32, h = 16 },
    target_frames_layers = { x = 240, y = 224, w = 32, h = 16 },
    selection_replace = { x = 176, y = 160, w = 7, h = 7 },
    selection_add = { x = 184, y = 160, w = 7, h = 7 },
    selection_subtract = { x = 192, y = 160, w = 7, h = 7 },
    unpinned = { x = 192, y = 144, w = 8, h = 8 },
    pinned = { x = 200, y = 144, w = 8, h = 8 },
    drop_down_button_left_normal = { x = 48, y = 32, w1 = 3, w2 = 2, w3 = 3, h1 = 4, h2 = 6, h3 = 6 },
    drop_down_button_left_hot = { x = 64, y = 32, w1 = 3, w2 = 2, w3 = 3, h1 = 4, h2 = 6, h3 = 6 },
    drop_down_button_left_focused = { x = 48, y = 48, w1 = 3, w2 = 2, w3 = 3, h1 = 4, h2 = 6, h3 = 6 },
    drop_down_button_left_selected = { x = 64, y = 48, w1 = 3, w2 = 2, w3 = 3, h1 = 4, h2 = 6, h3 = 6 },
    drop_down_button_right_normal = { x = 56, y = 32, w1 = 2, w2 = 1, w3 = 3, h1 = 4, h2 = 6, h3 = 6 },
    drop_down_button_right_hot = { x = 72, y = 32, w1 = 2, w2 = 1, w3 = 3, h1 = 4, h2 = 6, h3 = 6 },
    drop_down_button_right_focused = { x = 55, y = 48, w1 = 2, w2 = 2, w3 = 3, h1 = 4, h2 = 6, h3 = 6 },
    drop_down_button_right_selected = { x = 71, y = 48, w1 = 2, w2 = 2, w3 = 3, h1 = 4, h2 = 6, h3 = 6 },
    transformation_handle = { x = 208, y = 144, w = 5, h = 5 },
    pivot_handle = { x = 224, y = 144, w = 9, h = 9 },
    timeline_none = { x = 228, y = 0, w1 = 2, w2 = 8, w3 = 2, h1 = 2, h2 = 8, h3 = 2 },
    timeline_normal = { x = 240, y = 0, w1 = 2, w2 = 8, w3 = 2, h1 = 2, h2 = 8, h3 = 2 },
    timeline_active = { x = 252, y = 0, w1 = 2, w2 = 8, w3 = 2, h1 = 2, h2 = 8, h3 = 2 },
    timeline_hover = { x = 264, y = 0, w1 = 2, w2 = 8, w3 = 2, h1 = 2, h2 = 8, h3 = 2 },
    timeline_active_hover = { x = 276, y = 0, w1 = 2, w2 = 8, w3 = 2, h1 = 2, h2 = 8, h3 = 2 },
    timeline_clicked = { x = 288, y = 0, w1 = 2, w2 = 8, w3 = 2, h1 = 2, h2 = 8, h3 = 2 },
    timeline_open_eye_normal = { x = 240, y = 12, w = 12, h = 12 },
    timeline_open_eye_active = { x = 252, y = 12, w = 12, h = 12 },
    timeline_closed_eye_normal = { x = 240, y = 24, w = 12, h = 12 },
    timeline_closed_eye_active = { x = 252, y = 24, w = 12, h = 12 },
    timeline_open_padlock_normal = { x = 240, y = 36, w = 12, h = 12 },
    timeline_open_padlock_active = { x = 252, y = 36, w = 12, h = 12 },
    timeline_closed_padlock_normal = { x = 240, y = 48, w = 12, h = 12 },
    timeline_closed_padlock_active = { x = 252, y = 48, w = 12, h = 12 },
    timeline_continuous_normal = { x = 276, y = 36, w = 12, h = 12 },
    timeline_continuous_active = { x = 288, y = 36, w = 12, h = 12 },
    timeline_discontinuous_normal = { x = 276, y = 48, w = 12, h = 12 },
    timeline_discontinuous_active = { x = 288, y = 48, w = 12, h = 12 },
    timeline_closed_group_normal = { x = 276, y = 60, w = 12, h = 12 },
    timeline_closed_group_active = { x = 288, y = 60, w = 12, h = 12 },
    timeline_open_group_normal = { x = 276, y = 72, w = 12, h = 12 },
    timeline_open_group_active = { x = 288, y = 72, w = 12, h = 12 },
    timeline_empty_frame_normal = { x = 240, y = 60, w = 12, h = 12 },
    timeline_empty_frame_active = { x = 252, y = 60, w = 12, h = 12 },
    timeline_keyframe_normal = { x = 240, y = 72, w = 12, h = 12 },
    timeline_keyframe_active = { x = 252, y = 72, w = 12, h = 12 },
    timeline_from_left_normal = { x = 240, y = 84, w = 12, h = 12 },
    timeline_from_left_active = { x = 252, y = 84, w = 12, h = 12 },
    timeline_from_right_normal = { x = 240, y = 96, w = 12, h = 12 },
    timeline_from_right_active = { x = 252, y = 96, w = 12, h = 12 },
    timeline_from_both_normal = { x = 240, y = 108, w = 12, h = 12 },
    timeline_from_both_active = { x = 252, y = 108, w = 12, h = 12 },
    timeline_left_link_active = { x = 264, y = 84, w = 12, h = 12 },
    timeline_both_links_active = { x = 264, y = 96, w = 12, h = 12 },
    timeline_right_link_active = { x = 264, y = 108, w = 12, h = 12 },
    timeline_gear = { x = 264, y = 12, w = 12, h = 12 },
    timeline_gear_active = { x = 264, y = 24, w = 12, h = 12 },
    timeline_onionskin = { x = 264, y = 36, w = 12, h = 12 },
    timeline_onionskin_active = { x = 264, y = 48, w = 12, h = 12 },
    timeline_onionskin_range = { x = 240, y = 120, w1 = 3, w2 = 6, w3 = 3, h1 = 3, h2 = 6, h3 = 3 },
    timeline_padding = { x = 276, y = 12, w1 = 1, w2 = 10, w3 = 1, h1 = 1, h2 = 10, h3 = 1 },
    timeline_padding_tr = { x = 288, y = 12, w1 = 1, w2 = 10, w3 = 1, h1 = 1, h2 = 10, h3 = 1 },
    timeline_padding_bl = { x = 276, y = 24, w1 = 1, w2 = 10, w3 = 1, h1 = 1, h2 = 10, h3 = 1 },
    timeline_padding_br = { x = 288, y = 24, w1 = 1, w2 = 10, w3 = 1, h1 = 1, h2 = 10, h3 = 1 },
    timeline_drop_layer_deco = { x = 252, y = 127, w1 = 3, w2 = 1, w3 = 3, h1 = 2, h2 = 1, h3 = 2 },
    timeline_drop_frame_deco = { x = 252, y = 120, w1 = 2, w2 = 1, w3 = 2, h1 = 3, h2 = 1, h3 = 3 },
    timeline_loop_range = { x = 240, y = 132, w1 = 4, w2 = 4, w3 = 4, h1 = 3, h2 = 6, h3 = 3 },
    flag_normal = { x = 0, y = 240, w = 16, h = 10 },
    flag_highlight = { x = 16, y = 240, w = 16, h = 10 },
    drop_pixels_ok = { x = 176, y = 176, w = 7, h = 8 },
    drop_pixels_ok_selected = { x = 176, y = 184, w = 7, h = 8 },
    drop_pixels_cancel = { x = 192, y = 176, w = 7, h = 8 },
    drop_pixels_cancel_selected = { x = 192, y = 184, w = 7, h = 8 },
    warning_box = { x = 112, y = 80, w = 9, h = 10 },
    canvas_nw = { x = 96, y = 96, w = 16, h = 16 },
    canvas_n = { x = 112, y = 96, w = 16, h = 16 },
    canvas_ne = { x = 128, y = 96, w = 16, h = 16 },
    canvas_w = { x = 96, y = 112, w = 16, h = 16 },
    canvas_c = { x = 112, y = 112, w = 16, h = 16 },
    canvas_e = { x = 128, y = 112, w = 16, h = 16 },
    canvas_sw = { x = 96, y = 128, w = 16, h = 16 },
    canvas_s = { x = 112, y = 128, w = 16, h = 16 },
    canvas_se = { x = 128, y = 128, w = 16, h = 16 },
    canvas_empty = { x = 96, y = 96, w = 1, h = 1 },
    ink_simple = { x = 144, y = 144, w = 16, h = 16 },
    ink_alpha_compositing = { x = 160, y = 144, w = 16, h = 16 },
    ink_copy_color = { x = 144, y = 160, w = 16, h = 16 },
    ink_lock_alpha = { x = 160, y = 160, w = 16, h = 16 },
    ink_shading = { x = 144, y = 176, w = 16, h = 16 },
    selection_opaque = { x = 208, y = 176, w = 16, h = 10 },
    selection_masked = { x = 224, y = 176, w = 16, h = 10 },
    pivot_northwest = { x = 208, y = 192, w = 7, h = 7 },
    pivot_north = { x = 216, y = 192, w = 7, h = 7 },
    pivot_northeast = { x = 224, y = 192, w = 7, h = 7 },
    pivot_west = { x = 208, y = 200, w = 7, h = 7 },
    pivot_center = { x = 216, y = 200, w = 7, h = 7 },
    pivot_east = { x = 224, y = 200, w = 7, h = 7 },
    pivot_southwest = { x = 208, y = 208, w = 7, h = 7 },
    pivot_south = { x = 216, y = 208, w = 7, h = 7 },
    pivot_southeast = { x = 224, y = 208, w = 7, h = 7 },
    icon_rgb = { x = 0, y = 256, w = 16, h = 16 },
    icon_grayscale = { x = 16, y = 256, w = 16, h = 16 },
    icon_indexed = { x = 32, y = 256, w = 16, h = 16 },
    icon_black = { x = 48, y = 256, w = 16, h = 16 },
    icon_white = { x = 64, y = 256, w = 16, h = 16 },
    icon_transparent = { x = 80, y = 256, w = 16, h = 16 },
    color_wheel_indicator = { x = 48, y = 192, w = 4, h = 4 },
    no_symmetry = { x = 144, y = 240, w = 13, h = 13 },
    horizontal_symmetry = { x = 160, y = 240, w = 13, h = 13 },
    vertical_symmetry = { x = 176, y = 240, w = 13, h = 13 },
    icon_arrow_down = { x = 144, y = 256, w = 7, h = 4 },
    icon_close = { x = 152, y = 256, w = 7, h = 7 },
    icon_search = { x = 160, y = 256, w = 8, h = 8 },
    icon_user_data = { x = 168, y = 256, w = 8, h = 8 },
    icon_pos = { x = 144, y = 264, w = 8, h = 8 },
    icon_size = { x = 152, y = 264, w = 8, h = 8 },
    icon_selsize = { x = 160, y = 264, w = 8, h = 8 },
    icon_frame = { x = 168, y = 264, w = 8, h = 8 },
    icon_clock = { x = 176, y = 264, w = 8, h = 8 },
    icon_start = { x = 184, y = 264, w = 8, h = 8 },
    icon_end = { x = 192, y = 264, w = 8, h = 8 },
    icon_angle = { x = 200, y = 264, w = 8, h = 8 },
    icon_key = { x = 208, y = 264, w = 8, h = 8 },
    icon_distance = { x = 216, y = 264, w = 8, h = 8 },
    icon_grid = { x = 224, y = 264, w = 8, h = 8 },
    icon_save = { x = 232, y = 264, w = 8, h = 8 },
    icon_save_small = { x = 240, y = 264, w = 8, h = 8 },
    icon_slice = { x = 248, y = 264, w = 8, h = 8 },
    tool_rectangular_marquee = { x = 144, y = 0, w = 16, h = 16 },
    tool_elliptical_marquee = { x = 160, y = 0, w = 16, h = 16 },
    tool_lasso = { x = 176, y = 0, w = 16, h = 16 },
    tool_polygonal_lasso = { x = 192, y = 0, w = 16, h = 16 },
    tool_magic_wand = { x = 208, y = 0, w = 16, h = 16 },
    tool_pencil = { x = 144, y = 16, w = 16, h = 16 },
    tool_spray = { x = 160, y = 16, w = 16, h = 16 },
    tool_eraser = { x = 144, y = 32, w = 16, h = 16 },
    tool_eyedropper = { x = 160, y = 32, w = 16, h = 16 },
    tool_hand = { x = 176, y = 32, w = 16, h = 16 },
    tool_move = { x = 192, y = 32, w = 16, h = 16 },
    tool_zoom = { x = 208, y = 32, w = 16, h = 16 },
    tool_slice = { x = 224, y = 32, w = 16, h = 16 },
    tool_paint_bucket = { x = 144, y = 48, w = 16, h = 16 },
    tool_line = { x = 144, y = 64, w = 16, h = 16 },
    tool_curve = { x = 160, y = 64, w = 16, h = 16 },
    tool_rectangle = { x = 144, y = 80, w = 16, h = 16 },
    tool_filled_rectangle = { x = 160, y = 80, w = 16, h = 16 },
    tool_ellipse = { x = 176, y = 80, w = 16, h = 16 },
    tool_filled_ellipse = { x = 192, y = 80, w = 16, h = 16 },
    tool_contour = { x = 144, y = 96, w = 16, h = 16 },
    tool_polygon = { x = 160, y = 96, w = 16, h = 16 },
    tool_blur = { x = 160, y = 112, w = 16, h = 16 },
    tool_jumble = { x = 176, y = 112, w = 16, h = 16 },
    tool_configuration = { x = 144, y = 128, w = 16, h = 16 },
    tool_minieditor = { x = 160, y = 128, w = 16, h = 16 },
    simple_color_border = { x = 16, y = 32, w1 = 3, w2 = 6, w3 = 3, h1 = 3, h2 = 6, h3 = 3 },
    simple_color_selected = { x = 32, y = 32, w1 = 3, w2 = 6, w3 = 3, h1 = 3, h2 = 6, h3 = 3 },
}

do
    local CURSOR_SCALE = 1

    local W, H = hud_sheet.image:getDimensions()
    for sliceName, slice in pairs(hud_sheet.slices) do
        slice.quads = {}
        if slice.focusx then -- Cursor
            local imageData = love.image.newImageData(CURSOR_SCALE * slice.w, CURSOR_SCALE * slice.h)
            for i = 0, CURSOR_SCALE * slice.w - 1 do
                for j = 0, CURSOR_SCALE * slice.h - 1 do
                    local sourceI, sourceJ = slice.x + math.floor(i / CURSOR_SCALE), slice.y + math.floor(j / CURSOR_SCALE)
                    imageData:setPixel(i, j, hud_sheet.imageData:getPixel(sourceI, sourceJ))
                end
            end
            slice.cursor = love.mouse.newCursor(imageData, slice.focusx, slice.focusy)
        elseif slice.w then -- Single quad
            slice.quads.single = love.graphics.newQuad(slice.x, slice.y, slice.w, slice.h, W, H)
        elseif slice.w1 then -- 3x3 quads
            local x, y, w1, w2, w3, h1, h2, h3 = slice.x, slice.y, slice.w1, slice.w2, slice.w3, slice.h1, slice.h2, slice.h3
            slice.quads.top_left = love.graphics.newQuad(x, y, w1, h1, W, H)
            slice.quads.top = love.graphics.newQuad(x + w1, y, w2, h1, W, H)
            slice.quads.top_right = love.graphics.newQuad(x + w1 + w2, y, w3, h1, W, H)
            slice.quads.right = love.graphics.newQuad(x + w1 + w2, y + h1, w3, h2, W, H)
            slice.quads.bottom_right = love.graphics.newQuad(x + w1 + w2, y + h1 + h2, w3, h3, W, H)
            slice.quads.bottom = love.graphics.newQuad(x + w1, y + h1 + h2, w2, h3, W, H)
            slice.quads.bottom_left = love.graphics.newQuad(x, y + h1 + h2, w1, h3, W, H)
            slice.quads.left = love.graphics.newQuad(x, y + h1, w1, h2, W, H)
            slice.quads.middle = love.graphics.newQuad(x + w1 - 1, y + h1 - 1, 1, 1, W, H)
        end
    end
end


return hud_sheet