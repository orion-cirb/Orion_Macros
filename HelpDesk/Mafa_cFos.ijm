/*
 * Description: Detect cells in Mafa and cFos channels and count double-positive cells
 * Developed for: Aévin & Laure, Rouach's team
 * Author: Héloïse Monnet @ ORION-CIRB
 * Date: July 2025
 * Repository: https://github.com/orion-cirb/Orion_Macros.git
 * Dependencies: None
*/

imgName = getTitle();

run("Z Project...", "projection=[Max Intensity]");
run("Duplicate...", "title=proj duplicate");

selectImage("MAX_"+imgName);
run("Split Channels");

// Close DAPI channel
close("C1-MAX_"+imgName);

// Count cells on MAFA channel
selectImage("C2-MAX_"+imgName);
run("Gaussian Blur...", "sigma=3");
run("Remove Outliers...", "radius=10 threshold=0 which=Bright");
run("Find Maxima...", "prominence=40 output=[Single Points]");
run("Options...", "iterations=2 count=1 black pad do=Dilate");
run("Options...", "iterations=20 count=3 black pad do=Dilate");
rename("MAFA_"+imgName);
run("Set Measurements...", "centroid display redirect=None decimal=2");
run("Analyze Particles...", "display exclude");
// Add counted cells to ROI Manager
run("Create Selection");
roiManager("Add");
roiManager("Select", 0);
roiManager("Rename", "MAFA");

// Count cells on CFOS channel
selectImage("C3-MAX_"+imgName);
run("Gaussian Blur...", "sigma=5");
run("Remove Outliers...", "radius=10 threshold=0 which=Bright");
run("Find Maxima...", "prominence=20 output=[Single Points]");
run("Options...", "iterations=2 count=1 black pad do=Dilate");
run("Options...", "iterations=20 count=3 black pad do=Dilate");
rename("CFOS_"+imgName);
// Add counted cells to ROI Manager
run("Create Selection");
roiManager("Add");
roiManager("Select", 1);
roiManager("Rename", "CFOS");

// Compute intersection of two binary masks and count MAFA-cFOS positive cells
imageCalculator("AND create", "MAFA_"+imgName,"CFOS_"+imgName);
rename("MAFA_CFOS_"+imgName);
run("Analyze Particles...", "display exclude");
// Add counted cells to ROI Manager
run("Create Selection");
roiManager("Add");
roiManager("Select", 2);
roiManager("Rename", "MAFA_CFOS");

selectImage("proj");
close("\\Others");
