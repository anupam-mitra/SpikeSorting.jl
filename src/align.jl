
#=
Alignment methods. Each method needs
1) Type with fields necessary for algorithm
2) function "align" to operate on sort with type field defined above
3) any other necessary functions for alignment algorithm
=#

export AlignMax, AlignMin, AlignMinMax, AlignCOM, AlignProm

#=
Maximum signal
=#
mutable struct AlignMax <: Align
end

function align(a::AlignMax, sort::Sorting)
    mymax=sort.p_temp[sort.s.win2]
    sort.cent=sort.s.win2
    @inbounds for i=(sort.s.win2+1):sort.s.s_end
        if sort.p_temp[i]>mymax
            sort.cent=i+1
            mymax=sort.p_temp[i]
        end
    end
    nothing
end

mysize(align::AlignMax,win)=win

#=
Minimum signal
=#
mutable struct AlignMin <: Align
    shift::Int64
end

AlignMin()=AlignMin(10)

function align(a::AlignMin,sort::Sorting)
    mymin=sort.p_temp[sort.s.win2]
    sort.cent=sort.s.win2
    @inbounds for i=(sort.s.win2+1):sort.s.s_end
        if sort.p_temp[i]<mymin
            sort.cent=i+1
            mymin=sort.p_temp[i]
        end
    end
    sort.cent += a.shift
    nothing
end

mysize(align::AlignMin,win)=win

#=
Middle of Minimum and Max
=#
mutable struct AlignMinMax <: Align
    shift::Int64
end

AlignMinMax()=AlignMinMax(5)

function align(a::AlignMinMax,sort::Sorting)
    mymin=sort.p_temp[sort.s.win2]
    mymax=sort.p_temp[sort.s.win2]
    minind=sort.s.win2
    maxind=sort.s.win2
    @inbounds for i=(sort.s.win2+1):sort.s.s_end
        if sort.p_temp[i]<mymin
            minind=i+1
            mymin=sort.p_temp[i]
        end
        if sort.p_temp[i]>mymax
            maxind=i+1
            mymax=sort.p_temp[i]
        end
    end
    sort.cent = a.shift+round(Int64,(minind+maxind)/2)
    nothing
end

mysize(align::AlignMinMax,win)=win

#=
Center of Mass Alignment
=#

mutable struct AlignCOM <: Align
    shift::Int64
end

AlignCOM()=AlignCOM(5)

function align(a::AlignCOM,sort::Sorting)

    com=0.0
    mysum=0.0

    for i=(sort.s.win2+1):sort.s.s_end
        com += i*abs(sort.p_temp[i])
        mysum += abs(sort.p_temp[i])
    end

    sort.cent = a.shift + round(Int64, com/mysum)

end

mysize(align::AlignCOM,win)=win

#=
Prominence Alignment
=#

mutable struct AlignProm <: Align
    shift::Int64
end

AlignProm()=AlignProm(5)

function align(a::AlignProm,sort::Sorting)

    indprom=sort.s.win2+1
    prom=sort.p_temp[indprom]

    for i=(sort.s.win2+1):sort.s.s_end

        test = (sort.p_temp[i-1]-sort.p_temp[i-2])
        test += (sort.p_temp[i]-sort.p_temp[i-1])
        test += (sort.p_temp[i]-sort.p_temp[i+1])
        test += (sort.p_temp[i+1]-sort.p_temp[i+2])

        if abs(test) > prom
            prom=abs(test)
            indprom=i
        end
    end
    sort.cent = a.shift + indprom
end

mysize(align::AlignProm,win)=win

#=
Maximum Magnitude
=#

#=
FFT upsampling
=#

#=
type AlignFFT <: Align
    M::Int64
    x_int::Array{Complex{Float64},1}
    fout::Array{Complex{Float64},1}
    upsamp::Array{Float64,1}
    align_range::UnitRange{Int64}
end

function AlignFFT(M::Int64)

    AlignFFT(M,zeros(Complex{Float64},M*2*window),
             zeros(Complex{Float64},2*window),zeros(Float64,M*2*window),
             (window_half*M+1):((window+window_half)*M))

end

function align(a::AlignFFT, sort::Sorting)

    sort.a.fout[:]=fft(sort.p_temp)

    sort.a.x_int[1:window]=sort.a.fout[1:window]
    sort.a.x_int[window+1]=sort.a.fout[window+1]/2
    sort.a.x_int[(window+2):(sort.a.M*2*window-window)]=zeros(Complex{Float64},2*sort.a.M*window-2*window-1)
    sort.a.x_int[sort.a.M*2*window-window+1]=sort.a.fout[window+1]/2
    sort.a.x_int[(sort.a.M*2*window-window+2):end]=sort.a.fout[(window+2):end]

    ifft!(sort.a.x_int)
    sort.a.upsamp[:]=sort.a.M.*real(sort.a.x_int)

    j=indmax(sort.a.upsamp[sort.a.align_range])+sort.a.M*window_half
    sort.waveform=view(sort.a.upsamp,j-sort.a.M*window_half:j+sort.a.M*window_half-1)

    return j-window_half:j+window_half-1
end

mysize(align::AlignFFT)=window*align.M
=#
#=
FFT upsampling + temporal order of peaks

Rutishauser 2006
=#
#=
type AlignOsort <: Align

end

function align(a::AlignOsort, sort::Sorting)

end


function mysize(align::AlignOsort)
    window*align.M
end
=#
