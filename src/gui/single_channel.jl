
#=
Convert canvas coordinates to voltage vs time coordinates
=#

function coordinate_transform(sc::Single_Channel,event)
    (x1,x2,y1,y2)=coordinate_transform(sc,sc.mi[1],sc.mi[2],event.x,event.y)
end

function coordinate_transform(sc::Single_Channel,xi1::Float64,yi1::Float64,xi2::Float64,yi2::Float64)

    ctx=sc.ctx2

    myx=[1.0;collect(2:(sc.wave_points-1)).*(sc.w2/sc.wave_points)]
    x1=indmin(abs.(myx-xi1))
    x2=indmin(abs.(myx-xi2))
    s=sc.s
    o=sc.o
    y1=(yi1-sc.h2/2+o)/s
    y2=(yi2-sc.h2/2+o)/s

    #ensure that left most point is first
    if x1>x2
        x=x1
        x1=x2
        x2=x
        y=y1
        y1=y2
        y2=y
    end
    (x1,x2,y1,y2)
end


#=
Rubber Band functions adopted from GtkUtilities.jl package by Tim Holy 2015
=#

function rubberband_start(sc::Single_Channel, x, y, button_num=1)

    sc.rb = RubberBand(Vec2(x,y), Vec2(x,y), Vec2(x,y), [Vec2(x,y)],false, 2)
    sc.selected=falses(500)
    sc.plotted=falses(500)

    if button_num==1
        push!((sc.c2.mouse, :button1motion),  (c, event) -> rubberband_move(sc,event.x, event.y))
        push!((sc.c2.mouse, :motion), Gtk.default_mouse_cb)
        push!((sc.c2.mouse, :button1release), (c, event) -> rubberband_stop(sc,event.x, event.y,button_num))
    elseif button_num==3
        push!((sc.c2.mouse, :motion),  (c, event) -> rubberband_move(sc,event.x, event.y))
        push!((sc.c2.mouse, :button3release), (c, event) -> rubberband_stop(sc,event.x, event.y,button_num))
    end
    sc.rb_active=true
    nothing
end

function rubberband_move(sc::Single_Channel, x, y)

    sc.rb.moved = true
    sc.rb.pos2 = Vec2(x ,y)
    nothing
end

function rubberband_stop(sc::Single_Channel, x, y,button_num)

    if button_num==1
        pop!((sc.c2.mouse, :button1motion))
        pop!((sc.c2.mouse, :motion))
        pop!((sc.c2.mouse, :button1release))
    elseif button_num==3
        pop!((sc.c2.mouse, :motion))
        pop!((sc.c2.mouse, :button3release))
    end

    sc.rb.moved = false
    sc.rb_active=false
    clear_rb(sc)
    nothing
end

function draw_rb(sc::Single_Channel)

    if sc.rb.moved

        if sc.pause_state == 1

            ctx = sc.ctx2
            clear_rb(sc)

            line(ctx,sc.rb.pos0.x,sc.rb.pos2.x,sc.rb.pos0.y,sc.rb.pos2.y)
            set_line_width(ctx,1.0)
            set_source_rgb(ctx,1.0,1.0,1.0)
            stroke(ctx)

            #Find selected waveforms and plot
            if (sc.buf.selected_clus>0)&((sc.buf.count>0)&(sc.pause))
                get_selected_waveforms(sc,sc.buf.spikes)
                mycolor=1
                if sc.click_button==1
                    mycolor=sc.buf.selected_clus+1
                elseif sc.click_button==3
                    mycolor=1
                end
                plot_selected_waveforms(sc,sc.buf.spikes,mycolor)
            end
            sc.rb.pos1=sc.rb.pos2
        elseif sc.pause_state == 2
            draw_template(sc)
        end

    end

    nothing
end

