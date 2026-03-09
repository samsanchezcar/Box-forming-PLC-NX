function best = optimizar_perfil_8cpm()
% OPTIMIZACIÓN (solo números) para 8 cajas/min
% Ahora con DOS reposos:
%   - tR_ini (inicio)   >= 0.4 s
%   - tR_mid (mitad)    (entre Formado y Home)
% y NO hay reposo final (solo inicio + mitad, como pediste).
%
% Variables optimizadas:
%   tR_ini, tR_mid, aY [m/s^2], aX=aZ=aRot [rad/s^2]
%
% Restricciones duras:
%   max|a| <= aLim (=4) , max|v| <= vLim (=4)
%   Factibilidad trapezoidal simétrico: a >= 4L/T^2
%
% Criterio:
%   Minimiza RMS combinado (suavidad) + penaliza picos
%   y (suavemente) prefiere más reposo total (tR_ini+tR_mid)

clc

%% ---------- Parámetros fijos ----------
cajas_por_min = 8;
Tu_total = 60 / cajas_por_min;    % 7.5 s/caja (incluye reposos)

L1 = 1.5; L2 = 1.5;
Ltot  = L1 + L2;                   % [m] recorrido Y (avance o retorno)
Lrot  = pi/2;                       % [rad] 90°

vLim = 4;                           % [m/s] o [rad/s]
aLim = 4;                           % [m/s^2] o [rad/s^2]

lockXZ = true;                      % true => aX=aZ

% Restricción NUEVA:
tR_ini_min = 0.40;                  % [s]
tR_mid_min = 0.40;                  % [s] (si quieres también >=0.4: pon 0.40)

%% ---------- Pesos del criterio ----------
wRMS = 1.0;     % suavidad (RMS a)
wA   = 0.15;    % picos a
wV   = 0.10;    % picos v
wTR  = 0.05;    % preferencia por reposo total (si quieres más reposo, sube)

%% ---------- Grid (coarse) ----------
% OJO: ahora hay 4 loops (tR_ini, tR_mid, aY, aRot).
% Para que no sea eterno, uso pasos más grandes y luego refino.

grid1.tR_ini = tR_ini_min:0.05:1.20;
grid1.tR_mid = tR_mid_min:0.05:1.20;

grid1.aY     = 0.5:0.10:4.0;
grid1.aRot   = 0.5:0.10:4.0;

% Refinamiento
refineHalfSpan = struct("tR",0.10,"a",0.25);
step2 = struct("tR",0.01,"a",0.02);

bestJ = inf;
best  = struct();

[best, bestJ] = run_grid(grid1, best, bestJ);

if ~isfield(best,"tR_ini")
    error("No se encontró solución factible con tR_ini >= %.2f s.", tR_ini_min);
end

%% ---------- Refinar alrededor del mejor ----------
grid2.tR_ini = clip_range(best.tR_ini - refineHalfSpan.tR, best.tR_ini + refineHalfSpan.tR, tR_ini_min, 2.0, step2.tR);
grid2.tR_mid = clip_range(best.tR_mid - refineHalfSpan.tR, best.tR_mid + refineHalfSpan.tR, tR_mid_min, 2.0, step2.tR);

grid2.aY     = clip_range(best.aY    - refineHalfSpan.a,  best.aY    + refineHalfSpan.a,  0.1, aLim, step2.a);
grid2.aRot   = clip_range(best.aX    - refineHalfSpan.a,  best.aX    + refineHalfSpan.a,  0.1, aLim, step2.a);

[best, bestJ] = run_grid(grid2, best, bestJ);

%% ---------- Reporte ----------
fprintf("\n=== MEJOR CONFIGURACIÓN (8 cajas/min, Tu_total=%.3f s) ===\n", Tu_total);
fprintf("Reposos: inicio y mitad (sin reposo final)\n");
fprintf("Restricción: tR_ini >= %.3f s\n\n", tR_ini_min);

fprintf("tR_ini = %.3f s\n", best.tR_ini);
fprintf("tR_mid = %.3f s\n", best.tR_mid);
fprintf("Tu_move = %.3f s\n\n", best.Tu_move);

fprintf("aY      = %.4f [m/s^2]\n",   best.aY);
fprintf("aX=aZ   = %.4f [rad/s^2]\n", best.aX);

fprintf("\n--- Métricas (solo movimiento) ---\n");
fprintf("RMS(a):   Y=%.4f | X=%.4f | Z=%.4f\n", best.rmsY, best.rmsX, best.rmsZ);
fprintf("RMS combo = %.4f\n", best.rmsCombo);
fprintf("Vmax:     Y=%.4f m/s | X=%.4f rad/s | Z=%.4f rad/s\n", best.VmaxY, best.VmaxX, best.VmaxZ);
fprintf("a_min:    Y=%.4f m/s^2 | X=%.4f rad/s^2 | Z=%.4f rad/s^2\n", best.aMinY, best.aMinX, best.aMinZ);
fprintf("J = %.6f\n\n", bestJ);

