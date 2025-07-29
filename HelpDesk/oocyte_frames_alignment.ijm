/*
 * Description: Align the oocyte across frames
 * Developed for: Anastasia, Verlhac's team
 * Author: Héloïse Monnet @ ORION-CIRB
 * Date: July 2025
 * Repository: https://github.com/orion-cirb/Orion_Macros.git
 * Dependencies: None
*/

// Hide on-screen updates
setBatchMode(true);

// Store the name of the original image stack & duplicate it
imgName = getTitle();
run("Duplicate...", "title=bin duplicate");

// Segment the oocyte in the duplicated stack
selectImage("bin");
run("Gaussian Blur...", "sigma=20 stack");
run("Convert to Mask", "method=Triangle background=Dark calculate black");
// Measure oocyte centroid in each frame
for(i=1; i <= nSlices; i++) {
	setSlice(i);
	run("Create Selection");
	run("Measure");
}

// Align all slices in the original stack to the centroid of the first slice
selectImage(imgName);
xRef = getResult("X", 0);
yRef = getResult("Y", 0);
for(i=2; i <= nSlices; i++) {
	setSlice(i);
	x = xRef-getResult("X", i-1);
	y = yRef-getResult("Y", i-1);
	run("Translate...", "x="+x+" y="+y+" interpolation=None slice");
}

// Fit a circle around the oocyte on the first frame
selectImage("bin");
setSlice(1);
run("Create Selection");
run("Fit Circle");
selectImage(imgName);
setSlice(1);
run("Restore Selection");

// Close intermediate windows
close("bin");
close("Results");

setBatchMode(false);
