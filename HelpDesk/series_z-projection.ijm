/*
 * Description: Open each fluorescent series in .nd files, perform Z-projection, and save each channel as a separate file.
 * Developed for: Maria, Verlhac's team
 * Author: Héloïse Monnet @ ORION-CIRB
 * Date: May 2025
 * Repository: https://github.com/orion-cirb/Orion_Macros.git
 * Dependencies: None
*/

// Hide on-screen updates for faster macro execution
setBatchMode(true);

// Prompt user to select directory containing input images
inputDir = getDirectory("Please select a directory containing images to analyze");

// Generate results directory with timestamp
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
resultDir = inputDir + "z-projection" + "_" + year + "-" + (month+1) + "-" + dayOfMonth + "_" + hour + "-" + minute + "-" + second + File.separator();
if (!File.isDirectory(resultDir)) {
	File.makeDirectory(resultDir);
}

// Retrieve list of all files in input directory
inputFiles = getFileList(inputDir);

// Process each .nd file in the input directory
for (i = 0; i < inputFiles.length; i++) {
    if (endsWith(inputFiles[i], ".nd")) {
    	print("- Analyzing file " + inputFiles[i] + " -");
    	
    	// Retrieve number of series in file
    	run("Bio-Formats Macro Extensions");
		Ext.setId(inputDir + inputFiles[i]);
		Ext.getSeriesCount(seriesCount);
		
		// Process each series in file that contains "Laser" in its name
		for (s = 0; s < seriesCount; s++) {
			Ext.setSeries(s);
			Ext.getSeriesName(seriesName);
			
			if (seriesName.contains("Laser")) {
				imgName = seriesName.replace("; Laser 491 GFP/Laser 642", "");
				imgName = imgName.replace("\"", "");
				print("Analyzing series " + imgName + "...");
				
		    	// Open series
				run("Bio-Formats Importer", "open=["+inputDir + inputFiles[i]+"] autoscale color_mode=Default view=Hyperstack stack_order=XYCZT series_"+s+1);
		
				// Sum slices Z-projection
				run("Z Project...", "projection=[Sum Slices] all");
				rename(imgName);
				
				// Split channels
				run("Split Channels");
								
				// Save two channels in separate files
				selectWindow("C1-"+imgName);
		    	saveAs("Tiff", resultDir+imgName+" C1");
		    	selectWindow("C2-"+imgName);
		    	saveAs("Tiff", resultDir+imgName+" C2");
		    	
				// Close all windows
				close("*");
			}
	    }
    }
}

// Print completion message
print("Analysis done!");

// Restore batch mode to default
setBatchMode(false);
