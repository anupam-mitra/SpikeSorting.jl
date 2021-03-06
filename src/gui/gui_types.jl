
mutable struct FeaturePlot
    xmin::Float64
    ymin::Float64
    xscale::Float64
    yscale::Float64
    xc_i::Float64
end

FeaturePlot()=FeaturePlot(0.0,0.0,1.0,1.0,1.0)

mutable struct Buffer
    count::Int64
    ind::Int64
    spikes::Array{Int16,2}
    clus::Array{UInt8,1}
    mask::Array{Bool,1}
    selected_clus::UInt8
    replot::Bool
    selected::Array{Bool,1}
    c_changed::Bool
end

Buffer(wave_points)=Buffer(500,1,zeros(Int16,wave_points,500),zeros(UInt8,500),trues(500),1,false,falses(500),false)

struct Vec2
    x::Float64
    y::Float64
end

mutable struct RubberBand
    pos0::Vec2
    pos1::Vec2
    pos2::Vec2
    polygon::Array{Vec2,1}
    moved::Bool
    minpixels::Int
end

mutable struct SortView
    win::Gtk.GtkWindowLeaf

    c::Gtk.GtkCanvasLeaf

    b1::Gtk.GtkButtonLeaf

    features::Dict{String,Array{Float64,1}}

    pca::PCA{Float64}
    pca_calced::Bool

    n_col::Int64
    n_row::Int64

    popup_axis::Gtk.GtkMenuLeaf

    selected_plot::Int64

    axes::Array{Bool,2}
    axes_name::Array{String,2}

    col_sb::Gtk.GtkSpinButtonLeaf

    plots::Array{FeaturePlot,1}

    h::Float64
    w::Float64

    buf::Buffer
end

mutable struct Thres_Widgets
    sb::Gtk.GtkLabelLeaf
    slider::Gtk.GtkScaleLeaf
    adj::Gtk.GtkAdjustmentLeaf
    all::Gtk.GtkCheckButtonLeaf
    show::Gtk.GtkCheckButtonLeaf
end

mutable struct Gain_Widgets
    gainbox::Gtk.GtkSpinButtonLeaf
    multiply::Gtk.GtkCheckButtonLeaf
    all::Gtk.GtkCheckButtonLeaf
end

mutable struct Single_Channel
    c2::Gtk.GtkCanvasLeaf
    c3::Gtk.GtkCanvasLeaf
    ctx2::Cairo.CairoContext
    ctx2s::Cairo.CairoContext
    rb_active::Bool
    rb::RubberBand
    click_button::Int64
    selected::Array{Bool,1}
    plotted::Array{Bool,1}
    hold::Bool
    pause::Bool
    pause_button::Gtk.GtkToggleButtonLeaf
    rb_buttons::Array{Gtk.GtkRadioButton,1}
    pause_state::Int64
    mi::NTuple{2,Float64} #saved x,y position of mouse input
    show_thres::Bool
    w2::Int64
    h2::Int64
    wave_points::Int64
    s::Float64
    o::Float64
    buf::Buffer
    thres::Float64
    old_thres::Float64
    temp::ClusterTemplate

    total_clus::Int64
    spike::Int64
    sort_cb::Bool
    sort_list::Gtk.GtkListStoreLeaf
    sort_tv::Gtk.GtkTreeViewLeaf
    adj_sort::Gtk.GtkAdjustmentLeaf

    adj_thres::Gtk.GtkAdjustmentLeaf
    thres_slider::Gtk.GtkScaleLeaf
    thres_changed::Bool
    thres_widgets::Thres_Widgets
    gain_widgets::Gain_Widgets
end
