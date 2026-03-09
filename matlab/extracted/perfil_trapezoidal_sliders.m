function perfil_trapezoidal_sliders()
%% PERFIL TRAPEZOIDAL + UI con SLIDERS + EDITFIELDS (actualización en vivo)
% - Rotaciones en rad
% - Límites: vLim=4 (m/s o rad/s), aLim=4 (m/s^2 o rad/s^2)
% - Reposo SOLO al inicio + reposo SOLO en la mitad (entre Formado y Home)
% - Si no es posible, se muestra mensaje y no se cae la UI
% - Colores como antes (Y azul, X naranja, Z amarillo) + ejes blancos
% - Barras RMS / MAX (persistentes) y se actualizan con sliders
% - Lock aX=aZ
% - En labels: a y vMax (solo movimiento, excluyendo reposos ini y mitad)

clc

%% ------------------ PARÁMETROS FIJOS ------------------
p0.cajas_por_min = 8;

p0.L1  = 1.5;           % [m]
p0.L2  = 1.5;           % [m]
p0.dt  = 1e-3;          % [s]
p0.rot90 = pi/2;        % [rad]

p0.vLim = 4;            % [m/s] o [rad/s]
p0.aLim = 4;            % [m/s^2] o [rad/s^2]

% Defaults
p0.aY = 4.0;
p0.aX = 4.0;
p0.aZ = 4.0;

% Reposos (NUEVO)
p0.t_reposo_ini = 1.0;
p0.t_reposo_mid = 0.5;

% Colores "como antes"
cY = [0.0000 0.4470 0.7410];  % azul
cX = [0.8500 0.3250 0.0980];  % naranja
cZ = [0.9290 0.6940 0.1250];  % amarillo
cMk = [0.70 0.70 0.70];       % marcadores de tiempo

% Estado actual (para ValueChanging)
curr = struct("aY",p0.aY, "aX",p0.aX, "aZ",p0.aZ, ...
              "tRi",p0.t_reposo_ini, "tRm",p0.t_reposo_mid);

% Flag anti-loop (sync slider <-> editfield)
isSync = false;

%% ------------------ UI ------------------
fig = uifigure("Name","Perfiles trapezoidales - Sliders + Input", "Position",[60 60 1350 750]);
fig.Color = [0.08 0.08 0.10];

outer = uigridlayout(fig,[1 2]);
outer.ColumnWidth = {340,'1x'};
outer.RowHeight   = {'1x'};
outer.BackgroundColor = fig.Color;

% ===== Panel Controles =====
pCtrl = uipanel(outer, "Title","Controles", "FontWeight","bold");
pCtrl.Layout.Row = 1; pCtrl.Layout.Column = 1;
pCtrl.BackgroundColor = fig.Color;
pCtrl.ForegroundColor = [1 1 1];

gCtrl = uigridlayout(pCtrl,[22 1]);
gCtrl.RowHeight = {26, 22, 10, ...        % title/info/space
                   22, 34, 22, ...        % aY
                   22, 34, 22, ...        % aX
                   22, 34, 22, ...        % aZ
                   22, 34, 22, ...        % t_reposo_ini
                   22, 34, 22, ...        % t_reposo_mid
                   32, 26, 48, '1x'};     % reset/lock/status/fill
gCtrl.ColumnWidth = {'1x'};
gCtrl.BackgroundColor = fig.Color;

lblTitle = uilabel(gCtrl, "Text","Parámetros (slider o escribiendo)", "FontWeight","bold");
lblTitle.Layout.Row = 1; lblTitle.FontColor = [1 1 1];

lblInfo = uilabel(gCtrl, "Text", sprintf("cajas/min=%.2f | vLim=%.2f | aLim=%.2f", ...
    p0.cajas_por_min, p0.vLim, p0.aLim));
lblInfo.Layout.Row = 2; lblInfo.FontColor = [1 1 1];

sp = uilabel(gCtrl, "Text",""); sp.Layout.Row = 3;

% ---- aY ----
lbl1 = uilabel(gCtrl, "Text","aY [m/s^2] (<= 4)"); lbl1.Layout.Row = 4; lbl1.FontColor = [1 1 1];
gAY = uigridlayout(gCtrl,[1 2]); gAY.Layout.Row = 5; gAY.ColumnWidth = {'1x', 80}; gAY.BackgroundColor = fig.Color;
sAY = uislider(gAY, "Limits",[0.1 p0.aLim], "Value", p0.aY); sAY.Layout.Column = 1;
eAY = uieditfield(gAY,'numeric', "Limits",[0.1 p0.aLim], "Value", p0.aY); eAY.Layout.Column = 2;
lblAY = uilabel(gCtrl, "Text",""); lblAY.Layout.Row = 6; lblAY.FontColor = [1 1 1];

