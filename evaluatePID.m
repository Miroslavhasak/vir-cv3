function totalFitness = evaluatePID(Kp, Ki, Kd)
    % Tato funkcia zoberie Kp, Ki, Kd a otestuje ich na vsetkych 5 scenaroch.
    
    % --- Nastavte parametre, rovnake ako v testRegulator! ---
    dt = 0.05; simTime = 60; uMax = 100; % Príklad hodnôt
    parameters = [0.012, 1;   1.2, 1;   0.012, 10;   1.2, 10;   0.5, 5];
    scenario1 = [ones(30/dt, 1)*90; ones(30/dt, 1)*0]; % Príklad scenára

    sumOfAllFitnesses = 0;
    
    for s = 1:size(parameters, 1)
        a1_val = parameters(s, 1);
        b0_val = parameters(s, 2);
        
        % Zavolanie vasej existujucej funkcie simulatePID
        [fit_PID, ~, ~, ~] = simulatePID(Kp, Ki, Kd, scenario1, simTime, dt, uMax, a1_val, b0_val);
        
        % Ak system exploduje (vysoka fitness), vratime vysoku hodnotu
        if fit_PID > 1e6
            totalFitness = 1e9;
            return;
        end
        
        % Spocitanie fitness cez vsetky scenare (robíme to robustné!)
        % Môžete pridať aj váhovanie, ak chcete penalizovať tažké scenáre
        sumOfAllFitnesses = sumOfAllFitnesses + fit_PID;
    end
    
    % Celkova fitness je sucet chyb zo vsetkych scenarov
    totalFitness = sumOfAllFitnesses; 
end