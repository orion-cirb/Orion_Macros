/*
 * Description: Segment signal from 2 channels, label obtained objects in 3D, and compute the center-center and border-border distance between them
 * Developed for: Maria, Verlhac's team
 * Author: Thomas Caille & Héloïse Monnet @ ORION-CIRB 
 * Date: February 2025
 * Repository: https://github.com/orion-cirb/Orion_Macros/blob/main/HelpDesk/Oocytes_Nucleus_Distances.ijm
 * Dependencies: 3D ImageJ Suite plugin
*/

// PARAMETERS TO REVIEW BEFORE LAUNCHING MACRO //

minObjectVolume_488 = 1; // µm3
minObjectVolume_561 = 3; // µm3

////////////////////////////////////////////////

// Hide on-screen updates for faster macro execution
setBatchMode(true);

// Ask for the images directory
inputDir = getDirectory("Please select a directory containing images to analyze");

// Create results directory
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
resultDir = inputDir+"Results "+year+"-"+(month+1)+"-"+dayOfMonth+"_"+hour+"h"+minute+"m"+second+File.separator();
File.makeDirectory(resultDir);

// Get all files in the input directory
inputFiles = getFileList(inputDir);

// Loop through all files with .nd extension
for (i = 0; i < inputFiles.length; i++) {
    if (endsWith(inputFiles[i], ".nd")) {
    	imgNameNoExt = File.getNameWithoutExtension(inputDir+inputFiles[i]);
    	print("\nAnalyzing image" + imgNameNoExt + "...");
    	
    	// Create results subdirectory
    	imgResultDir = resultDir + imgNameNoExt + File.separator();
    	File.makeDirectory(imgResultDir);
    	// Create csv results file to save objects volume later on
    	volumeResultsFilePath = imgResultDir + "volumes.csv";
    	File.append("Channel, LabelObj, Volume (µm3)", volumeResultsFilePath);
    	
    	// Open image 
    	run("Bio-Formats Importer", "open=["+inputDir + inputFiles[i]+"] autoscale color_mode=Default view=Hyperstack stack_order=XYCZT series_2");
		imgTitle = getTitle();
		// Metadata wrongly saved, correct pixel depth
		getVoxelSize(pixelWidth, pixelHeight, pixelDepth, unit);
		setVoxelSize(pixelWidth, pixelHeight, 0.5, unit);
		// Split channels
		run("Split Channels");
		
		// SEGMENT FIRST CHANNEL (488)
		selectImage("C1-"+imgTitle);
		
		// Preprocessing: smooth channel with median filter
		run("Subtract Background...", "rolling=50 sliding stack");
		run("Median...", "radius=4 stack");
		
		// Automatic thresholding
		setAutoThreshold("MaxEntropy dark stack");
		setOption("BlackBackground", true);
		run("Convert to Mask", "method=MaxEntropy background=Dark black");
		
		// Post-processing: filter out objects with volume smaller than MinVolume_488
		run("Median...", "radius=1 stack");
		// Launch 3D Manager
		run("3D Manager");
		// Convert binary image into labelled one
		Ext.Manager3D_Segment(128, 255);
		rename("C1-labeled");
		// Load obtained 3D objects into 3D manager
		Ext.Manager3D_AddImage();
		// Filter out unwanted objects
		filterOutObjects(minObjectVolume_488, "488");
		
		// Save objects 3D ROIs
		Ext.Manager3D_SelectAll();
		Ext.Manager3D_Save(imgResultDir+"roisObjects_488.zip");
		
		// SEGMENT SECOND CHANNEL (561)
		selectImage("C2-"+imgTitle);
		
		// Preprocessing: smooth channel with median filter
		run("Subtract Background...", "rolling=50 sliding stack");
		run("Median...", "radius=4 stack");
		
		// Automatic thresholding
		setAutoThreshold("MaxEntropy dark stack");
		setOption("BlackBackground", true);
		run("Convert to Mask", "method=MaxEntropy background=Dark black");
		
		// Post-processing: filter out objects with volume smaller than MinVolume_561
		run("Median...", "radius=1 stack");
		// Reset 3D Manager
		Ext.Manager3D_Reset();
		// Convert binary image into labelled one
		Ext.Manager3D_Segment(128, 255);
		rename("C2-labeled");
		// Load obtained 3D objects into 3D manager
		Ext.Manager3D_AddImage();
		// Filter out unwanted objects
		filterOutObjects(minObjectVolume_561, "561");
		
		// Save objects 3D ROIs
		Ext.Manager3D_SelectAll();
		Ext.Manager3D_Save(imgResultDir+"roisObjects_561.zip");
		
		// Compute and save 3D distance between objects in each channel
		run("3D Distances", "image_a=C1-labeled image_b=C2-labeled distance=DistCenterCenterUnit distance_maximum=1000");
		saveAs("results", imgResultDir + "distCenterCenter.csv");
		close("distCenterCenter.csv");
		run("3D Distances", "image_a=C1-labeled image_b=C2-labeled distance=DistBorderBorderUnit distance_maximum=1000");
		saveAs("results", imgResultDir + "distBorderBorder.csv");
		close("distBorderBorder.csv");
		
		// Save labeled images as composite: channel 1 (488) in red and channel 2 (561) in green
		run("Merge Channels...", "c1=C1-labeled c2=C2-labeled create");
		saveAs("tiff", imgResultDir+ "labeledObjects_488-561");
		
		// Close all windows and reset 3D Manager
		close("*");
		Ext.Manager3D_Reset();
    }
}

// Print completion message
print("\nAnalysis done!");

// Restore batch mode to default
setBatchMode(false);


//////////////// FUNCTIONS ////////////////////

// Filter out objects with volume smaller than minVol and objects that appear on only one slice
function filterOutObjects(minVol, channel) {
	Ext.Manager3D_Count(nbObjs);
	print(nbObjs + " objects detected before size filtering");
	
	run("3D Manager Options", "volume bounding_box distance_between_centers=10 distance_max_contact=1.80 drawing=Contour");
	objLabel = 1;
	for(n = 0; n < nbObjs; n++) {
		Ext.Manager3D_Measure3D(n,"Vol",vol);
		Ext.Manager3D_Bounding3D(n,x0,x1,y0,y1,z0,z1);	
		if(vol < minVol || z0 == z1) {
			// Clear object in mask
			Ext.Manager3D_Select(n);
			Ext.Manager3D_FillStack(0, 0, 0);
		} else {
			// Reset object label in mask
			Ext.Manager3D_Select(n);
			Ext.Manager3D_FillStack(objLabel, objLabel, objLabel);
			File.append(channel+","+objLabel+","+vol, volumeResultsFilePath);
			objLabel++;
		}
	}
	Ext.Manager3D_Reset();
	Ext.Manager3D_AddImage();
	setMinAndMax(0, objLabel);
	
	Ext.Manager3D_Count(nbObjs);
	print(nbObjs + " objects detected after size filtering");
}
