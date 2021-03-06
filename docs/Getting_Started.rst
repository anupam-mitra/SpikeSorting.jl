
################
Getting Started
################

SpikeSorting.jl is a Julia implementation of many spike sorting algorithms for neural electrophysiology data. The goal of this project is to design a framework which allows for easy use in 1) real time applications, 2) large scale cluster computing and 3) benchmarking multiple methods against one another. The Julia Language keeps the syntax readible while also allowing for near C performance.

*********
Overview
*********

The process of "spike sorting" takes an analog, extracellular voltage trace, and determines what components of the signal correpond to electrical activity from nearby neurons. A general workflow for spike sorting would be to 1) detect canidate spikes 2) align candidate spikes 3) extract meaningful features from this signal 4) reduce the dimensionality from a high dimensional feature space to those dimensions which are most meaningful for discrimination and 5) clustering spikes with similar features.

SpikeSorting.jl employs this modular framework, such that one method in a step is compatible with most other existing methods in previous or subsequent steps. 

================
Data Structures
================

---------------------
Analog Voltage Input
---------------------

The methods of SpikeSorting.jl expect to operator on a 2D (M time x N channels) matrix of voltage values. 

---------
Sorting
---------

The primary data structure is the Sorting type, which contains the variables necessary for individual methods in the spike sorting workflow outlined above, as well as variables common to all of the methods. An instance of sorting is initialized by providing the desired method for each step in the workflow. For instance:

.. code-block:: julia

	detection=DetectPower() #Power-based spike detection
	alignment=AlignMax()	#Align candidate spikes by their maximum voltage
	feature=FeatureTime()	#Chose time varying voltage signal as feature
	reduction=Reduction()	#Use all time points for clustering steps
	cluster=ClusterOSort()	#OSort style clustering (compare clusters with candidate spikes by euclidean distance)

	mysort=Sorting(detection,cluster,alignment,feature,reduction)

In the example above, the detection container of type DetectPower will store all of the necessary variables for power-style detection to take place. Because of the modularity, these data containers can be relatively simple, as is the case with power detection:

.. code-block:: julia

	type DetectPower <: Detect
    		a::Int64
    		b::Int64
    		c::Int64
	end

---------------
Output Buffers
---------------

Spikes are characterized by their location in the input voltage array, as well as the cluster they are assigned to. This idea is captured by the Spike type:

.. code-block:: julia

	immutable Spike
    		inds::UnitRange{Int64}
    		id::Int64
	end

For online sorting, an output buffer is used to temporarily store newly detected spikes before they are written to disk. Two buffers are used: one to keep record of the spikes detected, and one to keep track of the number of spikes detected on each channel. These can be created with the output_buffer function:

.. code-block:: julia

	channel_num = 64 # number of channels

	(buf,nums)=output_buffer(channel_num);
	#buf is 100 x 64 array of Spike type, all initialized to (0:0, 0)
	#nums is a 64 index array with each element initialized to 0


=========
Workflow
=========

Most algorithms require some period of calibration, such as determining the appropriate threshold for detection, or the most discriminatory features to use for clustering. Therefore, some portion of data will need to be used for training. In real time acquisition, this would be the first data collected. For post hoc analysis, this would be some, or all of the data, and then the full dataset can be used after.

===============
Single Channel
===============

To create an instance of spike sorting for a single channel, a complete Sorting type must first be instantiated:

.. code-block:: julia

	detection=DetectPower() #Power-based spike detection
	alignment=AlignMax()	#Align candidate spikes by their maximum voltage
	feature=FeatureTime()	#Chose time varying voltage signal as feature
	reduction=Reduction()	#Use all time points for clustering steps
	cluster=ClusterOSort()	#OSort style clustering (compare clusters with candidate spikes by euclidean distance)

	s = Sorting(detection,cluster,alignment,feature,reduction)

To use the your sorting instance, you need a collection of analog voltage signals. This is assumed to be stored in a m x n matrix of Int64s, where m is the length of the sampling period, and n is the number of channels. Most methos for spike sorting require some calibration period, which is called with the cal! method. In addition, the first time you process signals with a new sorting instance, several methods that don't run everytime you calibrate (such as setting a threshold) need to be run; you can invoke these by setting the "firstrun" flag in the cal! method equal to true. Once you have finished calibration, you can call the onlinesort! method.

.. code-block:: julia

	#Single channel sorting workflow. v is assumed to be an m x 1 vector of voltage values

	#Create output buffers for single channel
	(buf1,nums1)=output_buffer(1);
	
	#First collect voltage trace

	#Call calibration with first run flag
	cal!(s,v,buf1,nums1,true)

	#Define some flag to determine when you want to switch from calibration to online sorting
	while (calibrate==true)

	#collect next voltage traces and overwrite v

		#Call calibration methods
		cal!(s,v,buf1,nums1)

	end

	#Once calibration is finished, you can perform online sorting instead for incoming data
	while (sorting==true)
		onlinesort!(s,v,buf1,nums1)
	end


==================
Multiple Channels
==================

The same methods have also been designed to work with m x n voltage arrays, where n > 1. First, an array of Sorting types needs to be created, which can be invoked with the create_multi method:

.. code-block:: julia

	num_channels=64 

	s2=create_multi(detection,cluster,alignment,feature,reduction, num_channels);

	(buf2,nums2)=output_buffer(num_channels);

Now the same processing methods can be called on a 64 column voltage array:

.. code-block:: julia

	cal!(s2,v,buf2,nums2,true); #first run flag set to true
	cal!(s2,v,buf2,nums2);
	onlinesort!(s2,v,buf2,nums2);


************
Parallelism
************

If multiple channels of extracellular recordings are collected simultaneously, and these channels are sufficiently far apart, as is common with multi-electrode arrays, then the spike sorting of each channel can be considered "embarassingly parallel" whereby the sorting of one channel has no impact on another. Right now, SpikeSorting.jl is designed around this principle and can create a Distributed Array of multiple Sorting instances. In this way, each core of a computer or cluster "owns" all of the data in a collection of Sorting instances, and can quickly and independent process channels without message passing back and forth

===============
Implementation
===============

Parallel multi-channel processing works almost identically to single core multi-channel. To create the multi-channel array, specify the parallel flag to be true during initialization:

.. code-block:: julia

	num_channels=64 

	s3=create_multi(detection,cluster,alignment,feature,reduction, num_channels, true);
	(buf3,nums3)=output_buffer(num_channels,true);

Now rather than an array of Sorting instance, mysort3 is a Distributed Array of Sorting instances. This can be applied to all of the processing methods as above:

.. code-block:: julia

	cal!(s3,v,buf3,nums3,true); #first run flag set to true
	cal!(s3,v,buf3,nums3);
	onlinesort!(mysort3,v,buf3,nums3);

The code above above may not actually be faster, however, because the matrix v has to be copied to each process during each interation. To get around this, you can store your voltage values in a SharedArray:

.. code-block:: julia

	v2=convert(SharedArray{Int64,2},v);
	cal!(mysort3,v2,buf3,nums3,true); #first run flag set to true
	cal!(mysort3,v2,buf3,nums3);
	onlinesort!(mysort3,v2,buf3,nums3);

**********************
Real-Time Application
**********************

SpikeSorting.jl is being designed to work on real time incoming electrophysiology using a Julia wrapper for Intan evaluation boards:

https://github.com/paulmthompson/Intan.jl



*************
Benchmarking
*************


