#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "batt.h"

// int set_batt_from_ports(batt_t *batt){
//     if(BATT_VOLTAGE_PORT < 0){
//         return 1;
//         // Nothing changes because BATT_VOLTAGE_PORT is less negative
//     } else {
//         batt->mlvolts = BATT_VOLTAGE_PORT >> 1;
//         batt->percent = (batt->mlvolts - 3000) >> 3;
//         // The formula to change BATT_VOLTAGE_PORT into a percentage
//         batt->mode = (BATT_STATUS_PORT >> 4) & 1;
//     }
//     if(((BATT_STATUS_PORT >> 4) & 1) == 1){
//         batt->mode = 1;
//         // If the 4th bit is 1 then batt->mode is 1 which is for percent
//     } else if(((BATT_STATUS_PORT >> 4) & 1) == 0){
//         // On the otherhand if it is 0 then batt->mode is 2 which is for voltage
//         batt->mode = 2;
//     }
//     if(batt->percent <= 0 || batt->mlvolts <= 3000){
//         batt->percent = 0;
//         // Makes percent 0 if percent is less than 0 or voltage is less than 3000
//     } else if(batt->percent >= 100 || batt->mlvolts >= 3800){
//         batt->percent = 100;
//         // Makes percent 100 if percent is greater than 100 or voltage is greater than 3800
//     }
//     return 0;
// }
// Uses the two global variables (ports) BATT_VOLTAGE_PORT and
// BATT_STATUS_PORT to set the fields of the parameter 'batt'.  If
// BATT_VOLTAGE_PORT is negative, then battery has been wired wrong;
// no fields of 'batt' are changed and 1 is returned to indicate an
// error.  Otherwise, sets fields of batt based on reading the voltage
// value and converting to precent using the provided formula. Returns
// 0 on a successful execution with no errors. This function DOES NOT
// modify any global variables but may access global variables.
//
// CONSTRAINT: Avoids the use of the division operation as much as
// possible. Makes use of shift operations in place of division where
// possible.
//
// CONSTRAINT: Uses only integer operations. No floating point
// operations are used as the target machine does not have a FPU.
// 
// CONSTRAINT: Limit the complexity of code as much as possible. Do
// not use deeply nested conditional structures. Seek to make the code
// as short, and simple as possible. Code longer than 40 lines may be
// penalized for complexity.

// int set_display_from_batt(batt_t batt, int *display){
//     *display = *display^*display;
//     int maskArr[10] = {0b0111111, 0b0000110, 0b1011011, 0b1001111, 0b1100110, 0b1101101, 0b1111101, 0b0000111, 0b1111111, 0b1101111};
//     int right, middle, left = 0;
//     int volts = batt.mlvolts;
//     int percent = batt.percent;
//     if(volts%10 > 5 && batt.mode == 2){
//         volts = volts + 10;
//     } // add 1 to volts if the remainder is greater than 5 because round up
//     if(batt.mode == 2){
//         // Assings mode to volts
//         volts = volts / 10;
//         right = maskArr[volts%10];
//         // set 1's place
//         volts = volts/10;
//         middle = maskArr[volts%10];
//         // set 10's place
//         volts = volts/10;
//         left = maskArr[volts%10];
//         // set 100's place
//         volts = volts/10;

//         *display = *display | (1 << 2);
//         *display = *display | (1 << 1);
//     } // Controls the voltage values

//     if(percent != 100 && percent > 9 && batt.mode == 1){
//         left = 0b0000000;
//         right = maskArr[percent%10];
//         // set 1's place
//         percent = percent/10;
//         middle = maskArr[percent%10];
//         // set 10's place
//         percent = percent/10;
//         *display = *display | (1 << 0);
//     } else if (percent >= 0 && percent < 10 && batt.mode == 1){
//         left = 0b0000000;
//         middle = 0b0000000;
//         right = maskArr[percent];
//         *display = *display | (1 << 0);
//         //assigns it as blank blank number because there is only a 1's place
//     } else if(percent == 100 && batt.mode == 1){
//         right = maskArr[0];
//         middle = maskArr[0];
//         left = maskArr[1];
//         *display = *display | (1 << 0);
//         // if 100 percent then it is just 1 0 0
//     } // Controls the percentage values and assings mode to percentage
//     if(batt.percent >= 5 && batt.percent <= 29){
//         *display = *display | (1 << 24);
//     } else if(batt.percent >= 30 && batt.percent <= 49){
//         *display = *display | (0b11 << 24);
//     } else if(batt.percent >= 50 && batt.percent <= 69){
//         *display = *display | (0b111 << 24);
//     } else if(batt.percent >= 70 && batt.percent <= 89){
//         *display = *display | (0b1111 << 24);
//     } else if(batt.percent >= 90 && batt.percent <= 100){
//        *display = *display | (0b11111 << 24);
//     }
//     // Displays the percentage battery at a certain percent

//     *display = *display | (right << 3);
//     *display = *display | (middle << 10);
//     *display = *display | (left << 17);
//     return 0;
// }
// Alters the bits of integer pointed to by 'display' to reflect the
// data in struct param 'batt'.  Does not assume any specific bit
// pattern stored at 'display' and completely resets all bits in it on
// successfully completing.  Selects either to show Volts (mode=1) or
// Percent (mode=2). If Volts are displayed, only displays 3 digits
// rounding the lowest digit up or down appropriate to the last digit.
// Calculates each digit to display changes bits at 'display' to show
// the volts/percent according to the pattern for each digit. Modifies
// additional bits to show a decimal place for volts and a 'V' or '%'
// indicator appropriate to the mode. In both modes, places bars in
// the level display as indicated by percentage cutoffs in provided
// diagrams. This function DOES NOT modify any global variables but
// may access global variables. Always returns 0.
// 
// CONSTRAINT: Limit the complexity of code as much as possible. Do
// not use deeply nested conditional structures. Seek to make the code
// as short, and simple as possible. Code longer than 65 lines may be
// penalized for complexity.

// int batt_update(){
//     batt_t batt = {};
//     if(set_batt_from_ports(&batt) == 1){
//         return 1;
//     } else {
//         set_batt_from_ports(&batt);
//         set_display_from_batt(batt, &BATT_DISPLAY_PORT);
//     }
//     return 0;
// }
// Called to update the battery meter display.  Makes use of
// set_batt_from_ports() and set_display_from_batt() to access battery
// voltage sensor then set the display. Checks these functions and if
// they indicate an error, does NOT change the display.  If functions
// succeed, modifies BATT_DISPLAY_PORT to show current battery level.
// 
// CONSTRAINT: Does not allocate any heap memory as malloc() is NOT
// available on the target microcontroller.  Uses stack and global
// memory only.