% ---- aX ----
lbl2 = uilabel(gCtrl, "Text","aX [rad/s^2] (<= 4)"); lbl2.Layout.Row = 7; lbl2.FontColor = [1 1 1];
gAX = uigridlayout(gCtrl,[1 2]); gAX.Layout.Row = 8; gAX.ColumnWidth = {'1x', 80}; gAX.BackgroundColor = fig.Color;
sAX = uislider(gAX, "Limits",[0.1 p0.aLim], "Value", p0.aX); sAX.Layout.Column = 1;
eAX = uieditfield(gAX,'numeric', "Limits",[0.1 p0.aLim], "Value", p0.aX); eAX.Layout.Column = 2;
lblAX = uilabel(gCtrl, "Text",""); lblAX.Layout.Row = 9; lblAX.FontColor = [1 1 1];

% ---- aZ ----
lbl3 = uilabel(gCtrl, "Text","aZ [rad/s^2] (<= 4)"); lbl3.Layout.Row = 10; lbl3.FontColor = [1 1 1];
gAZ = uigridlayout(gCtrl,[1 2]); gAZ.Layout.Row = 11; gAZ.ColumnWidth = {'1x', 80}; gAZ.BackgroundColor = fig.Color;
sAZ = uislider(gAZ, "Limits",[0.1 p0.aLim], "Value", p0.aZ); sAZ.Layout.Column = 1;
eAZ = uieditfield(gAZ,'numeric', "Limits",[0.1 p0.aLim], "Value", p0.aZ); eAZ.Layout.Column = 2;
lblAZ = uilabel(gCtrl, "Text",""); lblAZ.Layout.Row = 12; lblAZ.FontColor = [1 1 1];

% ---- t_reposo_ini ----
lbl4i = uilabel(gCtrl, "Text","t_reposo_ini [s] (al inicio)"); lbl4i.Layout.Row = 13; lbl4i.FontColor = [1 1 1];
gTRi = uigridlayout(gCtrl,[1 2]); gTRi.Layout.Row = 14; gTRi.ColumnWidth = {'1x', 80}; gTRi.BackgroundColor = fig.Color;
sTRi = uislider(gTRi, "Limits",[0 4], "Value", p0.t_reposo_ini); sTRi.Layout.Column = 1;
eTRi = uieditfield(gTRi,'numeric', "Limits",[0 4], "Value", p0.t_reposo_ini); eTRi.Layout.Column = 2;
lblTRi = uilabel(gCtrl, "Text",""); lblTRi.Layout.Row = 15; lblTRi.FontColor = [1 1 1];

% ---- t_reposo_mid ----
lbl4m = uilabel(gCtrl, "Text","t_reposo_mid [s] (en la mitad)"); lbl4m.Layout.Row = 16; lbl4m.FontColor = [1 1 1];
gTRm = uigridlayout(gCtrl,[1 2]); gTRm.Layout.Row = 17; gTRm.ColumnWidth = {'1x', 80}; gTRm.BackgroundColor = fig.Color;
sTRm = uislider(gTRm, "Limits",[0 4], "Value", p0.t_reposo_mid); sTRm.Layout.Column = 1;
eTRm = uieditfield(gTRm,'numeric', "Limits",[0 4], "Value", p0.t_reposo_mid); eTRm.Layout.Column = 2;
lblTRm = uilabel(gCtrl, "Text",""); lblTRm.Layout.Row = 18; lblTRm.FontColor = [1 1 1];

% ---- Reset ----
btnReset = uibutton(gCtrl, "Text","Reset", "ButtonPushedFcn", @onReset);
btnReset.Layout.Row = 19;

% ---- Lock ----
cbLock = uicheckbox(gCtrl, "Text","Bloquear aX = aZ", "Value", false, "ValueChangedFcn", @onLockChanged);
cbLock.Layout.Row = 20;
cbLock.FontColor = [1 1 1];

% ---- Estado ----
lblStatus = uilabel(gCtrl, "Text","Listo.", "FontWeight","bold");
lblStatus.Layout.Row = 21;
lblStatus.WordWrap = "on";
lblStatus.FontColor = [1 1 1];

% ===== Panel Plots =====
pPlots = uipanel(outer, "Title","Gráficas", "FontWeight","bold");
pPlots.Layout.Row = 1; pPlots.Layout.Column = 2;
pPlots.BackgroundColor = fig.Color;
pPlots.ForegroundColor = [1 1 1];

