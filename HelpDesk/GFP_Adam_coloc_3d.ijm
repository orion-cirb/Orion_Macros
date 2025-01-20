/*
 * Description: Segment DAPI, GFP and Adam channels 
 * 				Remove DAPI signal from GFP and Adam binary masks
 * 				Compute colocalization between resulting DAPI-excluded GFP and Adam binary masks
 * Developed for: Thi Mai Loan, Selimi's team
 * Author: Héloïse Monnet @ ORION-CIRB
 * Date: January 2025
 * Repository: https://github.com/orion-cirb/Orion_Macros.git
 * Dependencies: None
*/

// PARAMETERS TO REVIEW BEFORE LAUNCHING MACRO //
fileExtension = ".nd";

channelDapi = 1;
autoThresholdMethodDapi = "Triangle";

channelGfp = 2;
thresholdGfp = 500;

channelAdam = 4;
autoThresholdMethodAdam = "Triangle";
////////////////////////////////////////////////

// Hide images during macro execution
setBatchMode(true);

// Ask for the images directory
inputDir = getDirectory("Please select a directory containing images to analyze");

// Create results directory
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
resultDir = inputDir + "Results_" + year + "-" + (month+1) + "-" + dayOfMonth + "_" + hour + "-" + minute + "-" + second + File.separator();
if (!File.isDirectory(resultDir)) {
	File.makeDirectory(resultDir);
}

// Get all files in the input directory
inputFiles = getFileList(inputDir);

// Create global/branches_length/branches_diam results files and write headers in them
fileResultsGlobal = File.open(resultDir + "results.csv");
print(fileResultsGlobal, "Image name,Slices nb,Gfp background noise,Adam background noise,Gfp volume (µm3),Gfp mean intensity,Adam volume (µm3),Adam mean intensity,Coloc volume (µm3),Coloc mean intensity in Adam channel\n");

// Loop through all files with fileExtension extension
for (i=0; i<inputFiles.length; i++) {
	 if (endsWith(inputFiles[i], fileExtension)) {
		print("Analyzing image " + inputFiles[i] + "...");
	 	imgName = replace(inputFiles[i], fileExtension, "");

		// Open Dapi channel
		run("Bio-Formats Importer", "open=["+inputDir+inputFiles[i]+"] autoscale color_mode=Default specify_range split_channels view=Hyperstack stack_order=XYCZT c_begin="+channelDapi+" c_end="+channelDapi+" c_step=1");
		// Segment channel
		run("Subtract Background...", "rolling=100 sliding stack");
		run("Median...", "radius=10 stack");
		setAutoThreshold("Triangle dark stack");
		setOption("BlackBackground", true);
		run("Convert to Mask", "method=Triangle background=Dark black");
		run("Median...", "radius=2 stack");
		run("Fill Holes", "stack");
		run("Analyze Particles...", "size=10-Infinity circularity=0.5-1.00 show=Masks stack");
		run("Invert LUT");
		rename("maskDapi");
		close("\\Others");
		
		// Open Gfp channel
		run("Bio-Formats Importer", "open=["+inputDir+inputFiles[i]+"] autoscale color_mode=Default specify_range split_channels view=Hyperstack stack_order=XYCZT c_begin="+channelGfp+" c_end="+channelGfp+" c_step=1");
		rename("rawGfp");
		// Estimate background noise
		run("Duplicate...", "title=bgGfp duplicate");
		run("Z Project...", "projection=[Min Intensity]");
		run("Set Measurements...", "median redirect=None decimal=2");
		List.setMeasurements;
		bgGfp = List.getValue("Median");
		close("bgGfp");
		// Segment channel
		selectImage("rawGfp");
		run("Duplicate...", "title=maskGfp duplicate");
		run("Median...", "radius=1 stack");
		setThreshold(500, 65535, "raw");
		run("Convert to Mask", "black");
		run("Median...", "radius=1 stack");
		
		// Open Adam channel
		run("Bio-Formats Importer", "open=["+inputDir+inputFiles[i]+"] autoscale color_mode=Default specify_range split_channels view=Hyperstack stack_order=XYCZT c_begin="+channelAdam+" c_end="+channelAdam+" c_step=1");
		rename("rawAdam");
		// Estimate background noise
		run("Duplicate...", "title=bgAdam duplicate");
		run("Z Project...", "projection=[Min Intensity]");
		run("Set Measurements...", "median redirect=None decimal=2");
		List.setMeasurements;
		bgAdam = List.getValue("Median");
		close("bgAdam");
		// Segment channel
		selectImage("rawAdam");
		run("Duplicate...", "title=maskAdam duplicate");
		run("Median...", "radius=1 stack");
		setAutoThreshold(autoThresholdMethodAdam+" dark no-reset stack");
		setOption("BlackBackground", true);
		run("Convert to Mask", "method="+autoThresholdMethodAdam+" background=Dark black");
		run("Median...", "radius=1 stack");
		
		// Clear nuclei in Gfp and Adam masks
		imageCalculator("Subtract stack", "maskGfp","maskDapi");
		imageCalculator("Subtract stack", "maskAdam","maskDapi");
		
		// Compute Gfp and Adam masks colocalization
		imageCalculator("AND create stack", "maskGfp", "maskAdam");
		rename("maskColoc");
		
		// Save parameters in results file
		params = imgName + "," + nSlices + "," + bgGfp + "," + bgAdam;
		run("3D Manager Options", "volume mean_grey_value distance_between_centers=10 distance_max_contact=1.80 drawing=Contour");
		run("3D Manager");
		masks = newArray("maskGfp", "maskAdam", "maskColoc");
		raws = newArray("rawGfp", "rawAdam", "rawAdam");
		for (j = 0; j < masks.length; j++) {
			Ext.Manager3D_Reset();
			selectImage(masks[j]);
			Ext.Manager3D_AddImage;
			
			Ext.Manager3D_Measure3D(0,"Vol",vol);
			selectImage(raws[j]);
			Ext.Manager3D_Quantif3D(0,"Mean",int);
			params += "," + vol + "," + int;
		}
		print(fileResultsGlobal, params+"\n");
		
		// Save resulting masks
		run("Merge Channels...", "c1=maskDapi c2=maskGfp c3=maskAdam create");
		saveAs("Tiff", resultDir+imgName+"_DapiGfpAdam");
		selectImage("maskColoc");
		saveAs("Tiff", resultDir+imgName+"_Coloc");
		
		close("*");
	 }
}

Ext.Manager3D_Reset();
File.close(fileResultsGlobal);

print("Analysis done!");

setBatchMode(true);