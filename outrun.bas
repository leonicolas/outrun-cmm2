option explicit
option base 0
option angle degrees
option default float

dim g_pos_x=0, g_pos_y=130

#include "constants.inc"
#include "input.inc"

const GAME_TICK_MS=1000/500 ' Temporary FPS cap for testing
const SCREEN_CX=mm.hres/2
const SCREEN_CY=mm.vres/3*2

const ROAD_WIDTH=mm.hres
const LANE_WIDTH=12
const RUMBLE_WIDTH=6
const SEGMENT_LENGTH=300

const SCREEN_SEGMENTS=16

dim g_tick
dim g_dist_to_player=160
' Camera: x, y, z, distance to projection plane
dim g_camera(3)=(0,120,-g_dist_to_player,0)
g_camera(3)=1/(g_camera(1)/g_dist_to_player)
' Segment: World x, y, z | road colour | off road colour
dim g_segments(100-1, 7)
dim g_curr_segment%=0

init()
load_road()
run_stage()

sub init()
    mode 7,12,rgb(0,146,251) ' 320x240
    font 7
    ' Clear pages
    page write 0: cls rgb(0,146,251)
    page write 1: cls 0
    page write 2: cls 0
end sub

sub load_road()
    local i%
    for i%=0 to bound(g_segments())
        g_segments(i%, 0)=0
        g_segments(i%, 1)=0
        g_segments(i%, 2)=i% * SEGMENT_LENGTH
        g_segments(i%, 3)=choice(i% mod 2, rgb(146,146,146), rgb(154,154,154)) ' Road colour
        g_segments(i%, 4)=choice(i% mod 2, rgb(227,211,195), rgb(235,219,203)) ' Off road colour
        g_segments(i%, 5)=choice(i% mod 2, rgb(255,255,255), 0) ' Lane colour
        g_segments(i%, 6)=choice(i% mod 2, rgb(146,146,146), rgb(255,255,255)) ' Rumble strip colour
        g_segments(i%, 7)=3 ' Number of lanes
    next i%
end sub

sub run_stage()
    local prev_frame_timer, delta_time

    load_stage()

    do
        if timer - prev_frame_timer < GAME_TICK_MS then continue do
        delta_time=(timer-prev_frame_timer)/1000
        prev_frame_timer=timer: inc g_tick

        update(delta_time)
        render(delta_time)
    loop

    close_stage()
end sub

sub load_stage()
    ' Load page 3
    page write 3: cls 0
    load png PLAYER_CAR_DIR+"c1.png",,,0

    ' Load framebuffer
    framebuffer create 1600,mm.vres
    page write framebuffer: cls 0
    load png MAP_DIR+"back.png",,,0
end sub

sub close_stage()
    framebuffer close
end sub

sub update(delta_time)
    process_input()
    g_camera(3)=1/(g_camera(1)/g_dist_to_player)
end sub

sub render(delta_time)
    local i%, prev_seg_proj(2), curr_seg_proj(2)

    'cls rgb(0,146,251) ' Clear screen buffer

    ' Render background
    blit 1000,0, 0,23, mm.hres,143,framebuffer,&b100
    blit 750,145, 0,160, mm.hres,16,framebuffer,&b100

    ' Render segments
    for i%=1 to SCREEN_SEGMENTS
        if g_segments(i%,1) > mm.vres then continue for
        project_segment(i%-1, prev_seg_proj())
        project_segment(i%, curr_seg_proj())

        draw_segment(prev_seg_proj(), curr_seg_proj(), i%)
    next i%

    ' Stats
    print @(0,2)  "FPS: "+str$(int(1/delta_time))
    ' print @(0,8)  "X : "+str$(g_pos_x)
    ' print @(0,16) "Y: "+str$(g_pos_y)

    ' Player car
    blit 0,0, 110,193, 94,44,3,&b100

    ' Render buffer to screen
    page write 1: blit 1,1, 1,1, mm.hres-2,mm.vres-2, 2
    page write 2
end sub

sub project_segment(ix%, projection())
    ' World coordinates to camera coordinates
    local translated_x=g_segments(ix%, 0)-g_camera(0)
    local translated_y=g_segments(ix%, 1)-g_camera(1)
    local translated_z=g_segments(ix%, 2)-g_camera(2)
    ' Scale factor based on camera depth
    local scale= g_camera(3)/translated_z
    ' Projected screen coordinates
    projection(0)=cint((1+scale*translated_x)*SCREEN_CX)
    projection(1)=cint((1-scale*translated_y)*SCREEN_CY)
    projection(2)=cint(scale*ROAD_WIDTH*SCREEN_CX)
end sub

sub draw_segment(prev_seg_proj(), curr_seg_proj(), ix%)
    local x(3), y(3)
    local x1=prev_seg_proj(0), y1=prev_seg_proj(1), w1=prev_seg_proj(2)
    local x2=curr_seg_proj(0), y2=curr_seg_proj(1), w2=curr_seg_proj(2)
    local rw1=w1/RUMBLE_WIDTH, rw2=w2/RUMBLE_WIDTH

    ' Road
    x(0)=x1-w1: y(0)=y1: x(1)=x1+w1: y(1)=y1
    x(2)=x2+w2: y(2)=y2: x(3)=x2-w2: y(3)=y2
    polygon 4, x(), y(), g_segments(ix%,3), g_segments(ix%,3)

    ' Left rumble strip
    x(0)=x1-w1-rw1: x(1)=x1-w1: x(2)=x2-w2: x(3)=x2-w2-rw2
    polygon 4, x(), y(), g_segments(ix%,6), g_segments(ix%,6)

    ' Off road - left
    x(1)=0: x(2)=0
    polygon 4, x(), y(), g_segments(ix%,4), g_segments(ix%,4)

    ' Right rumble strip
    x(0)=x1+w1+rw1: x(1)=x1+w1: x(2)=x2+w2: x(3)=x2+w2+rw2
    polygon 4, x(), y(), g_segments(ix%,6), g_segments(ix%,6)

    ' Off road - right
    x(1)=max(mm.hres,x(1))
    x(2)=max(mm.hres,x(2))
    polygon 4, x(), y(), g_segments(ix%,4), g_segments(ix%,4)

    ' Lanes
    if g_segments(ix%, 5) then
        local lw1=w1*20/ROAD_WIDTH, lw2=w2*20/ROAD_WIDTH
        local lx1=x1-w1, lx2=x2-w2
        local ld1=w1*2/g_segments(ix%,7)-lw1/2
        local ld2=w2*2/g_segments(ix%,7)-lw2/2
        local lane%
        for lane%=1 to g_segments(ix%,7) + 1
            x(0)=lx1: x(1)=lx1+lw1: x(2)=lx2+lw2: x(3)=lx2
            polygon 4, x(), y(), g_segments(ix%,5), g_segments(ix%,5)
            inc lx1,ld1: inc lx2,ld2
        next
    end if
end sub