gPlots = uigridlayout(pPlots,[1 1]);
gPlots.RowHeight = {'1x'};
gPlots.ColumnWidth = {'1x'};
gPlots.BackgroundColor = fig.Color;

tg = uitabgroup(gPlots);
tg.Layout.Row = 1; tg.Layout.Column = 1;

tabT  = uitab(tg, "Title","Tiempo");
tab3D = uitab(tg, "Title","Trayectoria");
tabM  = uitab(tg, "Title","Métricas");

% --- Tab Tiempo ---
gT = uigridlayout(tabT,[3 1]);
gT.RowHeight = {'1x','1x','1x'};
gT.ColumnWidth = {'1x'};
axPos = uiaxes(gT); axPos.Layout.Row = 1;
axVel = uiaxes(gT); axVel.Layout.Row = 2;
axAcc = uiaxes(gT); axAcc.Layout.Row = 3;

% --- Tab Trayectoria ---
g3 = uigridlayout(tab3D,[1 1]);
g3.RowHeight = {'1x'}; g3.ColumnWidth = {'1x'};
ax3D = uiaxes(g3); ax3D.Layout.Row = 1;

% --- Tab Métricas ---
gM = uigridlayout(tabM,[2 1]);
gM.RowHeight = {'1x','1x'}; gM.ColumnWidth = {'1x'};
axRMS = uiaxes(gM); axRMS.Layout.Row = 1;
axMAX = uiaxes(gM); axMAX.Layout.Row = 2;

% Estilo oscuro + ejes blancos
styleAxesTime(axPos); styleAxesTime(axVel); styleAxesTime(axAcc);
styleAxes3D(ax3D);
styleAxesSimple(axRMS); styleAxesSimple(axMAX);

% Marcadores de tiempo
hMkPos = gobjects(0); hMkVel = gobjects(0); hMkAcc = gobjects(0);

% ======= BARRAS PERSISTENTES =======
% RMS
cla(axRMS);
hbRMS = bar(axRMS, zeros(3,2), "grouped");
hbRMS(1).FaceColor = [0.80 0.80 0.80];
hbRMS(2).FaceColor = [0.45 0.45 0.45];
axRMS.XTick = 1:3; axRMS.XTickLabel = {'Y','RotX','RotZ'};
title(axRMS,"Aceleración RMS (Solo movimiento vs Ciclo)");
ylabel(axRMS,"RMS a (Y: m/s^2 | Rot: rad/s^2)");
grid(axRMS,"on");
lr = legend(axRMS, {"Solo movimiento","Ciclo completo"}, "Location","best");
try, lr.TextColor = [1 1 1]; end
hRMSlim = yline(axRMS, p0.aLim, "--", "aLim", "Color",[1 1 1], "HandleVisibility","off");
styleAxesSimple(axRMS);

% MAX
cla(axMAX);
hbMAX = bar(axMAX, zeros(3,2), "grouped");
hbMAX(1).FaceColor = [0.80 0.80 0.80];
hbMAX(2).FaceColor = [0.45 0.45 0.45];
axMAX.XTick = 1:3; axMAX.XTickLabel = {'Y','RotX','RotZ'};
title(axMAX,"Aceleración Máxima |a| (Solo movimiento vs Ciclo)");
ylabel(axMAX,"Max |a| (Y: m/s^2 | Rot: rad/s^2)");
grid(axMAX,"on");
lm = legend(axMAX, {"Solo movimiento","Ciclo completo"}, "Location","best");
try, lm.TextColor = [1 1 1]; end
hMAXlim = yline(axMAX, p0.aLim, "--", "aLim", "Color",[1 1 1], "HandleVisibility","off");
styleAxesSimple(axMAX);

% Throttle
tLast = tic;

%% ------------------ Callbacks ------------------
% Slider en vivo
sAY.ValueChangingFcn  = @(~,event) onSlideChanging("aY",  event.Value);
sAX.ValueChangingFcn  = @(~,event) onSlideChanging("aX",  event.Value);
sAZ.ValueChangingFcn  = @(~,event) onSlideChanging("aZ",  event.Value);
sTRi.ValueChangingFcn = @(~,event) onSlideChanging("tRi", event.Value);
sTRm.ValueChangingFcn = @(~,event) onSlideChanging("tRm", event.Value);

% Editfields
eAY.ValueChangedFcn  = @(src,~) onEditChanged("aY",  src.Value);
eAX.ValueChangedFcn  = @(src,~) onEditChanged("aX",  src.Value);
eAZ.ValueChangedFcn  = @(src,~) onEditChanged("aZ",  src.Value);
eTRi.ValueChangedFcn = @(src,~) onEditChanged("tRi", src.Value);
eTRm.ValueChangedFcn = @(src,~) onEditChanged("tRm", src.Value);

