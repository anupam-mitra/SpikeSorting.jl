

function sort_gui(wave_points)

    grid = Grid()

    c_sort = Canvas(100,100)

    @guarded draw(c_sort) do widget
        ctx = Gtk.getgc(c_sort)
        set_source_rgb(ctx,0.0,0.0,0.0)
        paint(ctx)
    end
    show(c_sort)
    grid[1,2]=c_sort
    setproperty!(c_sort,:hexpand,true)
    setproperty!(c_sort,:vexpand,true)

    panel_grid = Grid()
    grid[2,2] = panel_grid

    b1 = Button("Plot")

    panel_grid[1,1]=b1

    clusteropts = MenuItem("_Cluster")
    clustermenu = Menu(clusteropts)
    cluster_km = MenuItem("K means")
    push!(clustermenu,cluster_km)
    cluster_dbscan = MenuItem("DBSCAN")
    push!(clustermenu,cluster_dbscan)

    mb = MenuBar()
    push!(mb, clusteropts)
    grid[1,1]=mb

    col_sb=SpinButton(1:3)
    panel_grid[1,3]=col_sb

    #Event
    popup_axis = Menu()

    popup_x = MenuItem("X Axis")
    push!(popup_axis,popup_x)
    popup_x_menu=Menu(popup_x)
    popup_y = MenuItem("Y Axis")
    push!(popup_axis,popup_y)
    popup_y_menu=Menu(popup_y)

    popup_pca1_x=MenuItem("PCA1")
    push!(popup_x_menu,popup_pca1_x)
    popup_pca2_x=MenuItem("PCA2")
    push!(popup_x_menu,popup_pca2_x)
    popup_pca3_x=MenuItem("PCA3")
    push!(popup_x_menu,popup_pca3_x)
    popup_peak_x=MenuItem("Peak")
    push!(popup_x_menu,popup_peak_x)
    popup_valley_x=MenuItem("Valley")
    push!(popup_x_menu,popup_valley_x)
    popup_pv_x=MenuItem("Peak-Valley")
    push!(popup_x_menu,popup_pv_x)
    popup_area_x=MenuItem("Area")
    push!(popup_x_menu,popup_area_x)

    popup_pca1_y=MenuItem("PCA1")
    push!(popup_y_menu,popup_pca1_y)
    popup_pca2_y=MenuItem("PCA2")
    push!(popup_y_menu,popup_pca2_y)
    popup_pca3_y=MenuItem("PCA3")
    push!(popup_y_menu,popup_pca3_y)
    popup_peak_y=MenuItem("Peak")
    push!(popup_y_menu,popup_peak_y)
    popup_valley_y=MenuItem("Valley")
    push!(popup_y_menu,popup_valley_y)
    popup_pv_y=MenuItem("Peak-Valley")
    push!(popup_y_menu,popup_pv_y)
    popup_area_y=MenuItem("Area")
    push!(popup_y_menu,popup_area_y)

    Gtk.showall(popup_axis)


    win = Window(grid,"Sort View") |> Gtk.showall

    myfeatures=Dict{String,Array{Float64,1}}("PCA-1"=>zeros(Float64,0),"PCA-2"=>zeros(Float64,0),"PCA-3"=>zeros(Float64,0),"Peak"=>zeros(Float64,0),"Valley"=>zeros(Float64,0),"Peak-Valley"=>zeros(Float64,0),"Area"=>zeros(Float64,0))

    handles = SortView(win,c_sort,b1,myfeatures,fit(PCA,rand(Float64,10,10)),false,1,1,popup_axis,1,falses(10,2),["Non" for i=1:20,j=1:2],col_sb,[FeaturePlot() for i=1:10],100.0,100.0,Buffer(wave_points))

    signal_connect(b1_cb,b1,"clicked",Void,(),false,(handles,))
    signal_connect(col_sb_cb,col_sb,"value-changed",Void,(),false,(handles,))

    signal_connect(canvas_press,c_sort,"button-press-event",Void,(Ptr{Gtk.GdkEventButton},),false,(handles,))

    signal_connect(popup_pca1_cb_x,popup_pca1_x,"activate",Void,(),false,(handles,))
    signal_connect(popup_pca2_cb_x,popup_pca2_x,"activate",Void,(),false,(handles,))
    signal_connect(popup_pca1_cb_y,popup_pca1_y,"activate",Void,(),false,(handles,))
    signal_connect(popup_pca2_cb_y,popup_pca2_y,"activate",Void,(),false,(handles,))
    signal_connect(popup_pca3_cb_x,popup_pca3_x,"activate",Void,(),false,(handles,))
    signal_connect(popup_pca3_cb_y,popup_pca3_y,"activate",Void,(),false,(handles,))
    signal_connect(popup_peak_cb_x,popup_peak_x,"activate",Void,(),false,(handles,))
    signal_connect(popup_peak_cb_y,popup_peak_y,"activate",Void,(),false,(handles,))
    signal_connect(popup_valley_cb_x,popup_valley_x,"activate",Void,(),false,(handles,))
    signal_connect(popup_valley_cb_y,popup_valley_y,"activate",Void,(),false,(handles,))
    signal_connect(popup_pv_cb_x,popup_pv_x,"activate",Void,(),false,(handles,))
    signal_connect(popup_pv_cb_y,popup_pv_y,"activate",Void,(),false,(handles,))

    signal_connect(popup_area_cb_x,popup_area_x,"activate",Void,(),false,(handles,))
    signal_connect(popup_area_cb_y,popup_area_y,"activate",Void,(),false,(handles,))

    id = signal_connect(win_resize_cb, win, "size-allocate",Void,(Ptr{Gtk.GdkRectangle},),false,(handles,))

    handles
