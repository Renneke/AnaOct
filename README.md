# AnaOct
AnaOct is an analytic circuit analysis tool for LTSpice circuits completly written with Octave.
Just run the AnaOct file and select a netlist you want to analyse.
The whole logic and helper functions are packed into one simple file for easy usage.
The goal is to help analog designers in rapidly analyse new circuits, optimize filters,
or just use it for educational purposes.

# Dependencies
Symbolic toolbox is required, which in turn needs Python and SymPy to run.

# Variable Names
* M: The nodal matrix
* b: The right hand side of the linear equation system
* V: The solution vector with all voltages of all nets
* nets: A struct with all net-ids for easy access. E.g. in order to get the output voltage of a circuit just type V(nets.out).  The fieldname correspond to the used net name in LTSpice.

# Build-In Functions
Latex(equ) - It converts any given equation into a latex image and displays it. It requires an internet connection.
