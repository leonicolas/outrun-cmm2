sub process_input()
    local ctrl% = read_keyboard%()

    if ctrl% and CTRL_LEFT then
        'inc g_dist_to_player,-1
        inc g_pos_x
    elseif ctrl% and CTRL_RIGHT then
        'inc g_dist_to_player, 1
        inc g_pos_x,-1
    endif
    if ctrl% and CTRL_UP then
        'inc g_camera(1), 1
        inc g_pos_y
    elseif ctrl% and CTRL_DOWN then
        'inc g_camera(1),-1
        inc g_pos_y,-1
    endif
end sub

function read_keyboard%()
    if not keydown(0) then exit function
    local i%
    for i% = 1 to 3
        if not keydown(i%) then continue for
        select case keydown(i%)
        case KB_ESC
            page write 0: cls 0
            end
        case KB_UP
            read_keyboard% = read_keyboard% or CTRL_UP
        case KB_DOWN
            read_keyboard% = read_keyboard% or CTRL_DOWN
        case KB_LEFT
            read_keyboard% = read_keyboard% or CTRL_LEFT
        case KB_RIGHT
            read_keyboard% = read_keyboard% or CTRL_RIGHT
        end select
    next
end function
