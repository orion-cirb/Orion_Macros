/*
 * Description: Add a scale bar to various channels and save them as separate files
 * Developed for: Tristan, Cohen-Salmon's team
 * Author: Héloïse Monnet @ ORION-CIRB
 * Date: February 2025
 * Repository: https://github.com/orion-cirb/Orion_Macros.git
 * Dependencies: None
*/

// Hide images during macro execution
setBatchMode(true);

// Ask for input directory
inputDir = getDirectory("Please select a directory containing images to analyze");

// Create output directory
outDir = inputDir+"Processed"+File.separator();
if (!File.isDirectory(outDir)) {
	File.makeDirectory(outDir);
}

// Get all files in the input directory
list = getFileList(inputDir);

for (i = 0; i < list.length; i++) {
	if(endsWith(list[i], ".nd2")) {
		// Open image
		run("Bio-Formats Importer", "open=["+inputDir + list[i]+"] autoscale color_mode=Default view=Hyperstack stack_order=XYCZT");
		rename("input.tif");
		
		// Split channels
		run("Split Channels");
		
		// Merge channel 2 (in green) and channel 3 (in red)
		run("Merge Channels...", "c1=C3-input.tif c2=C2-input.tif create ignore keep");
		
		// Add scale bar and save various channels as tif files
		selectImage(2);
		run("Scale Bar...", "width=50 height=50 thickness=5 font=20 bold overlay");
		run("Enhance Contrast", "saturated=0.35");
		saveAs("Tif", outDir+list[i]+"_green");
		
		selectImage(3);
		run("Scale Bar...", "width=50 height=50 thickness=5 font=20 bold overlay");
		run("Enhance Contrast", "saturated=0.35");
		saveAs("Tif", outDir+list[i]+"_red");
		
		selectImage(4);
		run("Scale Bar...", "width=50 height=50 thickness=5 font=20 bold overlay");
		run("Enhance Contrast", "saturated=0.35");
		saveAs("Tif", outDir+list[i]+"_merge");
		
		// Close all windows
		close("*");
	}
}

print("Done!");

setBatchMode(false);