% Primer render
updateAll();

    function onSlideChanging(field, val)
        curr.(field) = val;

        % Sync con editfield (sin loops)
        isSync = true;
        switch field
            case "aY",  eAY.Value  = val;
            case "aX",  eAX.Value  = val;
            case "aZ",  eAZ.Value  = val;
            case "tRi", eTRi.Value = val;
            case "tRm", eTRm.Value = val;
        end
        isSync = false;

        % Lock aX=aZ
        if cbLock.Value
            if field == "aX"
                curr.aZ = val; isSync = true; sAZ.Value = val; eAZ.Value = val; isSync = false;
            elseif field == "aZ"
                curr.aX = val; isSync = true; sAX.Value = val; eAX.Value = val; isSync = false;
            end
        end

        if toc(tLast) < 0.05, return; end
        tLast = tic;
        updateAll();
        drawnow limitrate
    end

    function onEditChanged(field, val)
        if isSync, return; end

        % Clamp manual
        switch field
            case {"aY","aX","aZ"}
                val = max(0.1, min(p0.aLim, val));
            case {"tRi","tRm"}
                val = max(0.0, min(4.0, val));
        end

        curr.(field) = val;

        % Sync hacia slider + editfield
        isSync = true;
        switch field
            case "aY",  sAY.Value  = val; eAY.Value  = val;
            case "aX",  sAX.Value  = val; eAX.Value  = val;
            case "aZ",  sAZ.Value  = val; eAZ.Value  = val;
            case "tRi", sTRi.Value = val; eTRi.Value = val;
            case "tRm", sTRm.Value = val; eTRm.Value = val;
        end
        isSync = false;

        % Lock aX=aZ
        if cbLock.Value && (field=="aX" || field=="aZ")
            curr.aZ = curr.aX;
            isSync = true;
            sAZ.Value = curr.aZ; eAZ.Value = curr.aZ;
            isSync = false;
        end

        updateAll();
        drawnow limitrate
    end

    function onReset(~,~)
        isSync = true;
        sAY.Value  = p0.aY; eAY.Value  = p0.aY; curr.aY  = p0.aY;
        sAX.Value  = p0.aX; eAX.Value  = p0.aX; curr.aX  = p0.aX;
        sAZ.Value  = p0.aZ; eAZ.Value  = p0.aZ; curr.aZ  = p0.aZ;
        sTRi.Value = p0.t_reposo_ini; eTRi.Value = p0.t_reposo_ini; curr.tRi = p0.t_reposo_ini;
        sTRm.Value = p0.t_reposo_mid; eTRm.Value = p0.t_reposo_mid; curr.tRm = p0.t_reposo_mid;

        cbLock.Value = false;
        sAZ.Enable = "on"; eAZ.Enable = "on";
        isSync = false;

        updateAll();
    end

    function onLockChanged(~,~)
        if cbLock.Value
            curr.aZ = curr.aX;
            isSync = true;
            sAZ.Value = curr.aZ; eAZ.Value = curr.aZ;
            sAZ.Enable = "off";  eAZ.Enable = "off";
            isSync = false;
        else
            sAZ.Enable = "on"; eAZ.Enable = "on";
        end
        updateAll();
    end

