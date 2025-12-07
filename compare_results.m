%% Porovnanie výkonu NC a PID regulátora na 5 scenároch
clc; 

% --- 1. NAČÍTANIE PARAMETROV (NAHRADTE VLASTNÝMI HODNOTAMI!) ---

% Parametre systému a simulácie (musia byť rovnaké ako v hlavnom tréneri)
dt = 0.05;  
refValues     = [90; 0];  
refValuesTime = [30; 30]; 
simTime = sum(refValuesTime);
steps = round(simTime/dt);
parameters = [0.010, 1;   1.2, 1;   0.010, 10;   1.2, 8;   0.5, 4];
nScenarios = size(parameters,1);
tVec = (0:steps-1)*dt;

% Dôležité: Tieto premenné musíte získať z hlavného kódu po trénovaní!
% Predpokladáme, že tieto premenné už existujú v pamäti po spustení main_ga_trainer.m
% AK ICH NEMÁTE, TÚTO ČASŤ NAHRAĎTE:
% load('best_NC_results.mat', 'bestIdx', 'wm1', 'wm2', 'wm3', 'fitness');
% bestIdx = min(fitness); 

% AKO PRÍKLAD SEM NAHRÁME FIKTÍVNE HODNOTY PID
% PID parametre (MUSIA BYŤ OPTIMALIZOVANÉ vopred)
Kp_pid = 0.2497; 
Ki_pid = 0;
Kd_pid = 0.3186;


% --- 2. INICIALIZÁCIA GRAFOV ---
figureOutput = figure('Name','NC vs PID - Výstupy y(t)');
figureControl = figure('Name','NC vs PID - Riadiace Signály u(t)');
yBest_NC = zeros(steps, nScenarios);
uBest_NC = zeros(steps, nScenarios);

% --- 3. TESTOVANIE NAJLEPŠIEHO NC (pre istotu) ---
disp('Testovanie finálneho Neuro-regulátora (NC)...');
for s = 1:nScenarios
    a1_val = parameters(s,1);
    b0_val = parameters(s,2);
    
    % Voláme funkciu NC regulátora (testRegulator)
    % POZOR: Pre správne fungovanie MUSÍTE mať v pamäti premenné: bestIdx, wm1, wm2, wm3
    [~, ~, yBest_NC(:,s), uBest_NC(:,s), ~, ~] = testRegulator(bestIdx, wm1, wm2, wm3, scenario1, simTime, dt, uMax, a1_val, b0_val);
end

% --- 4. TESTOVANIE PID REGULÁTORA ---
disp('Testovanie klasického PID regulátora...');
for s = 1:nScenarios
    a1_val = parameters(s,1);
    b0_val = parameters(s,2);

    % Voláme funkciu PID regulátora (simulatePID)
    [fit_PID, ~, yBest_PID, uBest_PID] = simulatePID(Kp_pid, Ki_pid, Kd_pid, scenario1, simTime, dt, uMax, a1_val, b0_val);
    fprintf('Fitness (ISE) PID v scenári %i je %.2f\n', s, fit_PID);

    % --- 5. VYKRESLOVANIE POROVNANIA ---
    
    % a) Výstup y(t)
    figure(figureOutput);
    subplot(nScenarios,1,s);
    plot(tVec, scenario1, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Referencia r(t)'); hold on;
    plot(tVec, yBest_NC(:,s), 'b', 'LineWidth', 1.5, 'DisplayName', 'NC Regulátor');
    plot(tVec, yBest_PID, 'r', 'LineWidth', 1.5, 'DisplayName', 'PID Regulátor');
    grid on;
    xlabel('Čas [s]'); ylabel('y(t)');
    title(['Výstup | Scenár ', num2str(s), ' (a1=', num2str(a1_val), ', b0=', num2str(b0_val), ')']);
    legend('show', 'Location', 'southeast');
    hold off;
    
    % b) Riadiaci Signál u(t)
    figure(figureControl);
    subplot(nScenarios,1,s);
    plot(tVec, uBest_NC(:,s), 'b', 'LineWidth', 1.5, 'DisplayName', 'NC u(t)'); hold on;
    plot(tVec, uBest_PID, 'r', 'LineWidth', 1.5, 'DisplayName', 'PID u(t)');
    grid on;
    xlabel('Čas [s]'); ylabel('u(t)');
    title(['Riadiaci Signál u(t) | Scenár ', num2str(s)]);
    legend('show', 'Location', 'southeast');
    hold off;
end