end




function b1_cb(widget::Ptr,user_data::Tuple{SortView})

    han, = user_data
    replot_sort(han)

    nothing
end

function b2_cb(widget::Ptr,user_data::Tuple{SortView})

    han, = user_data
    recalc_features(han)
    replot_sort(han)

    nothing
end

function recalc_features(han::SortView)

    han.pca_calced=false
    reset_pca(han,1)
    reset_pca(han,2)
    reset_pca(han,3)
    reset_peak(han)
    reset_valley(han)
    reset_pv(han)
    reset_area(han)

    for i=han.n_col*han.n_row

        if han.axes_name[i,1]=="Non"
            han.axes_name[i,1]="Peak"
        end
        if han.axes_name[i,2]=="Non"
            han.axes_name[i,2]="Peak"
        end

        scale_xaxis(han,i)
        scale_yaxis(han,i)
    end

    nothing
end

function col_sb_cb(widget::Ptr,user_data::Tuple{SortView})

    han, = user_data
    han.n_col=getproperty(han.col_sb,:value,Int)

    replot_sort(han)

    nothing
end

popup_pca1_cb_x(widget::Ptr,han::Tuple{SortView})=pca_calc(han[1],1,1)
popup_pca2_cb_x(widget::Ptr,han::Tuple{SortView})=pca_calc(han[1],2,1)
popup_pca3_cb_x(widget::Ptr,han::Tuple{SortView})=pca_calc(han[1],3,1)
popup_pca1_cb_y(widget::Ptr,han::Tuple{SortView})=pca_calc(han[1],1,2)
popup_pca2_cb_y(widget::Ptr,han::Tuple{SortView})=pca_calc(han[1],2,2)
popup_pca3_cb_y(widget::Ptr,han::Tuple{SortView})=pca_calc(han[1],3,2)

popup_peak_cb_x(widget::Ptr,han::Tuple{SortView})=peak_calc(han[1],1)
popup_peak_cb_y(widget::Ptr,han::Tuple{SortView})=peak_calc(han[1],2)

popup_valley_cb_x(widget::Ptr,han::Tuple{SortView})=valley_calc(han[1],1)
popup_valley_cb_y(widget::Ptr,han::Tuple{SortView})=valley_calc(han[1],2)

popup_pv_cb_x(widget::Ptr,han::Tuple{SortView})=pv_calc(han[1],1)
popup_pv_cb_y(widget::Ptr,han::Tuple{SortView})=pv_calc(han[1],2)

popup_area_cb_x(widget::Ptr,han::Tuple{SortView})=area_calc(han[1],1)
popup_area_cb_y(widget::Ptr,han::Tuple{SortView})=area_calc(han[1],2)