%% ------------------ Actualización general ------------------
    function updateAll()
        lblTRi.Text = sprintf("t_reposo_ini = %.3f s", curr.tRi);
        lblTRm.Text = sprintf("t_reposo_mid = %.3f s (entre Formado y Home)", curr.tRm);

        p = p0;
        p.aY = curr.aY;
        p.aX = curr.aX;
        p.aZ = curr.aZ;
        p.t_reposo_ini = curr.tRi;
        p.t_reposo_mid = curr.tRm;

        try
            out = computeCycle(p);

            % Labels con vMax (solo movimiento)
            lblAY.Text = sprintf("aY = %.3f | vMax = %.3f", curr.aY, out.vmaxY_move);
            lblAX.Text = sprintf("aX = %.3f | vMax = %.3f", curr.aX, out.vmaxX_move);
            lblAZ.Text = sprintf("aZ = %.3f | vMax = %.3f", curr.aZ, out.vmaxZ_move);

            lblStatus.FontColor = [0 0.85 0];
            lblStatus.Text = sprintf("OK | tEnd=%.3f s | cajas/min real=%.3f | t_move=%.3f s", ...
                out.tEnd, out.cajas_por_min_real, out.tu_move);

            % ====== POSICIONES ======
            cla(axPos); grid(axPos,"on");
            title(axPos,"Posiciones"); xlabel(axPos,"Tiempo [s]");

            yyaxis(axPos,'left');
            hY = plot(axPos, out.Y.t, out.Y.x, '-', "LineWidth", 1.2, "Color", cY);
            ylabel(axPos,"Y [m]");

            yyaxis(axPos,'right'); hold(axPos,"on");
            hX = plot(axPos, out.X.t, out.X.x, '-', "LineWidth", 1.2, "Color", cX);
            hZ = plot(axPos, out.Z.t, out.Z.x, '-', "LineWidth", 1.2, "Color", cZ);
            ylabel(axPos,"Rotaciones [rad]");
            leg = legend(axPos, [hY hX hZ], {"Y","RotX","RotZ"}, "Location","best");
            try, leg.TextColor = [1 1 1]; end
            hold(axPos,"off");
            hMkPos = addTimeMarkers(axPos, out, hMkPos, cMk);
            styleAxesTime(axPos);

            % ====== VELOCIDADES ======
            cla(axVel); grid(axVel,"on");
            title(axVel,"Velocidades"); xlabel(axVel,"Tiempo [s]");

            yyaxis(axVel,'left');
            hY = plot(axVel, out.Y.t, out.Y.v, '-', "LineWidth", 1.2, "Color", cY);
            ylabel(axVel,"Velocidad Y [m/s]");
            yline(axVel, +p.vLim, ":", "vLim", "Color",[1 1 1], "HandleVisibility","off");
            yline(axVel, -p.vLim, ":", "vLim", "Color",[1 1 1], "HandleVisibility","off");

            yyaxis(axVel,'right'); hold(axVel,"on");
            hX = plot(axVel, out.X.t, out.X.v, '-', "LineWidth", 1.2, "Color", cX);
            hZ = plot(axVel, out.Z.t, out.Z.v, '-', "LineWidth", 1.2, "Color", cZ);
            ylabel(axVel,"Velocidad Rot [rad/s]");
            yline(axVel, +p.vLim, ":", "vLim", "Color",[1 1 1], "HandleVisibility","off");
            yline(axVel, -p.vLim, ":", "vLim", "Color",[1 1 1], "HandleVisibility","off");
            leg = legend(axVel, [hY hX hZ], {"Y","RotX","RotZ"}, "Location","best");
            try, leg.TextColor = [1 1 1]; end
            hold(axVel,"off");
            hMkVel = addTimeMarkers(axVel, out, hMkVel, cMk);
            styleAxesTime(axVel);

            % ====== ACELERACIONES ======
            cla(axAcc); grid(axAcc,"on");
            title(axAcc,"Aceleraciones"); xlabel(axAcc,"Tiempo [s]");

            yyaxis(axAcc,'left');
            hY = plot(axAcc, out.Y.t, out.Y.acc, '-', "LineWidth", 1.2, "Color", cY);
            ylabel(axAcc,"Aceleración Y [m/s^2]");
            yline(axAcc, +p.aLim, ":", "aLim", "Color",[1 1 1], "HandleVisibility","off");
            yline(axAcc, -p.aLim, ":", "aLim", "Color",[1 1 1], "HandleVisibility","off");

            yyaxis(axAcc,'right'); hold(axAcc,"on");
            hX = plot(axAcc, out.X.t, out.X.acc, '-', "LineWidth", 1.2, "Color", cX);
            hZ = plot(axAcc, out.Z.t, out.Z.acc, '-', "LineWidth", 1.2, "Color", cZ);
            ylabel(axAcc,"Aceleración Rot [rad/s^2]");
            yline(axAcc, +p.aLim, ":", "aLim", "Color",[1 1 1], "HandleVisibility","off");
            yline(axAcc, -p.aLim, ":", "aLim", "Color",[1 1 1], "HandleVisibility","off");
            leg = legend(axAcc, [hY hX hZ], {"Y","RotX","RotZ"}, "Location","best");
            try, leg.TextColor = [1 1 1]; end
            hold(axAcc,"off");
            hMkAcc = addTimeMarkers(axAcc, out, hMkAcc, cMk);
            styleAxesTime(axAcc);

            % ====== TRAYECTORIA ======
            cla(ax3D);
            plot3(ax3D, out.Y.x, out.X.x, out.Z.x, '-', "LineWidth", 1.2, "Color", [0.9 0.9 0.9]);
            grid(ax3D,"on");
            xlabel(ax3D,"Y [m]"); ylabel(ax3D,"RotX [rad]"); zlabel(ax3D,"RotZ [rad]");
            title(ax3D,"Trayectoria conjunta (posición)");
            view(ax3D, 3);
            styleAxes3D(ax3D);

            % ====== MÉTRICAS (ACTUALIZAR BARRAS) ======
            dataRMS = [out.rmsY_move out.rmsY_all;
                       out.rmsX_move out.rmsX_all;
                       out.rmsZ_move out.rmsZ_all];

            dataMAX = [out.maxY_move out.maxY_all;
                       out.maxX_move out.maxX_all;
                       out.maxZ_move out.maxZ_all];

            hbRMS(1).YData = dataRMS(:,1);
            hbRMS(2).YData = dataRMS(:,2);

            hbMAX(1).YData = dataMAX(:,1);
            hbMAX(2).YData = dataMAX(:,2);

            hRMSlim.Value = p.aLim;
            hMAXlim.Value = p.aLim;

            axRMS.YLim = [0, max([p.aLim, max(dataRMS(:))*1.15, 0.5])];
            axMAX.YLim = [0, max([p.aLim, max(dataMAX(:))*1.15, 0.5])];

            styleAxesSimple(axRMS);
            styleAxesSimple(axMAX);

        catch ME
            lblAY.Text = sprintf("aY = %.3f | vMax = --", curr.aY);
            lblAX.Text = sprintf("aX = %.3f | vMax = --", curr.aX);
            lblAZ.Text = sprintf("aZ = %.3f | vMax = --", curr.aZ);

            lblStatus.FontColor = [0.95 0.25 0.25];
            lblStatus.Text = "NO es posible el perfil: " + string(ME.message);

            hbRMS(1).YData = [0;0;0]; hbRMS(2).YData = [0;0;0];
            hbMAX(1).YData = [0;0;0]; hbMAX(2).YData = [0;0;0];
            axRMS.YLim = [0, max(p0.aLim, 0.5)];
            axMAX.YLim = [0, max(p0.aLim, 0.5)];
        end
    end
