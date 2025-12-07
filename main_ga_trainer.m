%% Nonlinear System with NC Neuroevolution Trainer
clear; clc; close all;

% --- 1. Nastavenie simulácie a scenárov ---
refValues     = [90; 0];  
refValuesTime = [30; 30]; 
simTime = sum(refValuesTime);
dt = 0.05;  
steps = round(simTime/dt);
parameters = [0.010, 1;   1.2, 1;   0.010, 10;   1.2, 8;   0.5, 4];
nScenarios = size(parameters,1);
nRefs = length(refValues);

% Generovanie referenčnej trajektórie
scenario1 = zeros(steps,1);
currentStep = 1;
for i = 1:nRefs
    durationSteps = round(refValuesTime(i)/dt);
    endStep = min(currentStep + durationSteps - 1, steps);
    scenario1(currentStep:endStep) = refValues(i);   
    currentStep = endStep + 1;    
    if currentStep > steps
        break;
    end
end
uMax = 300; 

% --- 2. Nastavenie Neuro-regulátora (NN) a GA ---
popsize = 100;
generations = 50;
inputs = 7;         
outputs = 1;        
hidden = 12;        
chromLen = inputs*hidden + hidden*hidden + hidden*outputs;

% Definovanie rozsahu pre váhy (GA Space)
Space = zeros(2, chromLen);
for i = 1:chromLen
    Space(1, i) = -1.5;
    Space(2, i) = 1.5;
end
SpaceInit = Space*0.001; % Extrémne konzervatívna inicializácia pre stabilitu

% Inicializácia populácie
pop = genrpop(popsize, SpaceInit);
[wm1, wm2, wm3] = weightMatrices(pop, inputs, hidden, outputs);
fitness = zeros(popsize,1);
best = zeros(generations,1);
wereInvalid = zeros(generations,1);

% Nastavenia pre GA funkcie (predpokladáme, že fungujú s poliami [1 1 1])
prefer = [1 1 1];
prefer2 = [5 5 5];
limitAdd = 0.1;
Amp = zeros(1, chromLen) + limitAdd;

% --- 3. Hlavný cyklus Genetického Algoritmu ---
for g = 1:generations
    disp(['Generácia cislo ', num2str(g)]);
    
    for h = 1:popsize
        totalFitness = 0;
        validScenarios = 0;
        try
            % Testovanie na prvých 4 scenároch (na robustnosť)
            for s = 1:nScenarios-1
                a1_val = parameters(s,1);
                b0_val = parameters(s,2);
                
                % Volanie fitness funkcie
                [fit, ~, ~, ~, ~, fitnessRatio] = testRegulator(h, wm1, wm2, wm3, scenario1, simTime, dt, uMax, a1_val, b0_val);
                
                if any(isnan(fitnessRatio)) || any(isinf(fitnessRatio))
                    totalFitness = totalFitness + 1e9;
                    wereInvalid(g,1) = wereInvalid(g,1) + 1;
                    continue;
                end
                
                totalFitness = totalFitness + fit;
                validScenarios = validScenarios + 1;
            end
            
            % Priemerovanie fitness pre validné scenáre
            if validScenarios > 0
                fitness(h) = totalFitness / validScenarios;
            else
                fitness(h) = 1e9; % Veľká penalizácia, ak všetky scenáre zlyhali
            end
        catch ME
            disp(['Chyba v chromozóme ', num2str(h), ': ', ME.message]);
            fitness(h) = 1e9;
        end
    end
    
    % --- GA Operácie (Selekcia, Kríženie, Mutácia) ---
    validFitness = fitness(~isnan(fitness) & ~isinf(fitness) & fitness ~= 0);
    if isempty(validFitness)
        disp('Všetci jedinci zlyhali — resetovanie populácie.');
        pop = genrpop(popsize, SpaceInit);
        fitness(:) = 1e9;
        best(g,1) = 1e9;
        continue;
    else
        best(g,1) = min(validFitness);
    end

    Ultrapop = selbest(pop,fitness,prefer);
    Elitepop = selbest(pop,fitness,prefer2);
    Restpop  = seltourn(pop,fitness,popsize-sum(prefer)-sum(prefer2));
    Crospop  = crossov([Elitepop; Restpop],1,0);
    Mutpop   = mutx(Crospop,0.01,Space);
    Mutpop   = muta(Mutpop,0.05,Amp,Space);
    pop = [Ultrapop; Mutpop];
    [wm1, wm2, wm3] = weightMatrices(pop, inputs, hidden, outputs);
end

% --- 4. Vyhodnotenie a Vykreslenie výsledkov ---
figure('Name','Evolution Statistics');
plot(1:g, best, 'r', 'LineWidth', 2);
xlabel('Generácia'); ylabel('Najlepšia Fitness');
title('Evolúcia fitness Neuro-regulátora'); grid on;
[bestFitness, bestIdx] = min(fitness);
disp(['Najlepšia dosiahnutá Fitness: ', num2str(bestFitness)]);

tVec = (0:steps-1)*dt;

% Testovanie finálneho regulátora na všetkých 5 scenároch
for s = 1:nScenarios
    a1_val = parameters(s,1);
    b0_val = parameters(s,2);
    
    [fitnes(s), wBest, yBest, uBest, netInLog, fitnessRatio] = testRegulator(bestIdx, wm1, wm2, wm3, scenario1, simTime, dt, uMax, a1_val, b0_val);
    fprintf('Fitness (ISE) v scenári %i pre vyvinutý NC je %.2f\n', s, fitnes(s));
    
    % *** ZMENA ZAČÍNA TU ***
    
    % 1. Vykreslenie Výstupu y(t)
    figure('Name',['NN vs Different Parameter Scenarios - Scenár ', num2str(s)]);
    plot(tVec, yBest, 'b', tVec, scenario1, 'r--', 'LineWidth', 1.5);
    grid on;
    xlabel('Čas [s]'); ylabel('y(t)');
    title(['Scenár ', num2str(s), ' | a1=', num2str(a1_val), ', b0=', num2str(b0_val)]);
    legend('Výstup y(t)', 'Referencia r(t)');
    
    % 2. Vykreslenie Riadiaceho Signálu u(t)
    figure('Name',['Control Signal u(t) - Scenár ', num2str(s)]);
    plot(tVec, uBest, 'LineWidth', 1.2);
    grid on;
    xlabel('Čas [s]'); ylabel('u(t)');
    title(['Riadiaci Signál u(t) - Scenár ', num2str(s)]);
    
    % 3. Vykreslenie Vstupov NN
    figure('Name',['Neural Network Inputs - Scenár ', num2str(s)]);
    plot(tVec, netInLog, 'LineWidth', 1.2);
    grid on;
    xlabel('Čas [s]'); ylabel('Vstupy NN(t)');
    title(['Vstupy NN - Scenár ', num2str(s)]);
    legend('e','de','dde','int(e)', 'yRatio', 'DyRatio', 'eFut', 'Location', 'best');
    
    % *** ZMENA KONČÍ TU ***
end
