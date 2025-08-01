/*
 * Description: Modify current image lookup table (LUT) by setting specific RGB colors for four indexed values.
 * Developed for: Nicolas, Garel's team
 * Author: Héloïse Monnet @ ORION-CIRB
 * Date: May 2025
 * Repository: https://github.com/orion-cirb/Orion_Macros.git
 * Dependencies: None
*/

run("Spectrum");
getLut(reds, greens, blues);

// Background
reds[0] = 0;
greens[0] = 0;
blues[0] = 0;

// VAM
reds[1] = 255;
greens[1] = 255;
blues[1] = 0;

// VTM
reds[2] = 255;
greens[2] = 125;
blues[2] = 0;

// VDM
reds[3] = 0;
greens[3] = 0;
blues[3] = 255;

setLut(reds, greens, blues);
setMinAndMax(0, 255);