end

%% ====================== AUX UI ======================
function hPrev = addTimeMarkers(ax, out, hPrev, cMk)
    if ~isempty(hPrev)
        try, delete(hPrev(isvalid(hPrev))); catch, end
    end
    % 6 marcadores: start, B, C(=inicio reposo mitad), MidEnd, H, End
    hPrev = gobjects(6,1);
    hPrev(1) = xline(ax, out.tMoveStart, "--", "Color", cMk);
    hPrev(2) = xline(ax, out.tB,         "--", "Color", cMk);
    hPrev(3) = xline(ax, out.tC,         "--", "Color", cMk);      % fin formado / inicio reposo mitad
    hPrev(4) = xline(ax, out.tMidEnd,    "--", "Color", cMk);      % fin reposo mitad / inicio home
    hPrev(5) = xline(ax, out.tH,         "--", "Color", cMk);
    hPrev(6) = xline(ax, out.tEnd,       "--", "Color", cMk);
end

function styleAxesTime(ax)
    ax.Color = [0.05 0.05 0.07];
    ax.XColor = [1 1 1];
    ax.GridColor = [0.35 0.35 0.35];
    ax.Box = 'on';
    ax.Title.Color  = [1 1 1];
    ax.XLabel.Color = [1 1 1];
    ax.YLabel.Color = [1 1 1];
    try
        if numel(ax.YAxis) >= 1, ax.YAxis(1).Color = [1 1 1]; end
        if numel(ax.YAxis) >= 2, ax.YAxis(2).Color = [1 1 1]; end
    catch
        ax.YColor = [1 1 1];
    end
end

function styleAxesSimple(ax)
    ax.Color = [0.05 0.05 0.07];
    ax.XColor = [1 1 1];
    ax.YColor = [1 1 1];
    ax.GridColor = [0.35 0.35 0.35];
    ax.Box = 'on';
    ax.Title.Color  = [1 1 1];
    ax.XLabel.Color = [1 1 1];
    ax.YLabel.Color = [1 1 1];
end

function styleAxes3D(ax)
    ax.Color = [0.05 0.05 0.07];
    ax.XColor = [1 1 1];
    ax.YColor = [1 1 1];
    ax.ZColor = [1 1 1];
    ax.GridColor = [0.35 0.35 0.35];
    ax.Box = 'on';
    ax.Title.Color  = [1 1 1];
    ax.XLabel.Color = [1 1 1];
    ax.YLabel.Color = [1 1 1];
    ax.ZLabel.Color = [1 1 1];
end

