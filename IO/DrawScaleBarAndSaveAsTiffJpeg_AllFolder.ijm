// "BatchProcessFolders"
// Open all files in a folder, from .nd or .czi files
// and save them as .tif or .jpeg files
// with scale bar drawn on it
// split color chanels if put to 1
//
// ORION CIRB

requires("1.53");
run("Bio-Formats Macro Extensions");

jpeg = 0;  // Put to 1 to save merge as jpeg, to 0 else
dosplit = 1;  // Put to 1 to save individual channels as tiff and jpeg, to 0 else

   dir = getDirectory("Choose a Directory ");
   setBatchMode(true);
   n = 0;
   count = 0;
   countFiles(dir);
   processFiles(dir, jpeg, dosplit);
	setBatchMode(false);
   
    function countFiles(dir) {
      list = getFileList(dir);
      for (i=0; i<list.length; i++) {
          if (endsWith(list[i], "/"))
              countFiles(""+dir+list[i]);
          else
              count++;
      }
  }
 
  function scaleBar()
   {
	 run("Scale Bar...", "width=200 height=20 font=50 color=White background=None location=[Lower Right] bold hide overlay label");
   }
  
  function adjustContraste(nslices) {
  	for (i = 1; i <= nslices; i++) {
  		Stack.setChannel(i);
  		run("Enhance Contrast...", "saturated=0.3");
  	}
  }

   function processFiles(dir, jpeg, dosplit) {
      list = getFileList(dir);
      for (i=0; i<list.length; i++) {
          if (endsWith(list[i], "/"))
              processFiles(""+dir+list[i], jpeg, dosplit);
          else {
             showProgress(n++, count);
             path = dir+list[i];
             processFile(path, jpeg, dosplit);
          }
      }
  }

  function saveTifJpeg(slices, outName) {
  	for (i = 1; i <= slices; i++) {
  		selectWindow("C"+i+"-"+rootname);
  		run("Enhance Contrast...", "saturated=0.3");
  		scaleBar();
        saveAs("Jpeg",outName+"-C"+i+".jpg");
        saveAs("Tiff",outName+"-C"+i+".tiff");
        close();
  	}
  }



  function processFile(path, jpeg, dosplit) {
  	
       if (endsWith(path, ".nd") ||endsWith(path, ".czi")) {
       	   dir = File.getDirectory(path);
       	    // create output directory
		   outDir = dir + "Projections"+ File.separator();
			if (!File.isDirectory(outDir)) {File.makeDirectory(outDir);}

       	   rootname = File.getNameWithoutExtension(path);	
           run("Bio-Formats Importer", "open=&path autoscale color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
           Ext.setId(path);
           Ext.getSizeC(sizeC);
           id = getImageID();
           run("Z Project...", "projection=[Max Intensity]");
           selectImage(id);
           close();
           rename(rootname);
           adjustContraste(sizeC);
  		   scaleBar();
           if (jpeg>0) saveAs("Jpeg",outDir+rootname+".jpg");
           saveAs("Tiff",outDir+rootname+".tif");
           rename(rootname);
           if (dosplit>0){
           run("Split Channels");
           saveTifJpeg(sizeC, outDir+rootname);
           } else {
           	close();
           }
      }
  }
