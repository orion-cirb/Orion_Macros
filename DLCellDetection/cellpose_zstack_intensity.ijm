/*
 * Description: 
 * 		Detect 3D cells in a channel using the 2D-stitched version of Cellpose
 * 		Compute cells volume and mean intensity in another channel
 * Developed for: Tristan, Cohen-Salmon's team
 * Author: Héloïse Monnet @ ORION-CIRB 
 * Date: January 2025
 * Repository: https://github.com/orion-cirb/Orion_Macros.git
 * Dependencies: 3D ImageJ Suite Fiji plugin + PTBIOP Fiji plugin + Cellpose conda environment
*/


// PARAMETERS TO REVIEW BEFORE LAUNCHING MACRO //
fileExtension = ".nd2";
cellsDetectionChannel = 2;
cellsIntensityChannel = 3;

cellposeEnvPath = "C:/Users/utilisateur/miniconda3/envs/CellPose/";
cellposeModelPath = "C:/Users/utilisateur/.cellpose/models/";
cellposePretrainedModel = false; // Set to true if you use one of the Cellpose pretrained model, false otherwise
cellposeModelName = "cyto2_sox9_p5-15-60_27-11-24";
cellposeDiameter = 35; // pix
cellposeStitchThreshold = 0.5;

cellMinVolume = 50; // µm3
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

// Create a file named "results.csv" and write headers in it
fileResults = File.open(resultDir + "results.csv");
print(fileResults, "Image name,Slices number,Channel "+cellsIntensityChannel+" background noise,Cell label,Cell volume (µm3), Cell mean intensity in channel "+cellsIntensityChannel+"\n");

// Loop through all files with fileExtension extension
for (f = 0; f < inputFiles.length; f++) {
    if (endsWith(inputFiles[f], fileExtension)) {
    	print("- Analyzing image " + inputFiles[f] + " -");
    	
		// Open channel cellsDetectionChannel
    	run("Bio-Formats Importer", "open=["+inputDir + inputFiles[f]+"] autoscale color_mode=Default specify_range split_channels view=Hyperstack stack_order=XYCZT c_begin="+cellsDetectionChannel+" c_end="+cellsDetectionChannel+" c_step=1");
    	rename("cellsDetection");
		nbSlices = nSlices;
		
		// Detect cells with Cellpose
		if(cellposePretrainedModel) {
			run("Cellpose ...", "env_path="+cellposeEnvPath+" env_type=conda model="+cellposeModelName+" model_path=path\\to\\own_cellpose_model diameter="+cellposeDiameter+" ch1=0 ch2=-1 additional_flags=[--use_gpu, --stitch_threshold, "+cellposeStitchThreshold+"]");
		} else {
			run("Cellpose ...", "env_path="+cellposeEnvPath+" env_type=conda model= model_path=["+cellposeModelPath+cellposeModelName+"] diameter="+cellposeDiameter+" ch1=0 ch2=-1 additional_flags=[--use_gpu, --stitch_threshold, "+cellposeStitchThreshold +"]");
		}
		selectImage("cellsDetection-cellpose");
		Stack.setDimensions(1, nbSlices, 1);
		
		// Load detected cells into 3D Manager
		run("3D Manager");
		Ext.Manager3D_Reset();
		selectImage("cellsDetection-cellpose");
		Ext.Manager3D_AddImage();
		Ext.Manager3D_Count(nbCells);
		print(nbCells + " cells detected before size filtering");
		
		// Filter out cells with volume smaller than cellMinVolume and cells that appear on only one slice
		run("3D Manager Options", "volume bounding_box distance_between_centers=10 distance_max_contact=1.80 drawing=Contour");
		cellLabel = 1;
		for(c = 0; c < nbCells; c++) {
			Ext.Manager3D_Measure3D(c,"Vol",vol);
			Ext.Manager3D_Bounding3D(c,x0,x1,y0,y1,z0,z1);			
			if(vol < cellMinVolume || z0 == z1) {
				// Clear cell in mask
				Ext.Manager3D_Select(c);
				Ext.Manager3D_FillStack(0, 0, 0);
			} else {
				// Reset cell label in mask
				Ext.Manager3D_Select(c);
				Ext.Manager3D_FillStack(cellLabel, cellLabel, cellLabel);
				cellLabel++;
			}
		}
		
		// Clear 3D Manager and load only remaining cells
		Ext.Manager3D_Reset();
		Ext.Manager3D_AddImage();
		Ext.Manager3D_Count(nbCells);
		print(nbCells + " cells detected after size filtering");
		
		// Open channel cellsIntensityChannel
    	run("Bio-Formats Importer", "open=["+inputDir + inputFiles[f]+"] autoscale color_mode=Default specify_range split_channels view=Hyperstack stack_order=XYCZT c_begin="+cellsIntensityChannel+" c_end="+cellsIntensityChannel+" c_step=1");
    	rename("cellsIntensity");
    	
    	// Estimate background noise
		run("Duplicate...", "title=cellsIntensity-bg duplicate");
		run("Z Project...", "projection=[Min Intensity]");
		run("Set Measurements...", "median redirect=None decimal=2");
		List.setMeasurements;
		bg = List.getValue("Median");
		
		// Measure and save cells volume and intensity
		selectImage("cellsIntensity");
		for (c = 0; c < nbCells; c++) {
			Ext.Manager3D_Measure3D(c,"Vol",vol);
			Ext.Manager3D_Quantif3D(c,"Mean",int);
			print(fileResults, inputFiles[f]+","+nbSlices+","+bg+","+(c+1)+","+vol+","+int+"\n");
		}

		// Save cells 3D ROIs
		Ext.Manager3D_SelectAll();
		Ext.Manager3D_Save(resultDir+replace(inputFiles[f], fileExtension, "_rois.zip"));
		Ext.Manager3D_Close();
		
		// Save cells mask
		selectImage("cellsDetection-cellpose");
		saveAs("Tiff", resultDir+replace(inputFiles[f], fileExtension, "_mask"));

		// Close all windows
		close("*");
    }
}

File.close(fileResults);
print("- Analysis done! -");

setBatchMode(false);
