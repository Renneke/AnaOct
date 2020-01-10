
netlist = "SParameterExtract.net";

AnaOct

syms Z0;
M = subs(M, {R1 R2}, {Z0 Z0});

solveMNA();

V1_ = V(nets.V1);
V2_ = V(nets.V2);
I1_ = V(end-1);
I2_ = V(end);

S11 = limit( simplify((V1_-Z0*I1_)/(V1_+Z0*I1_)) , V2, 0)
S12 = limit( simplify((V1_-Z0*I1_)/(V2_+Z0*I2_)) , V1, 0)
S21 = limit( simplify((V2_-Z0*I2_)/(V1_+Z0*I1_)) , V2, 0)
S22 = limit( simplify((V2_-Z0*I2_)/(V2_+Z0*I2_)) , V1, 0)

S = [S11, S12; S21, S22];

Sfun = matlabFunction(S);


f_ist  = [1.589e3, 29.283e3, 147.95e3];
V1_ist = [749.88985e-3*exp(1i*(-238e-3/360*2*pi)), 724.17e-3*exp(1i*(-3.08/360*2*pi)), 673.3644e-3*exp(1i*(-1.88/360*2*pi)) ];
V2_ist = [249.825e-3*exp(1i*(-2.143911/360*2*pi)), 205.77251e-3*exp(1i*(-34.60466/360*2*pi)), 68.9315e-3*exp(1i*(-74/360*2*pi))]

V1_calc = [];
I1_calc = [];

figure(1);
clf;
figure(3);
clf;

for i=1:length(f_ist)
  f = f_ist(i)
  S_ = Sfun(100e-9, 100, 50, 1i*2*pi*f);
  ABCD = StoABCD(S_, 50, 50);
  
  V2_meas = abs(V2_ist(i));
  NI2_calc = V2_meas/50;
  X = ABCD * [V2_meas; NI2_calc];
  V1_calc = [V1_calc, X(1)];
  I1_calc = [I1_calc, X(2)];

figure(1);
  plot(f, abs(X(1)), 'x')
  hold on;
figure(3);
plot(f, angle(X(1)), 'x');
hold on;
end

figure(1);
plot(f_ist, abs(V1_ist))

figure(2);
clf;
plot(f_ist, abs(V2_ist));


figure(3);
plot(f_ist, angle(V1_ist));

figure(4);
clf;
plot(f_ist, angle(V1_calc));
hold on;
plot(f_ist, angle(V2_ist));

figure(5);
clf;
plot(f_ist, abs(I1_calc));