/*
 * Description: Segment channel and calculate segmented volume within the provided ROI, 
 *              or across the entire image if no ROI is provided.
 * Developed for: Brenda, Selimi's team
 * Author: Héloïse Monnet @ ORION-CIRB
 * Date: December 2024
 * Repository: https://github.com/orion-cirb/Orion_Macros.git
 * Dependencies: 3D ImageJ Suite Fiji plugin
*/

// PARAMETERS TO REVIEW BEFORE LAUNCHING MACRO //
fileExtension = ".nd2";
channel = 2;
autoThresholdMethod = "Default";
objectMeanVolume = 125; // µm3
////////////////////////////////////////////////

// Hide on-screen updates for faster macro execution
setBatchMode(true);

// Prompt user to select directory containing input images
inputDir = getDirectory("Please select a directory containing images to analyze");

// Generate results directory with timestamp
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
resultDir = inputDir + "Results_ch" + channel + "_" + autoThresholdMethod + "_" + year + "-" + (month+1) + "-" + dayOfMonth + "_" + hour + "-" + minute + "-" + second + File.separator();
if (!File.isDirectory(resultDir)) {
	File.makeDirectory(resultDir);
}

// Retrieve list of all files in input directory
inputFiles = getFileList(inputDir);

// Create a file named "results.csv" and write headers in it
fileResults = File.open(resultDir + "results.csv");
print(fileResults, "Image name,ROI volume (µm3),Segmented volume (µm3),Estimated number of objects\n");

// Process each file with fileExtension extension in the input directory
for (i = 0; i < inputFiles.length; i=i+1) {
    if (endsWith(inputFiles[i], fileExtension)) {
    	print("- Analyzing image " + inputFiles[i] + " -");
    	imgName = replace(inputFiles[i], fileExtension, "");
    	
    	// Open channel
		run("Bio-Formats Importer", "open=["+inputDir + inputFiles[i]+"] autoscale color_mode=Default specify_range split_channels view=Hyperstack stack_order=XYCZT c_begin="+channel+" c_end="+channel+" c_step=1");

		// Preprocess image
		run("Median...", "radius=5 stack");

		// Segment image
		setAutoThreshold(autoThresholdMethod+" dark stack");
		setOption("BlackBackground", true);
		run("Convert to Mask", "method="+autoThresholdMethod+" background=Dark black");

		// Postprocess segmentation mask
		run("Median...", "radius=5 stack");

		// Open ROI (if any provided) and clear mask outside
		roiName = inputDir + imgName + ".roi";
		if(File.exists(roiName)) {
			open(roiName);
			run("Clear Outside", "stack");			
		} else {
			print("WARNING: no ROI provided, analysis performed in entire image");
		}
		
		// Compute ROI volume (if any provided), or the volume of the entire image
		getStatistics(area, mean, min, max, std, histogram);
		getVoxelSize(width, height, depth, unit);
		roiVolume = area * nSlices * depth;
		run("Select None");
		
		// Save mask
    	saveAs("Tiff", resultDir+imgName);
    	rename("mask");

		// Load mask into 3D ImageJ Suite
		run("3D Manager");
		Ext.Manager3D_Reset();
		selectImage("mask");
		Ext.Manager3D_AddImage();
		
		// Measure and save mask volume
		run("3D Manager Options", "volume distance_between_centers=10 distance_max_contact=1.80 drawing=Contour display");
		Ext.Manager3D_Measure();
		print(fileResults, imgName+","+roiVolume+","+getResult("Vol (unit)", 0)+","+Math.round(getResult("Vol (unit)", 0)/objectMeanVolume)+"\n");
		Ext.Manager3D_Close();

		// Close all windows
		close("*");
		close("Results");
		close("MeasureTable");
    }
}

// Print completion message
print("Analysis done!");

// Restore batch mode to default
setBatchMode(false);