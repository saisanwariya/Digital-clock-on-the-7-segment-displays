# Digital Clock Program for MC9S12C

## Overview

This project involves creating a digital clock program for the MC9S12C Family microcontroller. The clock will be displayed on 7-segment displays attached to PORTB and will also be visible in the HyperTerminal connected to the HCS12 board simulation. The clock will display time in a 12-hour format (hh:mm:ss) with a limit of 10 minutes for the displayed minutes.

## Program Functionality

The digital clock program has the following functionality:

- Displays a 12-hour digital clock in hh:mm:ss format.
- Updates the time display every second.
- Displays two-digit seconds on the two 7-segment displays attached to PORTB.
- Displays one-digit minutes on one 7-segment display attached to PORTA.
- Accepts two commands:
  - "s" for 'set time' command: Allows the user to set the time.
  - "q" for 'quit' command: Stops the clock and allows text input in the terminal.
- Displays a 'Clock> ' prompt in the terminal and echoes user keystrokes until the Enter key is pressed.
- Handles invalid input formats and provides error messages.
- Uses Real Time Interrupt feature to maintain accurate time.

## Hardware Setup

To run this program, you need an MC9S12C Family microcontroller board with 7-segment displays attached to PORTB and PORTA. Ensure that the hardware connections are correctly set up to interface with these ports.

## Software Setup

To set up the software environment for running this program:

1. Install CodeWarrior software on your PC if not already installed.
2. Follow the Homework 8 Full Chip Simulator guide for additional CodeWarrior simulation setup.
3. Set the interrupt count number to ensure that your clock display is accurate within 1 second over two minutes.

## Running the Program

1. Load the compiled program onto your MC9S12C microcontroller board.
2. Start the program at memory address $3100 and ensure that data starts at $3000.
3. Connect to the HyperTerminal to see the clock display.
4. Follow the terminal instructions to set the time ("s" command) or quit the clock ("q" command).
5. Enjoy the digital clock functionality.

## Notes

- This program is designed to be user-friendly and robust, with error handling for invalid inputs.
- The clock program should accurately maintain time using Real Time Interrupts.
- Ensure that you have a proper development environment set up before attempting to run the program on your MC9S12C board.


# Academic Integrity Statement

Please note that all work included in this project is the original work of the author, and any external sources or references have been properly cited and credited. It is strictly prohibited to copy, reproduce, or use any part of this work without permission from the author.

If you choose to use any part of this work as a reference or resource, you are responsible for ensuring that you do not plagiarize or violate any academic integrity policies or guidelines. The author of this work cannot be held liable for any legal or academic consequences resulting from the misuse or misappropriation of this work.

Any unauthorized copying or use of this work may result in serious consequences, including but not limited to academic penalties, legal action, and damage to personal and professional reputation. Therefore, please use this work only as a reference and always ensure that you properly cite and attribute any sources or references used.