function clear_rb(sc::Single_Channel)

    line(sc.ctx2,sc.rb.pos0.x,sc.rb.pos1.x,sc.rb.pos0.y,sc.rb.pos1.y)
    set_line_width(sc.ctx2,2.0)
    set_source(sc.ctx2,sc.ctx2s)
    stroke(sc.ctx2)

    nothing
end

#=
Canvas Draw Templates
=#

function draw_start(sc::Single_Channel, x, y, temp,button_num=1)

    vec_list=Array(Vec2,0)

    clus = sc.buf.selected_clus
    for i=1:size(temp.templates,1)
        push!(vec_list,Vec2(temp.templates[i,clus]-temp.sig_min[i,clus],temp.templates[i,clus]+temp.sig_max[i,clus]))
    end

    sc.rb = RubberBand(Vec2(x,y), Vec2(x,y), Vec2(x,y),vec_list,false, 2)
    sc.selected=falses(500)
    sc.plotted=falses(500)

    if button_num==1
        push!((sc.c2.mouse, :button1motion),  (c, event) -> draw_move(sc,event.x, event.y))
        push!((sc.c2.mouse, :motion), Gtk.default_mouse_cb)
        push!((sc.c2.mouse, :button1release), (c, event) -> draw_stop(sc,event.x, event.y,temp,button_num))
    elseif button_num==3
        push!((sc.c2.mouse, :motion),  (c, event) -> draw_move(sc,event.x, event.y))
        push!((sc.c2.mouse, :button3release), (c, event) -> draw_stop(sc,event.x, event.y,temp,button_num))
    end
    sc.rb_active=true
    nothing
end

function draw_move(sc::Single_Channel, x, y)

    sc.rb.moved = true
    sc.rb.pos2 = Vec2(x ,y)
    nothing
end

function draw_stop(sc::Single_Channel, x, y,temp,button_num)

    if button_num==1
        pop!((sc.c2.mouse, :button1motion))
        pop!((sc.c2.mouse, :motion))
        pop!((sc.c2.mouse, :button1release))
    elseif button_num==3
        pop!((sc.c2.mouse, :motion))
        pop!((sc.c2.mouse, :button3release))
    end

    sc.rb.moved = false
    sc.rb_active=false

    clus = sc.buf.selected_clus
    for i=1:length(sc.rb.polygon)
        temp.templates[i,clus] = (sc.rb.polygon[i].x + sc.rb.polygon[i].y) / 2
        temp.sig_min[i,clus] = temp.templates[i,clus] - sc.rb.polygon[i].x
        temp.sig_max[i,clus] = sc.rb.polygon[i].y - temp.templates[i,clus]
    end
    nothing
end

function draw_template(sc::Single_Channel)

    (x1,x2,y1,y2)=coordinate_transform(sc,sc.rb.pos2.x,sc.rb.pos2.y,sc.rb.pos2.x,sc.rb.pos2.y)

    if x1 != sc.rb.pos1.x
        sc.rb.pos1 = Vec2(x1,x1)


        myline=0 #0 for bottom, 1 for top

        mymean=(sc.rb.polygon[x1].x+sc.rb.polygon[x1].y)/2

        if y1 < mymean
            myline = 0
        else
            myline = 1
        end

        s=sc.s
        ctx = sc.ctx2
        wave_points=length(sc.rb.polygon)
        Cairo.translate(ctx,0.0,sc.h2/2)
        Gtk.scale(ctx,sc.w2/wave_points,s)
        clus = sc.buf.selected_clus + 1

        if myline == 0
            move_to(ctx,1,sc.rb.polygon[1].x)
            for i=2:wave_points
                line_to(ctx,i,sc.rb.polygon[i].x)
            end
            sc.rb.polygon[x1] = Vec2(y1,sc.rb.polygon[x1].y)
        else
            move_to(ctx,1,sc.rb.polygon[1].y)
            for i=2:wave_points
                line_to(ctx,i,sc.rb.polygon[i].y)
            end
            sc.rb.polygon[x1] = Vec2(sc.rb.polygon[x1].x,y1)
        end

        identity_matrix(ctx)

        set_line_width(ctx,2.0)
        set_source(ctx,sc.ctx2s)
        stroke(ctx)

        Cairo.translate(ctx,0.0,sc.h2/2)
        Gtk.scale(ctx,sc.w2/wave_points,s)

        if myline == 0
            move_to(ctx,1,sc.rb.polygon[1].x)
            for i=2:wave_points
                line_to(ctx,i,sc.rb.polygon[i].x)
            end
        else
            move_to(ctx,1,sc.rb.polygon[1].y)
            for i=2:wave_points
                line_to(ctx,i,sc.rb.polygon[i].y)
            end
        end

        set_line_width(ctx,1.0)
        select_color(ctx,clus)
        stroke(ctx)

        identity_matrix(ctx)

    end

    nothing
