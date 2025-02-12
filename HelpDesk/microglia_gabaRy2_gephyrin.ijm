/*
 * Description: 
 * 		Segment microglia and gephyrin, then compute their colocalization
 * 		Measure colocalization area and mean intensity in GABARγ2 channel
 * Developed for: Samira Benadda, Imachem, IBENS, ENS
 * Author: Héloïse Monnet @ ORION-CIRB
 * Date: February 2025
 * Repository: https://github.com/orion-cirb/Orion_Macros.git
 * Dependencies: GDSC Fiji plugin (to install via Help > Update... > Manage Update Sites)
*/

run("Duplicate...", "title=img duplicate");

// Split channels
run("Split Channels");

// Segment microglia in channel 1
selectImage("C1-img");
run("Subtract Background...", "rolling=50");
run("Median...", "radius=1");
setAutoThreshold("Otsu dark"); // use another method? Triangle for example? 
run("Convert to Mask");

// Segment gephyrin in channel 3
selectImage("C3-img");
run("Difference of Gaussians", "  sigma1=2 sigma2=1 enhance");
setAutoThreshold("Otsu dark"); // use another method? Li for example? 
run("Convert to Mask");

// Compute colocalisation of microglia and gephyrin binary masks
imageCalculator("AND create", "C1-img", "C3-img");

// Measure area and mean intensity of resulting binary mask in channel 2 (GABARγ2)
run("Set Measurements...", "area mean redirect=C2-img decimal=2");
run("Create Selection");
run("Measure");

run("Select None");
run("Tile");