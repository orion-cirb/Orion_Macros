// "BatchProcessFolders"
//
 requires("1.53");
run("Bio-Formats Macro Extensions");

   dir = getDirectory("Choose a Directory ");
   setBatchMode(true);
   count = 0;
   countFiles(dir);
   n = 0;
   processFiles(dir);
   
   function countFiles(dir) {
      list = getFileList(dir);
      for (i=0; i<list.length; i++) {
          if (endsWith(list[i], "/"))
              countFiles(""+dir+list[i]);
          else
              count++;
      }
  }
  function adjustContraste(nslices) {
  	for (i = 1; i <= nslices; i++) {
  		Stack.setChannel(i);
  		run("Enhance Contrast...", "saturated=0.3");
  	}
  }

   function processFiles(dir) {
      list = getFileList(dir);
      for (i=0; i<list.length; i++) {
          if (endsWith(list[i], "/"))
              processFiles(""+dir+list[i]);
          else {
             showProgress(n++, count);
             path = dir+list[i];
             processFile(path);
          }
      }
  }

  function saveJpeg(slices) {
  	for (i = 1; i <= slices; i++) {
  		selectWindow("C"+i+"-"+rootname);
  		run("Enhance Contrast...", "saturated=0.3");
  		run("Scale Bar...", "width=100 height=12 font=42 color=White background=None location=[Lower Right] bold hide overlay");
        saveAs("Jpeg",dir+"C"+i+"-"+rootname+".jpg");
        close();
  	}
  }


  function processFile(path) {
       if (endsWith(path, ".nd")) {
       	   dir = File.getDirectory(path);
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
  		     run("Scale Bar...", "width=100 height=12 font=42 color=White background=None location=[Lower Right] bold overlay");
           saveAs("Jpeg",dir+rootname+".jpg");
           saveAs("Tiff",dir+rootname+".tif");
           run("Split Channels");
           saveJpeg(sizeC);
      }
  }