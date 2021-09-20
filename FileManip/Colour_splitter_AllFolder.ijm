// Open all .tif images in a given directory and save separated color chanel images in new .tif files
// Orion CIRB

requires("1.52t");
dir = getDirectory("Choose images directory");
list = getFileList(dir);
splitDir = dir + "canaux individuels" + File.separator();

setBatchMode(true);

if (!File.isDirectory(splitDir)) {			// checks if there is already
	File.makeDirectory(splitDir);			// a folder named "canaux individuels"
}

for (i=0; i<list.length; i++){
	if (endsWith(list[i], ".tif") || endsWith(list[i], ".tiff") || endsWith(list[i], ".TIF") || endsWith(list[i], ".TIFF")){ 		//checks if file's extension is .tif
		file = dir + list[i];
		rootName = substring(list[i],0,lastIndexOf(list[i].toLowerCase(),".tif"));		 // gets file name without extension
		open(file);
		getDimensions(width, height, channels, slices, frames);
		
		if (channels > 1){
			run("Split Channels");
		}
		for (j=1; j<=channels; j++){
			save(splitDir+rootName+ "_C" + j + ".tif");		// saves splitted channels
			close();
		}
	}
}
setBatchMode(false);
