// Hide on-screen updates for faster macro execution
setBatchMode(true);

// Prompt user to select directory containing input images
inputDir = getDirectory("Please select a directory containing images to analyze");

// Generate results directory with timestamp
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
resultDir = inputDir + "Results_" + year + "-" + (month+1) + "-" + dayOfMonth + "_" + hour + "-" + minute + "-" + second + File.separator();
if (!File.isDirectory(resultDir)) {
	File.makeDirectory(resultDir);
}

// Retrieve list of all files in input directory
inputFiles = getFileList(inputDir);

// Process each .TIF file in the input directory
for (i = 0; i < inputFiles.length; i=i+1) {
    if (endsWith(inputFiles[i], ".tif")) {
    	print("Analyzing image " + inputFiles[i] + "...");
    	imgName = replace(inputFiles[i], ".tif", "");
    	
    	// Open the current image
    	open(inputDir + inputFiles[i]);
    	
    	// Preprocess image
    	// Example: run("Median...", "radius=2");
    	// INSERT YOUR CODE HERE
    	
    	// Segment image
    	// Example: setAutoThreshold("Otsu dark");
        //          setOption("BlackBackground", true);
        //          run("Convert to Mask");
    	// INSERT YOUR CODE HERE
    	
    	// Postprocess segmentation result
    	// Example: run("Fill Holes");
    	// INSERT YOUR CODE HERE
		
		// Set measurements
		// Example: run("Set Measurements...", "area redirect=None decimal=0");
		// INSERT YOUR CODE HERE
		
		// Analyze Particles
		// Example: run("Analyze Particles...", "size=100-Infinity display exclude clear add");
		// INSERT YOUR CODE HERE
		
		// Save results
		// Example: saveAs("Results", resultDir+imgName+"_results.csv");
		//			roiManager("Save", resultDir+imgName+"_rois.zip");
		// INSERT YOUR CODE HERE
		
		// Close all open windows
		close("*");
    }
}

// Print completion message
print("Analysis done!");

// Restore batch mode to default
setBatchMode(false);