function reset_pca(han::SortView,num::Int64)
    if !han.pca_calced
        han.pca = fit(PCA,convert(Array{Float64,2},han.buf.spikes[:,1:han.buf.ind]))
        han.pca_calced=true
    end

    if num>size(han.pca.proj,2)
        han.features[string("PCA-",num)]=zeros(Float64,han.buf.ind)
    else
        han.features[string("PCA-",num)] = squeeze(han.pca.proj[:,num]' * han.buf.spikes[:,1:han.buf.ind],1)

    end
    nothing
end

function pca_calc(han::SortView,num::Int64,myaxis::Int64)

    reset_pca(han,num)
    han.axes_name[han.selected_plot,myaxis]=string("PCA-",num)
    scale_axis(han,myaxis)

    replot_sort(han)
    nothing
end

function reset_peak(han::SortView)
    han.features["Peak"]=zeros(Float64,han.buf.ind)
    for i=1:han.buf.ind
        han.features["Peak"][i]=maximum(han.buf.spikes[:,i])
    end
    nothing
end

function peak_calc(han::SortView,myaxis::Int64)

    reset_peak(han)
    han.axes_name[han.selected_plot,myaxis]=string("Peak")
    scale_axis(han,myaxis)

    replot_sort(han)
end

function reset_valley(han::SortView)
    han.features["Valley"]=zeros(Float64,han.buf.ind)
    for i=1:han.buf.ind
        han.features["Valley"][i]=minimum(han.buf.spikes[:,i])
    end
    nothing
end

function valley_calc(han::SortView,myaxis::Int64)

    reset_valley(han)
    han.axes_name[han.selected_plot,myaxis]=string("Valley")
    scale_axis(han,myaxis)

    replot_sort(han)
end

function reset_pv(han::SortView)
    han.features["Peak-Valley"]=zeros(Float64,han.buf.ind)
    for i=1:han.buf.ind
        han.features["Peak-Valley"][i]=maximum(han.buf.spikes[:,i])-minimum(han.buf.spikes[:,i])
    end
    nothing
end

function pv_calc(han::SortView,myaxis::Int64)

    reset_pv(han)
    han.axes_name[han.selected_plot,myaxis]=string("Peak-Valley")
    scale_axis(han,myaxis)

    replot_sort(han)
    nothing
end

function reset_area(han::SortView)
    han.features["Area"]=zeros(Float64,han.buf.ind)
    for i=1:han.buf.ind
        for j=1:size(han.buf.spikes,1)
            han.features["Area"][i]+=maximum(han.buf.spikes[j,i])
        end
    end
    nothing
end

function area_calc(han::SortView,myaxis::Int64)

    reset_area(han)
    han.axes_name[han.selected_plot,myaxis]=string("Area")
    scale_axis(han,myaxis)

    replot_sort(han)
end

function scale_xaxis(han::SortView,myplot::Int64)
    han.plots[myplot].xmin=minimum(han.features[han.axes_name[myplot,1]])
    han.plots[myplot].xscale=maximum(han.features[han.axes_name[myplot,1]])-han.plots[myplot].xmin
end

function scale_yaxis(han::SortView,myplot::Int64)
    han.plots[myplot].ymin=minimum(han.features[han.axes_name[myplot,2]])
    han.plots[myplot].yscale=maximum(han.features[han.axes_name[myplot,2]])-han.plots[myplot].ymin
end

function scale_axis(han::SortView,myaxis::Int64)

    if myaxis==1
        scale_xaxis(han,han.selected_plot)
    else
        scale_yaxis(han,han.selected_plot)
    end

    han.axes[han.selected_plot,myaxis]=true
    nothing
end

function name_axis(han::SortView,myname)

end

function canvas_press(widget::Ptr,param_tuple,user_data::Tuple{SortView})

    han, = user_data

    event = unsafe_load(param_tuple)

    inaxis = get_axis_bounds(han,event.x,event.y)

    if event.button==1
        rubberband_start(han,event.x,event.y)
    elseif event.button==3
        popup(han.popup_axis,event)
    end

    nothing
end

function get_axis_bounds(han::SortView,x,y)

    xbounds=linspace(0.0,han.w,han.n_col+1)
    ybounds=linspace(0.0,han.h,han.n_row+1)

    count=1
    for yy=2:length(ybounds), xx=2:length(xbounds)
        if (x<xbounds[xx])&(y<ybounds[yy])
            han.selected_plot=count
            break
        end
        count+=1
    end

    nothing
end

function replot_sort(han::SortView)

    ctx=Gtk.getgc(han.c)
    set_source_rgb(ctx,0.0,0.0,0.0)
    paint(ctx)

    #Check if something has changed in underlying data
    if han.axes[1,1]&han.axes[1,2]
        if length(han.features[han.axes_name[1,1]]) != han.buf.ind
            recalc_features(han)
        end
    end

    prepare_plots(han)

    for jj=1:(han.n_col*han.n_row)

        if han.axes[jj,1]&han.axes[jj,2]

            xmin=han.plots[jj].xmin
            ymin=han.plots[jj].ymin
            xscale=han.plots[jj].xscale
            yscale=han.plots[jj].yscale

            xdata = han.features[han.axes_name[jj,1]]
            ydata = han.features[han.axes_name[jj,2]]

            Cairo.translate(ctx,50+han.w/(han.n_col)*(jj-1),1)
            Cairo.scale(ctx,(han.w/(han.n_col)-70)/xscale,(han.h/(han.n_row)-50)/yscale)

            for ii=1:(maximum(han.buf.clus)+1)
                for i=1:han.buf.ind
                    if (han.buf.clus[i]+1 == ii)&(han.buf.mask[i])

                        move_to(ctx,xdata[i]-xmin,ydata[i]-ymin)

                        line_to(ctx,xdata[i]-xmin+10.0,ydata[i]-ymin+10.0)
                    end
                end
                select_color(ctx,ii)
                stroke(ctx)
            end

            identity_matrix(ctx)

            set_source_rgb(ctx,1.0,1.0,1.0)
            move_to(ctx,han.w/(han.n_col*2)+han.w/(han.n_col)*(jj-1),han.h-10.0)
            show_text(ctx,han.axes_name[jj,1])

            move_to(ctx,10.0+han.w/han.n_col*(jj-1),han.h/2)
            rotate(ctx,-pi/2)
            show_text(ctx,han.axes_name[jj,2])

            identity_matrix(ctx)
        end
    end
    reveal(han.c)

    nothing
end

function prepare_plots(han::SortView)

    ctx=Gtk.getgc(han.c)

    xbounds=linspace(0.0,han.w,han.n_col+1)
    ybounds=linspace(0.0,han.h,han.n_row+1)

    for i=2:length(ybounds)-1
        move_to(ctx,0.0,ybounds[i])
        line_to(ctx,han.w,ybounds[i])
    end

    for i=2:length(xbounds)-1
        move_to(ctx,xbounds[i],0.0)
        line_to(ctx,xbounds[i],han.h)
    end

    nothing
end

identity_matrix(ctx)=ccall((:cairo_identity_matrix,Cairo._jl_libcairo),Void, (Ptr{Void},), ctx.ptr)

function select_color(ctx,clus,alpha=1.0)

    if clus==1
        set_source_rgba(ctx,1.0,1.0,1.0,alpha) # white
    elseif clus==2
        set_source_rgba(ctx,1.0,1.0,0.0,alpha) #Yellow
    elseif clus==3
        set_source_rgba(ctx,0.0,1.0,0.0,alpha) #Green
    elseif clus==4
        set_source_rgba(ctx,0.0,0.0,1.0,alpha) #Blue
    elseif clus==5
        set_source_rgba(ctx,1.0,0.0,0.0,alpha) #Red
    else
        set_source_rgba(ctx,1.0,1.0,0.0,alpha)
    end

    nothing
end

#=
Rubber Band functions adopted from GtkUtilities.jl package by Tim Holy 2015
=#

function rb_draw(r::Cairo.CairoContext, rb::RubberBand)
    rb_set(r, rb)
    set_line_width(r, 1)

    set_source_rgb(r, 1, 1, 1)
    stroke_preserve(r)
end

function rb_set(r::Cairo.CairoContext, rb::RubberBand)
    move_to(r, rb.pos1.x, rb.pos1.y)
    rel_line_to(r,rb.pos2.x-rb.pos1.x, rb.pos2.y-rb.pos1.y)
end

function rubberband_start(han::SortView, x, y; minpixels::Int=2)
    r = Gtk.getgc(han.c)
    Cairo.save(r)
    ctxcopy = copy(r)
    rb = RubberBand(Vec2(x,y),Vec2(x,y), Vec2(x,y), [Vec2(x,y)],false, minpixels)
    push!((han.c.mouse, :button1motion),  (c, event) -> rubberband_move(han.c, rb, event.x, event.y, ctxcopy))
    push!((han.c.mouse, :motion), Gtk.default_mouse_cb)
    push!((han.c.mouse, :button1release), (c, event) -> rubberband_stop(han, rb, event.x, event.y, ctxcopy))
    nothing
end

function rubberband_move(c::Canvas, rb::RubberBand, x, y, ctxcopy)
    r = Gtk.getgc(c)
    if rb.moved
        #rb_erase(r, ctxcopy)
    end
    rb.moved = true

    # Draw the new rubberband
    rb.pos2 = Vec2(x, y)
    push!(rb.polygon,rb.pos2)
    rb_draw(r, rb)
    rb.pos1=rb.pos2
    reveal(c, false)
end

function rubberband_stop(han::SortView, rb::RubberBand, x, y, ctxcopy)
    pop!((han.c.mouse, :button1motion))
    pop!((han.c.mouse, :motion))
    pop!((han.c.mouse, :button1release))
    if !rb.moved
        return
    end
    r = Gtk.getgc(han.c)
    rb_set(r, rb)
    restore(r)
    set_line_width(r,3.0)
    move_to(r,rb.polygon[1].x,rb.polygon[1].y)
    for i=2:length(rb.polygon)
        line_to(r,rb.polygon[i].x,rb.polygon[i].y)
    end
    stroke(r)

    if han.buf.selected_clus>0
        inside_polygon(rb.polygon,han)
    end
    replot_sort(han)
    reveal(han.c, false)
    nothing
end

function canvas_to_feature(han,x1,y1,myplot)

    xtrans=50+han.w/(han.n_col)*(myplot-1)
    ytrans=0

    xscale=(han.w/han.n_col-70)/han.plots[myplot].xscale
    yscale=(han.h/han.n_row-50)/han.plots[myplot].yscale

    x1=(x1 - xtrans)/(xscale)+han.plots[myplot].xmin
    y1=(y1 - ytrans)/(yscale)+han.plots[myplot].ymin

    (x1,y1)
end

function inside_polygon(xy::Array{Vec2,1},han::SortView)

    xmin=xy[1].x
    ymin=xy[1].y
    xmax=xy[1].x
    ymax=xy[1].y

    #Find bounds of lasso
    for i=2:length(xy)
        if xy[i].x<xmin
            xmin=xy[i].x
        elseif xy[i].x>xmax
            xmax=xy[i].x
        end

        if xy[i].y<ymin
            ymin=xy[i].y
        elseif xy[i].y>ymax
            ymax=xy[i].y
        end
    end

    #Convert canvas coordinates to PCA space coordinates
    (xmin,ymin)=canvas_to_feature(han,xmin,ymin,han.selected_plot)
    (xmax,ymax)=canvas_to_feature(han,xmax,ymax,han.selected_plot)

    xdata = han.features[han.axes_name[han.selected_plot,1]]
    ydata = han.features[han.axes_name[han.selected_plot,2]]

    han.buf.selected=trues(han.buf.ind)

    for i=1:han.buf.ind

        px=xdata[i]
        py=ydata[i]
        if ((px>xmin)&(px<xmax))&((py>ymin)&(py<ymax))
            han.buf.selected[i]=false
        end
    end

    han.buf.c_changed=true
    han.buf.replot=true
    nothing
end

function win_resize_cb(widget::Ptr,param_tuple,user_data::Tuple{SortView})

    han, = user_data

    ctx=Gtk.getgc(han.c)
    han.h=height(ctx)
    han.w=width(ctx)

    replot_sort(han)

    nothing
end
