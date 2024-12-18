/*
 * Description: Segment two channels and calculate the volume of colocalized objects between them
 * Developed for: Thi Mai Loan, Selimi's team
 * Author: Héloïse Monnet @ ORION-CIRB
 * Date: December 2024
 * Repository: https://github.com/orion-cirb/Orion_Macros.git
 * Dependencies: None
*/

// PARAMETERS TO REVIEW BEFORE LAUNCHING MACRO //
fileExtension = ".nd";

channel1 = 2;
autoThresholdMethod1 = "Triangle";

channel2 = 4;
autoThresholdMethod2 = "Triangle";

minNbObjVoxels = 2;
////////////////////////////////////////////////

// Hide images during macro execution
setBatchMode(true);

// Ask for the images directory
dir_img = getDirectory("Please select a directory containing images to analyze");

// Create results directory
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
dir_result = dir_img + "Results_" + year + "-" + (month+1) + "-" + dayOfMonth + "_" + hour + "-" + minute + "-" + second + File.separator();
if (!File.isDirectory(dir_result)) {
	File.makeDirectory(dir_result);
}

// Get all files in the input directory
list_img = getFileList(dir_img);

// Loop through all files with fileExtension extension
for (i=0; i<list_img.length; i++) {
	 if (endsWith(list_img[i], fileExtension)) {
		print("\n - Analyzing image " + list_img[i] + " -");
	 	imgName = replace(list_img[i], fileExtension, "");

		// Open channel 1
		run("Bio-Formats Importer", "open=["+dir_img+list_img[i]+"] autoscale color_mode=Default specify_range split_channels view=Hyperstack stack_order=XYCZT c_begin="+channel1+" c_end="+channel1+" c_step=1");
		// Segment channel 1
		run("Median...", "radius=1 stack");
		setAutoThreshold(autoThresholdMethod1 + " dark no-reset stack");
		setOption("BlackBackground", true);
		run("Convert to Mask", "method="+autoThresholdMethod1+" background=Dark black");
		saveAs("Tiff", dir_result+imgName+"_maskC1");
		rename("maskC1");
		
		// Open channel 2
		run("Bio-Formats Importer", "open=["+dir_img+list_img[i]+"] autoscale color_mode=Default specify_range split_channels view=Hyperstack stack_order=XYCZT c_begin="+channel2+" c_end="+channel2+" c_step=1");
		// Segment channel 2
		run("Median...", "radius=1 stack");
		setAutoThreshold(autoThresholdMethod2+" dark no-reset stack");
		setOption("BlackBackground", true);
		run("Convert to Mask", "method="+autoThresholdMethod2+" background=Dark black");
		saveAs("Tiff", dir_result+imgName+"_maskC2");
		rename("maskC2");
		
		// Compute channel 1 and channel 2 masks colocalization
		imageCalculator("AND create stack", "maskC1", "maskC2");
		saveAs("Tiff", dir_result+imgName+"_maskColoc");
		
		// Analyze colocalized objects with 3D Objects Counter
		run("3D OC Options", "volume nb_of_obj._voxels dots_size=5 font_size=10 redirect_to=none");
		run("3D Objects Counter", "threshold=128 slice=1 min.="+minNbObjVoxels+" max.=42991616 exclude_objects_on_edges statistics");
		saveAs("Results", dir_result+imgName+"_results.csv");
		
		close("Results");
		close("*");
	 }
}

print("\n - Analysis done! -");

setBatchMode(true);