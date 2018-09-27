

# AnaOct
AnaOct is an analytic circuit analysis tool for LTSpice circuits completely written with Octave. Just run the AnaOct file and select a netlist you want to analyze. The whole logic and helper functions are packed into one simple file for easy usage. The goal is to help analog designers in rapidly analyses new circuits, optimize filters, or just use it for educational purposes.

# Dependencies
Symbolic toolbox is required, which in turn needs Python and SymPy to run.

# Variable Names
* M: The nodal matrix
* b: The right hand side of the linear equation system
* V: The solution vector with all voltages of all nets
* nets: A struct with all net-ids for easy access. E.g. in order to get the output voltage of a circuit just type V(nets.out).  The fieldname correspond to the used net name in LTSpice.

# Build-In Functions
Latex(equ) - It converts any given equation into a latex image and displays it. It requires an internet connection.


# Example

```
% Coupler Example
%V1 N001 0 1 AC 1
%L1 N004 N003 1
%L2 N004 0 1
%L3 N005 0 1
%L4 N006 N005 1
%R1 Vn 0 50
%R2 Vp 0 50
%R3 out 0 10
%C1 out N004 10µ
%R4 N002 N001 50
%C3 N003 N002 10µ
%C2 N005 Vp 10µ
%C4 Vn N006 10µ
%.ac dec 1000 10Meg 1G
%K1 L1 L3 1
%K2 L2 L4 1
%.backanno
%.end


netlist = "MNACoupler.net";
AnaOct

% Simplify variables
M = subs(M, {L2 L3 L4 C2 C4 C3 R2 R4}, {L1 L1 L1 C1 C1 C1 R1 R1});

solveMNA();

% Large capacitors and inductors (ideal coupler)
Vp = limit(V(nets.Vp), C1, sym(inf));
Vp = limit(Vp, L1, sym(inf));

Vn = limit(V(nets.Vn), C1, sym(inf));
Vn = limit(Vn, L1, sym(inf));
```