%% ================== FUNCIÓN INTERNA: GRID SEARCH ==================
    function [best, bestJ] = run_grid(grid, best, bestJ)

        tRsumMax = max(grid.tR_ini) + max(grid.tR_mid);

        for tR_ini = grid.tR_ini
            if tR_ini < tR_ini_min, continue; end

            for tR_mid = grid.tR_mid
                if tR_mid < tR_mid_min, continue; end

                % Tiempo de movimiento disponible (reposo inicio + reposo mitad)
                Tu_move = Tu_total - (tR_ini + tR_mid);
                if Tu_move <= 0
                    continue
                end

                % En tu lógica: Formado = Tu_move/2 y Home = Tu_move/2
                % Y se mueve una vez en Formado y una vez en Home (2 movimientos)
                T_Y   = Tu_move/2;

                % Cada rotación de 90° dura 1/4 de Tu_move (tb=tc=Tu_move/4)
                T_rot = Tu_move/4;

                % Poda rápida: si el mínimo requerido ya excede aLim, no hay nada que buscar
                aMinY_req   = 4*Ltot/(T_Y^2);
                aMinRot_req = 4*Lrot/(T_rot^2);
                if (aMinY_req > aLim + 1e-12) || (aMinRot_req > aLim + 1e-12)
                    continue
                end

                for aY = grid.aY
                    [okY, aMinY, VmaxY, t1Y] = seg_metrics(Ltot, T_Y, aY, vLim, aLim);
                    if ~okY, continue; end

                    % integral total a^2 de Y en TODO el movimiento:
                    % 2 movimientos Y, cada uno aporta 2*a^2*t1
                    int_a2_Y = 2 * (2 * aY^2 * t1Y);

                    for aRot = grid.aRot
                        if lockXZ
                            aX = aRot; aZ = aRot;
                        else
                            aX = aRot; aZ = aRot;
                        end

                        [okX, aMinX, VmaxX, t1X] = seg_metrics(Lrot, T_rot, aX, vLim, aLim);
                        if ~okX, continue; end
                        [okZ, aMinZ, VmaxZ, t1Z] = seg_metrics(Lrot, T_rot, aZ, vLim, aLim);
                        if ~okZ, continue; end

                        % X y Z: cada eje hace 2 movimientos trapezoidales (sube y baja)
                        int_a2_X = 2 * (2 * aX^2 * t1X);
                        int_a2_Z = 2 * (2 * aZ^2 * t1Z);

                        % RMS sobre el intervalo SOLO de movimiento (Tu_move)
                        rmsY = sqrt(int_a2_Y / Tu_move);
                        rmsX = sqrt(int_a2_X / Tu_move);
                        rmsZ = sqrt(int_a2_Z / Tu_move);

                        rmsCombo = sqrt(rmsY^2 + rmsX^2 + rmsZ^2);

                        aPeak = max([aY, aX, aZ]);
                        vPeak = max([VmaxY, VmaxX, VmaxZ]);

                        % Objetivo (normalizado)
                        J = wRMS*(rmsCombo/aLim) ...
                          + wA  *(aPeak/aLim) ...
                          + wV  *(vPeak/vLim) ...
                          - wTR *((tR_ini + tR_mid)/max(tRsumMax,eps));

                        if J < bestJ
                            bestJ = J;

                            best.tR_ini = tR_ini;
                            best.tR_mid = tR_mid;
                            best.Tu_move = Tu_move;

                            best.aY = aY;
                            best.aX = aX;
                            best.aZ = aZ;

                            best.rmsY = rmsY; best.rmsX = rmsX; best.rmsZ = rmsZ;
                            best.rmsCombo = rmsCombo;

                            best.VmaxY = VmaxY; best.VmaxX = VmaxX; best.VmaxZ = VmaxZ;
                            best.aMinY = aMinY; best.aMinX = aMinX; best.aMinZ = aMinZ;
                        end
                    end
                end
            end
        end
    end
end

%% ====================== helpers ======================
function [ok, aMin, Vmax, t1] = seg_metrics(L, T, a, vLim, aLim)
% Métricas de un trapezoidal simétrico (v0=vf=0) para distancia L y tiempo T.
% ok: cumple factibilidad + límites

ok = false;

if a <= 0 || T <= 0
    aMin = NaN; Vmax = NaN; t1 = NaN; return
end

if a > aLim + 1e-12
    aMin = 4*L/(T^2); Vmax = NaN; t1 = NaN; return
end

aMin = 4*L/(T^2);
if a < aMin - 1e-12
    Vmax = NaN; t1 = NaN; return
end

disc = (a*T)^2 - 4*a*L;
if disc < -1e-10
    Vmax = NaN; t1 = NaN; return
end
disc = max(disc, 0);

Vmax = (a*T - sqrt(disc))/2;   % >= 0
if Vmax > vLim + 1e-12
    t1 = NaN; return
end

t1 = Vmax / a;                 % tiempo de aceleración y frenado
ok = true;
end

function vec = clip_range(lo, hi, loLim, hiLim, step)
lo = max(lo, loLim);
hi = min(hi, hiLim);
if hi < lo
    vec = loLim:step:hiLim;
else
    vec = lo:step:hi;
end
end


best = optimizar_perfil_8cpm
