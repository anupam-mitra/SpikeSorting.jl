
#=
Feature extraction methods. Each method needs
1) Type with fields necessary for algorithm
2) function "feature" to operate on sort with type field defined above
3) any other necessary functions for extraction algorithm

=#

export FeatureTime, FeaturePCA, FeatureIT, FeatureDDMDT

function featureprepare{D<:Detect,C<:Cluster,A<:Align,F<:Feature,R<:Reduction}(sort::Sorting{D,C,A,F,R})
    nothing
end

#=
Temporal Waveform
=#

type FeatureTime <: Feature 
end

function FeatureTime(N::Int64)
    FeatureTime()
end

function feature{D<:Detect,C<:Cluster,A<:Align,F<:FeatureTime,R<:Reduction}(sort::Sorting{D,C,A,F,R})
    sort.features[:]=sort.waveforms[sort.dims,sort.numSpikes]
    nothing
end

function mysize(feature::FeatureTime,wavelength::Int64)
    wavelength
end

#=
online PCA
=#

type FeaturePCA <: Feature
    oPCA::OnlineStats.OnlinePCA
end

function FeaturePCA()
    FeaturePCA(OnlineStats.OnlinePCA(window,4))
end

function FeaturePCA(N::Int64)
    FeaturePCA(OnlineStats.OnlinePCA(N,4))
end

function FeaturePCA(win::Int64,dims::Int64)
    FeaturePCA(OnlineStats.OnlinePCA(win,dims))
end

function feature{D<:Detect,C<:Cluster,A<:Align,F<:FeaturePCA,R<:Reduction}(sort::Sorting{D,C,A,F,R})
    OnlineStats.update!(sort.f.oPCA,sort.waveforms[:,sort.numSpikes])
    sort.features[:]=sort.f.oPCA.V*sort.waveforms[:,sort.numSpikes]
    nothing
end

function mysize(feature::FeaturePCA,wavelength::Int64)
    feature.oPCA.k
end

#=
Wavelet
=#

type FeatureWPD <: Feature
end

function feature{D<:Detect,C<:Cluster,A<:Align,F<:FeatureWPD,R<:Reduction}(sort::Sorting{D,C,A,F,R})
    #a=2^i where i = 1:L and L=log2(N) where N is signal length

end

function mysize(feature::FeatureWPD,wavelength::Int64)
    feature.oPCA.k
end

#=
Integral Transform

Zviagintsev et al 2006
=#

type FeatureIT <: Feature
    N1::Int64
    N2::Int64
    wavemean::Float64
    itr::Int64
    tbeta::Int64
    talpha::Int64
end

function FeatureIT()
    FeatureIT(0,0,0.0,0,0,0)
end

function FeatureIT(N::Int64)
    FeatureIT(0,0,0.0,0,0,0)
end

function feature{D<:Detect,C<:Cluster,A<:Align,F<:FeatureIT,R<:Reduction}(sort::Sorting{D,C,A,F,R})
    
    sort.features[:]=zeros(Float64,length(sort.features))
    for i=sort.f.talpha:(sort.f.talpha+sort.f.N1)
        sort.features[1]+=sort.waveforms[i,sort.numSpikes]
    end
    sort.features[1]=sort.features[1]/sort.f.N1

    for i=sort.f.tbeta:(sort.f.tbeta+sort.f.N2)
        sort.features[2]+=sort.waveforms[i,sort.numSpikes]
    end
    sort.features[2]=sort.features[2]/sort.f.N2
    
    nothing
end

function mysize(feature::FeatureIT,wavelength::Int64)
    2
end