end

#=
Find waveforms that cross line defined by (x1,y1),(x2,y2)
=#
function find_intersected_waveforms{T}(input::Array{T,2},mask,count,x1,y1,x2,y2)

    #Bounds check
    x1 = x1 < 2 ? 2 : x1
    x2 = x2 > size(input,2)-2 ? size(input,2)-2 : x2

    for i=1:count
        for j=(x1-1):(x2+1)
            if SpikeSorting.intersect(x1,x2,j,j+1,y1,y2,input[j,i],input[j+1,i])
                mask[i]=false
                break
            end
        end
    end

    nothing
end

#=
Find which of the intersected waveforms are in a different cluster and if that difference has already been plotted
=#
function get_selected_waveforms{T<:Real}(sc::Single_Channel,input::Array{T,2})

    (x1,x2,y1,y2)=coordinate_transform(sc,sc.rb.pos0.x,sc.rb.pos0.y,sc.rb.pos2.x,sc.rb.pos2.y)

    intersection = trues(sc.buf.ind)
    find_intersected_waveforms(sc.buf.spikes,intersection,sc.buf.ind,x1,y1,x2,y2)

    for i=1:sc.buf.ind
        if sc.buf.mask[i]
            if !intersection[i]
                sc.selected[i]=true
            end
            if (sc.plotted[i])&(intersection[i])
                sc.selected[i]=false
            end
        end
    end

    nothing
end


#=
Plot waveforms in incremental way

Selected - true if waveform is captured by incremental capture
Plotted - true if waveform has been replotted in new color since start of incremental capture
=#
function plot_selected_waveforms{T<:Real}(sc::Single_Channel,input::Array{T,2},mycolor)

    ctx=sc.ctx2
    s=sc.s
    o=sc.o

    set_line_width(ctx,2.0)
    set_source(ctx,sc.ctx2s)
    Cairo.translate(ctx,0.0,sc.h2/2)
    Gtk.scale(ctx,sc.w2/sc.wave_points,s)

    #=
    Reset waveforms that have changed since the start but are
    no longer selected
    =#
    for j=1:sc.buf.count
        if (!sc.selected[j])&(sc.plotted[j])
            move_to(ctx,1,(input[1,j]-o))
            for jj=2:size(input,1)
                line_to(ctx,jj,input[jj,j]-o)
            end
            sc.plotted[j]=false
        end
    end
    stroke(ctx)

    #=
    Plot selected waveforms in new color that have not
    yet been plotting in new color
    =#
    for i=1:sc.buf.count
        if (sc.selected[i])&(!sc.plotted[i])
            move_to(ctx,1,(input[1,i]-o))
            for jj=2:size(input,1)
                line_to(ctx,jj,input[jj,i]-o)
            end
            sc.plotted[i]=true
        end
    end
    set_line_width(ctx,0.5)
    select_color(ctx,mycolor)
    stroke(ctx)

    identity_matrix(ctx)
    nothing
end

#=
Show threshold on canvas
=#

