/*
 * Description: Segment signal from 2 channels, recoup 3D object, calcul the CenterCenter and Border Border distance between them
 * Developed for: Maria
 * Author: Thomas Caille & Héloïse Monnet @ ORION-CIRB 
 * Date: January 2025
 * Repository: https://github.com/orion-cirb/Orion_Macros/tree/main/HelpDesk/Oocytes_Nucleus_Distances.ijm
 * Dependencies: 3D ImageJ Suite Plug-in
*/

MinVolume_488 = 1;
MinVolume_561 = 3;

// Hide on-screen updates for faster macro execution
setBatchMode(true);

// Ask for the images directory
inputDir = getDirectory("Please select a directory containing images to analyze");

getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
resultDir = inputDir + "Results "+ month +"_"+ dayOfMonth +"_"+ hour +"h"+ minute + File.separator();
if (!File.isDirectory(resultDir)) {
	File.makeDirectory(resultDir);
}

inputFiles = getFileList(inputDir);



// Loop through all files with .nd extension
for (i = 0; i < inputFiles.length; i++) {
    if (endsWith(inputFiles[i], ".nd")) {
    	// Makeresults directory
    	nameNoExt = File.getNameWithoutExtension(inputDir+inputFiles[i]);
    	imageResultDir = resultDir + nameNoExt + File.separator();
    	File.makeDirectory(imageResultDir);
    	volumeResultsFilePath = imageResultDir + "Volumes.csv";
    	// Open the fluorescent image 
    	run("Bio-Formats Importer", "open=["+inputDir + inputFiles[i]+"] autoscale color_mode=Default view=Hyperstack stack_order=XYCZT series_2");
    	print("\n - Analyzing image " + nameNoExt + " -");
		title = getTitle();
		
		// Matadata are bugged, calibration is needed
		getPixelSize(unit, pixelWidth, pixelHeight);
		run("Properties...", "channels=2 slices="+(nSlices/2)+" frames=1 pixel_width="+pixelWidth+" pixel_height="+pixelHeight+" voxel_depth=0.5");
		run("Split Channels");
		selectImage("C1-"+title);
		
		// Preprocessing : smooth the image with median filter
		run("Subtract Background...", "rolling=50 sliding stack");
		run("Median...", "radius=4 stack");
		
		// Processing : segmentation with autothreshold, best results with MaxEntropy
		setAutoThreshold("MaxEntropy dark stack");
		setOption("BlackBackground", true);
		run("Convert to Mask", "method=MaxEntropy background=Dark black");
		
		// Launch and add the first channel to the 3D manager
		run("3D Manager");
		run("3D Manager Options", "volume bounding_box distance_max_contact=1.80 drawing=Contour display");
		Ext.Manager3D_Segment(128, 255);
		Ext.Manager3D_AddImage();
		
		Ext.Manager3D_Count(nbCells);
		print(nbCells + " cells detected before size filtering");
		
		File.append("channel 488 :",volumeResultsFilePath );
		File.append(" ",volumeResultsFilePath );
		// Filter out cells with volume smaller than cellMinVolume and cells that appear on only one slice
		cellLabel = 1;
		Ext.Manager3D_Measure();
		for(c = 0; c < nbCells; c++) {
			vol = getResult("Vol (unit)", c);
			zmin = getResult("Zmin (pix)", c);
			zmax = getResult("Zmax (pix)", c);
			if(vol < MinVolume_488 || zmin == zmax) {
				// Clear cell in mask
				Ext.Manager3D_Select(c);
				Ext.Manager3D_FillStack(0, 0, 0);
			} else {
				// Reset cell label in mask
				Ext.Manager3D_Select(c);
				Ext.Manager3D_FillStack(cellLabel, cellLabel, cellLabel);
				cellLabel++;
				File.append(cellLabel-1+","+vol+",",volumeResultsFilePath );
			}
		}
		Ext.Manager3D_Reset();
		Ext.Manager3D_AddImage();
		Ext.Manager3D_Count(nbCells);
		print(nbCells + " cells detected after size filtering");
			
		// Save the first channel 3D mask
		saveAs("tiff", imageResultDir+ "3D-Labeled_image_C1");
		Ext.Manager3D_Reset();		
		
		// Work on the second channel
		selectImage("C2-"+ title);
		
		// Preprocessing : smooth the image with median filter
		run("Subtract Background...", "rolling=50 sliding stack");
		run("Median...", "radius=4 stack");
		
		// Processing : segmentation with autothreshold, best results with MaxEntropy
		setAutoThreshold("MaxEntropy dark stack");
		setOption("BlackBackground", true);
		run("Convert to Mask", "method=MaxEntropy background=Dark black");
		
		// Launch and add the second channel to the 3D manager
		run("3D Manager Options", "volume bounding_box distance_max_contact=1.80 drawing=Contour display");
		Ext.Manager3D_Segment(128, 255);
		Ext.Manager3D_AddImage();	
		Ext.Manager3D_Count(nbCells);
		print(nbCells + " cells detected before size filtering");
		File.append("channel 561 :",volumeResultsFilePath );
		File.append(" ",volumeResultsFilePath );
		
		// Filter out cells with volume smaller than cellMinVolume and cells that appear on only one slice
		cellLabel = 1;
		Ext.Manager3D_Measure();
		for(c = 0; c < nbCells; c++) {
			vol = getResult("Vol (unit)", c);
			zmin = getResult("Zmin (pix)", c);
			zmax = getResult("Zmax (pix)", c);
			if(vol < MinVolume_561 || zmin == zmax) {
				// Clear cell in mask
				Ext.Manager3D_Select(c);
				Ext.Manager3D_FillStack(0, 0, 0);
			} else {
				// Reset cell label in mask
				Ext.Manager3D_Select(c);
				Ext.Manager3D_FillStack(cellLabel, cellLabel, cellLabel);
				cellLabel++;
				File.append(cellLabel-1+","+vol+",",volumeResultsFilePath );
			}
		}
		Ext.Manager3D_Reset();
		Ext.Manager3D_AddImage();
		Ext.Manager3D_Count(nbCells);
		print(nbCells + " cells detected after size filtering");
		
		// Save the 2nd channel 3D mask
		saveAs("tiff", imageResultDir+ "3D-Labeled_image_C2");
		
		// Calcul the 3D distance between objects and save the results tables
		run("3D Distances", "image_a=3D-Labeled_image_C1 image_b=3D-Labeled_image_C2 distance=DistCenterCenterUnit distance_maximum=1000");
		saveAs("results", imageResultDir + "DistCenterCenter.csv");
		close("DistCenterCenter.csv");
		run("3D Distances", "image_a=3D-Labeled_image_C1 image_b=3D-Labeled_image_C2 distance=DistBorderBorderUnit distance_maximum=1000");
		saveAs("results", imageResultDir + "DistBorderBorder.csv");
		
		// Save a Composite with channel1(red) = 561 and channel2(green) = 488
		run("Merge Channels...", "c1=3D-Labeled_image_C2.tif c2=3D-Labeled_image_C1.tif create");
		saveAs("tiff", imageResultDir+ "3D-Composite_image");
		
		// Close all windows and reset Tables
		close("DistBorderBorder.csv");
		Ext.Manager3D_Reset();
		Table.reset("MeasureTable");
		Table.reset("DistBorderBorder.csv");
		close("*");
		
    }
    
}
// Print completion message
print("Analysis Done!");
// Restore batch mode to default
setBatchMode(false);