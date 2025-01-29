/*
 * Description: 
 * 		Detect 3D cells in z-stacks using the 2D-stitched version of Cellpose
 * 		A .roi or a .zip file containing ROI(s) must be provided with each image, otherwise image is not analyzed
 * Developed for: Christophe, Prochiantz's team
 * Author: Héloïse Monnet @ ORION-CIRB 
 * Date: January 2025
 * Repository: https://github.com/orion-cirb/Orion_Macros.git
 * Dependencies: 3D ImageJ Suite Fiji plugin + PTBIOP Fiji plugin + Cellpose conda environment
*/


// PARAMETERS TO REVIEW BEFORE LAUNCHING MACRO //
fileExtension = ".czi";
channel = 3;

cellposeEnvPath = "C:/Users/utilisateur/miniconda3/envs/CellPose/";
cellposeModelPath = "C:/Users/utilisateur/.cellpose/models/";
cellposePretrainedModel = true; // Set to true if you use one of the Cellpose pretrained model, false otherwise
cellposeModelName = "cyto";
cellposeDiameter = 40; // pix
cellposeStitchThreshold = 0.5;

cellMinVolume = 100; // µm3
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

// Create results files and write headers in them
globalResultsPath = resultDir + "globalResults.csv";
globalResults = File.open(globalResultsPath);
print(globalResults, "Image name,Slices nb,ROI name,ROI area (µm2),ROI volume (µm3),Cells number\n");
File.close(globalResults);
cellsResultsPath = resultDir + "cellsResults.csv";
cellsResults = File.open(cellsResultsPath);
print(cellsResults, "Image name,ROI name,Cell name,Cell volume (µm3)\n");
File.close(cellsResults);

// Loop through all files with fileExtension extension
for (f = 0; f < inputFiles.length; f++) {
    if (endsWith(inputFiles[f], fileExtension)) {
    	print("Analyzing image " + inputFiles[f] + "...");
    	
    	// Load ROI(s), if any provided with image
    	roiPath = inputDir + replace(inputFiles[f], fileExtension, "");
    	if(File.exists(roiPath+".roi")) {
    		roiManager("Open", roiPath+".roi");
    	} else if(File.exists(roiPath+".zip")) {
    		roiManager("Open", roiPath+".zip");
    	} else {
    		print("ERROR: No ROI file found, image not analyzed");
    		continue;
    	}
    	
		// Open image
    	run("Bio-Formats Importer", "open=["+inputDir + inputFiles[f]+"] autoscale color_mode=Default split_channels view=Hyperstack stack_order=XYCZT series_1");
    	selectImage(channel);
    	rename("image");
		close("\\Others");
		
		// Retrieve some useful image parameters
		nbSlices = nSlices;
		getVoxelSize(pixWidth, pixHeight, pixDepth, pixUnit);
		
		// Detect cells with Cellpose
		if(cellposePretrainedModel) {
			run("Cellpose ...", "env_path="+cellposeEnvPath+" env_type=conda model="+cellposeModelName+" model_path=path\\to\\own_cellpose_model diameter="+cellposeDiameter+" ch1=0 ch2=-1 additional_flags=[--use_gpu, --stitch_threshold, "+cellposeStitchThreshold+"]");
		} else {
			run("Cellpose ...", "env_path="+cellposeEnvPath+" env_type=conda model= model_path=["+cellposeModelPath+cellposeModelName+"] diameter="+cellposeDiameter+" ch1=0 ch2=-1 additional_flags=[--use_gpu, --stitch_threshold, "+cellposeStitchThreshold +"]");
		}
		selectImage("image-cellpose");
		Stack.setDimensions(1, nbSlices, 1);
		
		// Load detected cells into 3D Manager
		run("3D Manager");
		Ext.Manager3D_Reset();
		selectImage("image-cellpose");
		Ext.Manager3D_AddImage();
		Ext.Manager3D_Count(nbCells);
		
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
		
		// Save results for each ROI
		setBackgroundColor(0, 0, 0);
		for(r=0; r < roiManager("count"); r++) {
			// Clear outside ROI to only keep cells in it
			selectImage("image-cellpose");
			run("Duplicate...", "title=image-cellpose-"+r+" ignore duplicate");
			roiManager("select", r);
			run("Clear Outside", "stack");
			
			// Clear 3D Manager and load remaining cells
			Ext.Manager3D_Reset();
			Ext.Manager3D_AddImage();
			Ext.Manager3D_Count(nbCells);
			
			// Save global parameters
			roiName = RoiManager.getName(r);
			List.setMeasurements;
			roiArea = List.getValue("Area");
			roiVolume = roiArea*nbSlices*pixDepth;
			File.append(inputFiles[f]+","+nbSlices+","+roiName+","+roiArea+","+roiVolume+","+nbCells, globalResultsPath);
			
			// Save cells parameters
			for (c = 0; c < nbCells; c++) {
				Ext.Manager3D_Measure3D(c,"Vol",vol);
				Ext.Manager3D_GetName(c, name);
				File.append(inputFiles[f]+","+roiName+","+name+","+vol, cellsResultsPath);
			}

			// Save cells 3D ROIs
			Ext.Manager3D_SelectAll();
			Ext.Manager3D_Save(resultDir+replace(inputFiles[f], fileExtension, "_"+roiName+".zip"));
			Ext.Manager3D_Close();
			
			close("image-cellpose-"+r);
		}
		
		// Save cells mask in all ROIs
		roiManager("deselect");
		roiManager("Combine");
		run("Clear Outside", "stack");
		run("Select None");
		setMinAndMax(0, 200);
		saveAs("Tiff", resultDir+replace(inputFiles[f], fileExtension, ""));

		// Close all windows
		close("*");
		roiManager("reset");
		close("ROI Manager");
    }
}

print("Analysis done!");

setBatchMode(false);
