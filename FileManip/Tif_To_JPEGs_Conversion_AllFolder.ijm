// Save all slices of a stack as separate jpeg images
// As RGB image if there are several chanels
// Process all folder

// ORION CIRB

requires("1.52t");

dir = getDirectory("Choose images directory");
list = getFileList(dir);
jpegDir = dir + "jpeg" + File.separator();

setBatchMode(true);

if (!File.isDirectory(jpegDir)) {		// checks if there is already
	File.makeDirectory(jpegDir);		// a folder named "jpeg"
}

for (i=0; i<list.length; i++){
	if (endsWith(list[i], ".tif") || endsWith(list[i], ".tiff") || endsWith(list[i], ".TIF") || endsWith(list[i], ".TIFF")){		//checks if file's extension is .tif
		file = dir + list[i];
		rootName = substring(list[i],0,lastIndexOf(list[i].toLowerCase(),".tif"));		// gets file name without extension
		open(file);
		getDimensions(width, height, channels, slices, frames);
		
		if (channels > 1){
			run("Stack to RGB", "slices");
		}
		for (j=1; j<=nSlices; j++){
			setSlice(j);
			saveAs("Jpeg", jpegDir + rootName + "_z=" + j + ".jpg");		// saves each slice in .jpg format
		}
	close();
	}
}

setBatchMode(false);
