%
% Convert 2 Port Scattering Parameter Matrix to ABCD Matrix
%
% V1 = A*V2 - B*I2
% I1 = C*V2 - D*I2

function ABCD = StoABCD (S, Z01, Z02)

ABCD = zeros(2, 2);
ABCD(1,1) = ((conj(Z01)+Z01*S(1,1))*(1-S(2,2)) + S(1,2)*S(2,1)*Z01) ./ (2*S(2,1)*sqrt(real(Z01) * real(Z02)));
ABCD(1,2) = ((conj(Z01)+Z01*S(1,1))*(conj(Z02)+S(2,2)*Z02)-S(1,2)*S(2,1)*Z01*Z02)./(2*S(2,1)*sqrt(real(Z01) * real(Z02)));
ABCD(2,1) = ((1-S(1,1))*(1-S(2,2))-S(1,2)*S(2,1))./(2*S(2,1)*sqrt(real(Z01) * real(Z02)));
ABCD(2,2) = ((1-S(1,1))*(conj(Z02)+S(2,2)*Z02)+S(1,2)*S(2,1)*Z02)/(2*S(2,1)*sqrt(real(Z01) * real(Z02)));


endfunction