%% ====================== PERFIL ======================
function out = computeCycle(p)
    tu_total = 60 / p.cajas_por_min;

    % NUEVO: solo reposo ini + reposo mitad
    tu_move  = tu_total - (p.t_reposo_ini + p.t_reposo_mid);
    if tu_move <= 0
        error("Reposos (ini+mitad=%.3f s) >= tiempo total por caja (%.3f s).", ...
              p.t_reposo_ini + p.t_reposo_mid, tu_total);
    end

    % Reparto del movimiento
    t_formado = tu_move/2;
    t_home    = tu_move/2;

    tb = t_formado/2;
    tc = t_formado/2;

    Ltot = p.L1 + p.L2;

    % ===== Reposo inicial (en 0) =====
    Y_ini = holdProfile(0, p.t_reposo_ini, p.dt);
    X_ini = holdProfile(0, p.t_reposo_ini, p.dt);
    Z_ini = holdProfile(0, p.t_reposo_ini, p.dt);

    % ===== FORMADO =====
    Y_formado = trapProfile(+Ltot,    t_formado, p.aY, 0,       p.dt, p.vLim, p.aLim, "Y (Formado)");
    Z_1b      = trapProfile(+p.rot90, tb,       p.aZ, 0,       p.dt, p.vLim, p.aLim, "RotZ (1b)");
    Z_1c      = holdProfile(p.rot90,  tc,       p.dt);
    X_1b      = holdProfile(0,        tb,       p.dt);
    X_1c      = trapProfile(+p.rot90, tc,       p.aX, 0,       p.dt, p.vLim, p.aLim, "RotX (1c)");

    % ===== Reposo en la mitad (en Ltot, rot90, rot90) =====
    Y_mid = holdProfile(Ltot,    p.t_reposo_mid, p.dt);
    X_mid = holdProfile(p.rot90, p.t_reposo_mid, p.dt);
    Z_mid = holdProfile(p.rot90, p.t_reposo_mid, p.dt);

    % ===== HOME =====
    tH1 = t_home/2;
    tH2 = t_home/2;

    Y_home   = trapProfile(-Ltot,     t_home, p.aY, Ltot,   p.dt, p.vLim, p.aLim, "Y (Home)");
    Z_home1  = trapProfile(-p.rot90,  tH1,   p.aZ, p.rot90, p.dt, p.vLim, p.aLim, "RotZ (Home1)");
    Z_home2  = holdProfile(0,         tH2,   p.dt);
    X_home1  = holdProfile(p.rot90,   tH1,   p.dt);
    X_home2  = trapProfile(-p.rot90,  tH2,   p.aX, p.rot90, p.dt, p.vLim, p.aLim, "RotX (Home2)");

    % ===== Stitch (SIN reposo final) =====
    Y = stitchProfiles({Y_ini, Y_formado, Y_mid, Y_home});
    X = stitchProfiles({X_ini, X_1b, X_1c, X_mid, X_home1, X_home2});
    Z = stitchProfiles({Z_ini, Z_1b, Z_1c, Z_mid, Z_home1, Z_home2});

    % ===== Tiempos globales =====
    tMoveStart = p.t_reposo_ini;
    tB         = tMoveStart + tb;
    tC         = tMoveStart + t_formado;           % inicio reposo mitad
    tMidEnd    = tC + p.t_reposo_mid;              % fin reposo mitad / inicio home
    tH         = tMidEnd + tH1;
    tEnd       = tMidEnd + t_home;                 % fin ciclo (sin reposo final)

    % Checks
    checkLimitsSamples(Y, p.vLim, p.aLim, "Y");
    checkLimitsSamples(X, p.vLim, p.aLim, "RotX");
    checkLimitsSamples(Z, p.vLim, p.aLim, "RotZ");

    % ===== Máscaras "solo movimiento" (EXCLUYE reposo ini y reposo mitad) =====
    % Movimiento = (>= tMoveStart y <= tEnd) pero NO dentro de [tC, tMidEnd]
    maskMoveY = (Y.t >= tMoveStart) & (Y.t <= tEnd) & ~((Y.t >= tC) & (Y.t <= tMidEnd));
    maskMoveX = (X.t >= tMoveStart) & (X.t <= tEnd) & ~((X.t >= tC) & (X.t <= tMidEnd));
    maskMoveZ = (Z.t >= tMoveStart) & (Z.t <= tEnd) & ~((Z.t >= tC) & (Z.t <= tMidEnd));

    out.rmsY_move = sqrt(mean(Y.acc(maskMoveY).^2));
    out.rmsX_move = sqrt(mean(X.acc(maskMoveX).^2));
    out.rmsZ_move = sqrt(mean(Z.acc(maskMoveZ).^2));

    out.maxY_move = max(abs(Y.acc(maskMoveY)));
    out.maxX_move = max(abs(X.acc(maskMoveX)));
    out.maxZ_move = max(abs(Z.acc(maskMoveZ)));

    out.rmsY_all = sqrt(mean(Y.acc.^2));
    out.rmsX_all = sqrt(mean(X.acc.^2));
    out.rmsZ_all = sqrt(mean(Z.acc.^2));

    out.maxY_all = max(abs(Y.acc));
    out.maxX_all = max(abs(X.acc));
    out.maxZ_all = max(abs(Z.acc));

    out.vmaxY_move = max(abs(Y.v(maskMoveY)));
    out.vmaxX_move = max(abs(X.v(maskMoveX)));
    out.vmaxZ_move = max(abs(Z.v(maskMoveZ)));

    out.Y = Y; out.X = X; out.Z = Z;
    out.tMoveStart = tMoveStart; out.tB = tB; out.tC = tC; out.tMidEnd = tMidEnd; out.tH = tH;
    out.tEnd = tEnd;
    out.tu_move = tu_move;
    out.cajas_por_min_real = 60 / tEnd;