function featureprepare{D<:Detect,C<:Cluster,A<:Align,F<:FeatureIT,R<:Reduction}(sort::Sorting{D,C,A,F,R})

    sort.f.wavemean=mean(sort.waveforms[:,sort.numSpikes])
    tempN1=0
    tempN2=0
    thisval=0
    lastval=0
    N1=0
    N2=0
    talpha=0
    talphat=0
    tbeta=0
    tbetat=0
    
    for i=1:size(sort.waveforms,1)

        thisval=sign(sort.waveforms[i,sort.numSpikes]-sort.f.wavemean)
        if thisval==lastval
            if thisval==1
                tempN2+=1
                if tempN2>N2
                    N2=tempN2
                    tbeta=tbetat
                end
            else
                tempN1+=1
                if tempN1>N1
                    N1=tempN1
                    talpha=talphat
                end
            end  
        else
            if thisval==1
                tempN2=1
                tbetat=i
            else
                tempN1=1
                talphat=i
            end            
        end
        lastval=thisval
    end

    if sort.f.itr==0
        sort.f.N1=N1
        sort.f.N2=N2
        sort.f.talpha=talpha
        sort.f.tbeta=tbeta
    else
        sort.f.N1=round((sort.f.itr/(sort.f.itr+1))*sort.f.N1+(1/(sort.f.itr+1))*N1)
        sort.f.N2=round((sort.f.itr/(sort.f.itr+1))*sort.f.N2+(1/(sort.f.itr+1))*N2)
        sort.f.talpha=round((sort.f.itr/(sort.f.itr+1))*sort.f.talpha+(1/(sort.f.itr+1))*talpha)
        sort.f.tbeta=round((sort.f.itr/(sort.f.itr+1))*sort.f.tbeta+(1/(sort.f.itr+1))*tbeta)
    end

    if sort.f.N1+sort.f.talpha>size(sort.waveforms,1)
        sort.f.N1=size(sort.waveforms,1)-sort.f.talpha-1
    end
    if sort.f.N2+sort.f.tbeta>size(sort.waveforms,1)
        sort.f.N2=size(sort.waveforms,1)-sort.f.tbeta-1
    end
    

    sort.f.itr+=1
    
    nothing
    
end

#=
Discrete Derivatives - Maximum Difference Test

Gibson et al 2010
=#

type FeatureDDMDT <: Feature
    maximum_difference::Array{Int64,1}
    local_difference::Array{Float64,1}
    spike_new::Array{Float64,1}
    spike_old::Array{Float64,1}
    D::Array{Int64,1}
    Dc::Array{Int64,1}
end

function FeatureDDMDT()
    FeatureDDMDT(zeros(Int64,10),zeros(Float64,10),zeros(Float64,10),zeros(Float64,10),zeros(Int64,10),zeros(Int64,10))
end

function FeatureDDMDT(N::Int64)

    sizeN=0

    for i=1:length(DD_inds)
        sizeN+=N-DD_inds[i]
    end
    
    FeatureDDMDT(zeros(Int64,sizeN),zeros(Float64,sizeN),zeros(Float64,sizeN),zeros(Float64,sizeN),zeros(Int64,10),zeros(Int64,10))
end

function feature{D<:Detect,C<:Cluster,A<:Align,F<:FeatureDDMDT,R<:Reduction}(sort::Sorting{D,C,A,F,R})
    
    nothing
end

function mysize(feature::FeatureDDMDT,wavelength::Int64)
    10
end

function featureprepare{D<:Detect,C<:Cluster,A<:Align,F<:FeatureDDMDT,R<:Reduction}(sort::Sorting{D,C,A,F,R})

    counter=1
    max3ind=zeros(Int64,3)
    
    for i in DD_inds
        for j=(i+1):size(sort.waveforms,1)
            sort.f.spike_new[counter]=sort.waveforms[j,sort.numSpikes]-sort.waveforms[j-i,sort.numSpikes]
            sort.f.local_difference[counter]=abs(sort.f.spike_old[counter]-sort.f.spike_new[counter])

            if sort.f.local_difference[counter]>max3ind[1]
                if sort.f.local_difference[counter]>max3ind[2]
                    if sort.f.local_difference[counter]>max3ind[3]
                        max3ind[1]=max3ind[2]
                        max3ind[2]=max3ind[3]
                        max3ind[3]=counter
                    end
                    max3ind[1]=max3ind[2]
                    max3ind[2]=counter
                end
                max3ind[1]=counter
            end
            
            counter+=1
        end
    end

    sort.f.maximum_difference[max3ind]+=1

    sort.f.spike_old[:]=sort.f.spike_new[:]

    #Need to fix this so there are no duplicates
    for i=1:3
        (mymin,myindex)=findmin(sort.f.Dc)
        if sort.f.maximum_difference[max3ind[i]]>mymin
            if max3ind[i]!=sort.f.D[myindex]
                sort.f.Dc[myindex]=sort.f.maximum_difference[max3ind[i]]
                sort.f.D[myindex]=max3ind[i]
            end     
        end
    end
  
    nothing
end
