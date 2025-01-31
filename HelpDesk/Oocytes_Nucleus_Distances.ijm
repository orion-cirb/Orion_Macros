/*
 * Description: Segment signal from 2 channels, recoup 3D object, calcul the CenterCenter and Border Border distance between them
 * Developed for: Maria
 * Author: Thomas Caille & Héloïse Monnet @ ORION-CIRB 
 * Date: January 2025
 * Repository: https://github.com/orion-cirb/Orion_Macros/tree/main/HelpDesk
 * Dependencies: 3D ImageJ Suite Plug-in
*/



// Hide on-screen updates for faster macro execution
setBatchMode(true);

// Ask for the images directory
inputDir = getDirectory("Please select a directory containing images to analyze");

getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
resultDir = inputDir + "Results" + File.separator();
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
    	// Open the fluorescent image 
    	run("Bio-Formats Importer", "open=["+inputDir + inputFiles[i]+"] autoscale color_mode=Default view=Hyperstack stack_order=XYCZT series_2");
    	print("\n - Analyzing image " + nameNoExt + " -");
		title = getTitle();
		
		// Matadata are bugged, calibration is needed
		run("Properties...", "channels=2 slices="+(nSlices/2)+" frames=1 pixel_width=0.1030000 pixel_height=0.1030000 voxel_depth=0.5");
		run("Split Channels");
		selectImage("C1-"+title);
		
		// Préprocessing : smooth the image with median filter
		run("Median...", "radius=3 stack");
		
		// Processing : segmentation with autothreshold, best results with MaxEntropy
		setAutoThreshold("MaxEntropy dark stack");
		setOption("BlackBackground", true);
		run("Convert to Mask", "black");
		
		// Processing : segmentation with autothreshold, best results with MaxEntropy
		run("Options...", "iterations=2 count=3 black do=Open stack");
		run("Options...", "iterations=3 count=1 black do=Close stack");
		
		// Launch and add the first channel to the 3D manager
		run("3D Manager");
		Ext.Manager3D_AddImage();
		Ext.Manager3D_Segment(128, 255);
		
		// Save the first channel 3D mask
		saveAs("tiff", imageResultDir+ "3D-Labeled_image_C1");
		
		// Work on the second channel
		selectImage("C2-"+ title);
		
		// Préprocessing : smooth the image with median filter
		run("Median...", "radius=3 stack");
		
		// Processing : segmentation with autothreshold, best results with MaxEntropy
		setAutoThreshold("MaxEntropy dark stack");
		setOption("BlackBackground", true);
		run("Convert to Mask", "black");
		
		//Post processing : work on the binary image 
		run("Options...", "iterations=2 count=3 black do=Open stack");
		run("Options...", "iterations=3 count=1 black do=Close stack");
		
		// Launch and add the second channel to the 3D manager
		run("3D Manager");
		Ext.Manager3D_AddImage();
		Ext.Manager3D_Segment(128, 255);
		
		// Save the 2nd channel 3D mask
		saveAs("tiff", imageResultDir+ "3D-Labeled_image_C2");
		
		// Calcul the 3D distance between objects and save the results tables
		run("3D Distances", "image_a=3D-Labeled_image_C1 image_b=3D-Labeled_image_C2 distance=DistCenterCenterUnit distance_maximum=1000");
		saveAs("results", imageResultDir + "DistCenterCenter.csv");
		close("DistCenterCenter.csv");
		run("3D Distances", "image_a=3D-Labeled_image_C1 image_b=3D-Labeled_image_C2 distance=DistBorderBorderUnit distance_maximum=1000");
		saveAs("results", imageResultDir + "DistBorderBorder.csv");
		
		// Close all windows
		close("DistBorderBorder.csv");
		Ext.Manager3D_Reset();
		close("*");
		
    }
    
}
// Print completion message
print("Analysis Done!");
// Restore batch mode to default
setBatchMode(false);