end

function checkLimitsSamples(p, vLim, aLim, name)
    tol = 1e-9;
    vmax_s = max(abs(p.v));
    amax_s = max(abs(p.acc));
    if vmax_s > vLim + tol
        error("'%s': |v|max=%.6g > vLim=%.6g", name, vmax_s, vLim);
    end
    if amax_s > aLim + tol
        error("'%s': |a|max=%.6g > aLim=%.6g", name, amax_s, aLim);
    end
end

function prof = trapProfile(dL, T, a, x0, dt, vLim, aLim, name)
    if a > aLim + 1e-12
        error("%s: a=%.6g excede aLim=%.6g", name, a, aLim);
    end

    L = abs(dL);
    sgn = sign(dL); if sgn == 0, sgn = 1; end

    disc = (a*T)^2 - 4*a*L;
    if disc < -1e-12
        a_min = 4*L/(T^2);
        error("%s: NO factible (a=%.6g < a_min=%.6g) L=%.6g T=%.6g", ...
            name, a, a_min, L, T);
    end
    disc = max(disc, 0);

    Vmax = (a*T - sqrt(disc))/2;
    if Vmax > vLim + 1e-12
        error("%s: Vmax=%.6g excede vLim=%.6g", name, Vmax, vLim);
    end

    t1 = Vmax/a;
    t2 = T - 2*t1; if t2 < 0, t2 = 0; end

    x1 = 0.5*a*t1^2;
    x2 = Vmax*t2;

    t = 0:dt:T;
    v = zeros(size(t));
    acc = zeros(size(t));
    x = zeros(size(t));

    i1 = (t <= t1);
    i2 = (t > t1) & (t <= (t1+t2));
    i3 = (t > (t1+t2));

    acc(i1) = +a;
    v(i1)   = a*t(i1);
    x(i1)   = 0.5*a*(t(i1)).^2;

    acc(i2) = 0;
    v(i2)   = Vmax;
    x(i2)   = x1 + Vmax*(t(i2)-t1);

    tau = t(i3) - (t1+t2);
    acc(i3) = -a;
    v(i3)   = Vmax - a*tau;
    x(i3)   = x1 + x2 + Vmax*tau - 0.5*a*(tau).^2;

    prof.t   = t(:);
    prof.x   = (x0 + sgn*x(:));
    prof.v   = (sgn*v(:));
    prof.acc = (sgn*acc(:));
end

function prof = holdProfile(x_hold, T, dt)
    t = 0:dt:T;
    prof.t = t(:);
    prof.x = x_hold*ones(numel(t),1);
    prof.v = zeros(numel(t),1);
    prof.acc = zeros(numel(t),1);
end

function full = stitchProfiles(profs)
    t_all = []; x_all = []; v_all = []; a_all = [];
    t_offset = 0;
    for k = 1:numel(profs)
        p = profs{k};
        if k == 1
            idx = 1:numel(p.t);
        else
            idx = 2:numel(p.t);
        end
        t_all = [t_all; p.t(idx) + t_offset];
        x_all = [x_all; p.x(idx)];
        v_all = [v_all; p.v(idx)];
        a_all = [a_all; p.acc(idx)];
        t_offset = t_all(end);
    end
    full.t = t_all; full.x = x_all; full.v = v_all; full.acc = a_all;
end