function plot_thres(sc::Single_Channel)

    ctx = sc.ctx2

    line(ctx,1,sc.w2,sc.h2/2-sc.old_thres,sc.h2/2-sc.old_thres)
    set_line_width(ctx,5.0)
    set_source(ctx,sc.ctx2s)
    stroke(ctx)

    line(ctx,1,sc.w2,sc.h2/2-sc.thres,sc.h2/2-sc.thres)
    set_line_width(ctx,1.0)
    set_source_rgb(ctx,1.0,1.0,1.0)
    stroke(ctx)
    sc.old_thres=sc.thres
    nothing
end

function clear_c2(myc::Gtk.GtkCanvas,num)

    ctx = Gtk.getgc(myc)
    myheight=height(ctx)
    mywidth=width(ctx)

    set_source_rgb(ctx,0.0,0.0,0.0)
    paint(ctx)

    dashes = [10.0,10.0,10.0]
    set_dash(ctx, dashes, 0.0)

    for y = [myheight/6, myheight/3, myheight/2, myheight/6*4, myheight/6*5]
        line(ctx,1,mywidth,y,y)
    end

    for x = [.2*mywidth, .4*mywidth, .6*mywidth, .8*mywidth]
        line(ctx,x,x,1,myheight)
    end

    set_source_rgba(ctx,1.0,1.0,1.0,.5)
    stroke(ctx)

    set_dash(ctx,Float64[])

    line(ctx,1,mywidth,myheight,myheight)
    set_source_rgb(ctx,1.0,1.0,1.0)
    stroke(ctx)

    line(ctx,1,mywidth,myheight/2,myheight/2)
    stroke(ctx)

    move_to(ctx,10,10)
    show_text(ctx,string(num))

    nothing
end

function pause_state_cb(widgetptr::Ptr,user_data::Tuple{Single_Channel,Int64})

    sc, myid = user_data

    sc.pause_state = myid

    nothing
end

#=
Callback for how mouse interacts with canvas
=#
function canvas_press_win(widget::Ptr,param_tuple,user_data::Tuple{Single_Channel})

    sc, = user_data
    event = unsafe_load(param_tuple)

    sc.click_button=event.button

    if event.button == 1 #left click captures window
        sc.mi=(event.x,event.y)
        if sc.pause_state==1
            rubberband_start(sc,event.x,event.y)
        elseif sc.pause_state == 2
            if sc.pause
                draw_start(sc,event.x,event.y,sc.temp)
            end
        end
    elseif event.button == 3 #right click refreshes window
        if !sc.pause
            clear_c2(sc.c2,sc.spike)
            sc.ctx2=Gtk.getgc(sc.c2)
            sc.ctx2s=copy(sc.ctx2)
            sc.buf.ind=1
            sc.buf.count=1
            if sc.sort_cb
                draw_templates(sc)
            end
        else
            sc.mi=(event.x,event.y)
            if sc.pause_state==1
                rubberband_start(sc,event.x,event.y,3)
            elseif sc.pause_state == 2

            end
        end
    end
    nothing
end

function pause_cb(widgetptr::Ptr,user_data::Tuple{Single_Channel})

    sc, = user_data

    widget = convert(ToggleButton, widgetptr)

    if getproperty(widget,:active,Bool)
        sc.pause=true
        change_button_label(widget,"Resume")
        for i=1:length(sc.buf.mask)
            sc.buf.mask[i]=true
        end
    else
        sc.pause=false
        change_button_label(widget,"Pause")
        sc.hold=false
    end

    nothing
end

function clear_button_cb(widget::Ptr,user_data::Tuple{SpikeSorting.Single_Channel})

    sc, = user_data
    SpikeSorting.clear_c2(sc.c2,sc.spike)
    sc.ctx2=Gtk.getgc(sc.c2)
    sc.ctx2s=copy(sc.ctx2)
    #Sort Button
    if sc.sort_cb
        SpikeSorting.draw_templates(sc)
    end

    nothing
end

function restore_button_cb(widget::Ptr,user_data::Tuple{SpikeSorting.Single_Channel})

    sc, = user_data

    if sc.pause
        for i=1:sc.buf.ind
            sc.buf.mask[i]=true
        end

        sc.buf.replot=true
    end

    nothing
end

function canvas_release_template(widget::Ptr,param_tuple,user_data::Tuple{Buffer,Single_Channel})

    buf,sc = user_data
    event = unsafe_load(param_tuple)

    clus=buf.selected_clus

    (x1,x2,y1,y2)=SpikeSorting.coordinate_transform(sc,event)

    if event.button==1

        if sc.pause_state == 1
            #Waveforms selected with a left click rubberband in the paused display will be used to form a cluster template for the currently selected cluster.

            if (clus==0) #do nothing if zeroth cluster
            else

                buf.selected=trues(buf.ind)
                find_intersected_waveforms(buf.spikes,buf.selected,buf.ind,x1,y1,x2,y2)

                buf.c_changed=true
            end

            if (clus>0)&((buf.count>0)&(sc.pause))
                buf.replot=true
            end
        elseif sc.pause_state == 2
            if sc.pause
                buf.c_changed=true
            end
        end
    elseif event.button==3

        if sc.pause_state == 1
            #Waveforms selected with right click in the paused display will be removed from display. If a cluster is selected, these waveforms will also be removed from that selected cluster

            if sc.pause
                find_intersected_waveforms(buf.spikes,buf.mask,buf.count,x1,y1,x2,y2)

                if clus>0
                    buf.selected=.!(buf.clus.==clus)
                    buf.c_changed=true
                end
                buf.replot=true
            end
        elseif sc.pause_state == 2
            if sc.pause

            end
        end
    end

    nothing
end

function win_resize_cb(widget::Ptr,param_tuple,user_data::Tuple{Single_Channel})

    sc, = user_data

    ctx=Gtk.getgc(sc.c2)

    if (height(ctx)!=sc.h2)|(width(ctx)!=sc.w2)

        sc.ctx2=ctx
        sc.ctx2s=copy(sc.ctx2)
        sc.w2=width(sc.ctx2)
        sc.h2=height(sc.ctx2)

        setproperty!(sc.adj_thres,:upper,sc.h2/2)
        setproperty!(sc.adj_thres,:lower,-sc.h2/2)
    end

    nothing
end

#=
Redraw all spikes shown in paused view
=#
function replot_all_spikes(sc::Single_Channel)

    SpikeSorting.clear_c2(sc.c2,sc.spike)
    sc.ctx2=Gtk.getgc(sc.c2)
    sc.ctx2s=copy(sc.ctx2)

    ctx=sc.ctx2s
    s=sc.s
    o=sc.o

    Cairo.translate(ctx,0.0,sc.h2/2)
    Cairo.scale(ctx,sc.w2/sc.wave_points,s)

    for i=1:(sc.total_clus+1)
        for j=1:sc.buf.ind
            if (sc.buf.clus[j]==(i-1))&(sc.buf.mask[j])
                move_to(ctx,1,(sc.buf.spikes[1,j]-o))
                for jj=2:size(sc.buf.spikes,1)
                    line_to(ctx,jj,sc.buf.spikes[jj,j]-o)
                end
            end
        end
        set_line_width(ctx,0.5)
        select_color(ctx,i)
        stroke(ctx)
    end
    identity_matrix(ctx)
    set_source(sc.ctx2,ctx)
    mask_surface(sc.ctx2,ctx,0.0,0.0)
    fill(sc.ctx2)
    reveal(sc.c2)
    nothing
end

function mask_surface(ctx,s,x,y)
    ccall((:cairo_mask_surface,Cairo._jl_libcairo),Void,(Ptr{Void},Ptr{Void},Float64,Float64),ctx.ptr,s.surface.ptr,x,y)
end
