function [fitness, wLog, yLog, uLog, netInLog, fitnessRatio] = testRegulator(idx, wm1, wm2, wm3, scenario, simTime, dt, uMax, a1, b0)
    % Testuje jeden Neuro-regulátor (daný indexom idx a váhami wm1, wm2, wm3)
    % na jednom scenári a vráti fitness (ISE).
    
    % --- Nastavenie simulácie ---
    steps = round(simTime / dt);
    scenario = scenario(:);
    
    % Inicializácia logov a systémových parametrov
    wLog = scenario(1:steps);
    yLog = zeros(steps,1);
    uLog = zeros(steps,1);
    netInLog = zeros(steps,7); % 7 vstupov
    a0 = 1; a2 = 8; a3 = 1; a4 = 1;
    b1 = 0.1;
    
    % Počiatočné stavy
    y = 0; Dy = 0; D2y = 0; D3y = 0;
    u = 0; Du = 0;
    intError = 0;
    prev_error = 0;
    prev_dError = 0; % Musí byť inicializované
    yExploded = false;
    
    % Inicializácia pre špecifické fitness zložky
    signalNotChanged = 0;
    currentW = 0;
    didNotMinimized = 0;
    wobbling = 0;
    
    % Inicializácia NC vstupov
    yRatio = 0; DyRatio = 0; eFut = 0;

    % --- SIMULÁCIA ---
    for k = 1:steps       
        w = wLog(k);
        
        % Detekcia zmeny referencie
        if abs(currentW-w)>0.01 
            currentW = w;
            signalNotChanged = 0;
        else
            signalNotChanged = signalNotChanged + 1;
        end
        
        % Výpočet chyby a jej derivácií
        error = w - y;
        intError = intError + error * dt;
        intError = max(-100, min(100, intError)); % Obmedzenie integrálu
        
        dError = (error - prev_error) / dt;
        if k == 1
            ddError = 0;
        else
            ddError = (dError - prev_dError) / dt;
        end
        prev_dError = dError;
        prev_error = error;
    
        % NN vstup & odozva
        inputVec = [error; dError; ddError; intError*0.02; yRatio; DyRatio*8; eFut]; % Upravené zosilnenie 0.02
        netInLog(k,:) = inputVec;
        raw_u = respond(inputVec, idx, wm1, wm2, wm3);
    
        % Saturácia
        u = raw_u * uMax;
        u = max(-uMax, min(uMax, u));
        uLog(k) = u;
    
        % --- Dynamika systému (Euler) ---
        if k == 1
            Du = 0;
        else
            Du = (u - uLog(k-1)) / dt;
        end
        
        % 4. derivácia y
        % Pozn: Pôvodný kód obsahoval nelineárny člen (1 + abs(y)/3) * D3y, 
        % ale v kóde, ktorý si mi poslal, je a3*D3y. Používam Tvoj kód:
        D4y_new = (b1 * Du + b0 * u - a3 * D3y - a2 * D2y - a1 * Dy - a0 * y) / a4; 
        
        % Integrácia
        D3y_new = D3y + D4y_new * dt;
        D2y_new = D2y + D3y * dt;
        Dy_new  = Dy  + D2y * dt;
        y_new   = y   + Dy * dt;
        
        % Commit updates
        D3y = D3y_new; D2y = D2y_new; Dy  = Dy_new; y   = y_new;
        
        % --- Predikcia chyby (Future Error) ---
        Tpred = 3; 
        yFut = y + Dy*Tpred + 0.5*D2y*(Tpred^2);
        eFut = w - yFut;
        
        % Log výstup
        yLog(k) = y;
        
        % Výpočet pomerov (Dynamic Identification)
        uSafe = u;
        if abs(uSafe) < 0.01
            uSafe = 0.01 * sign(uSafe + 1e-6); % Zabránenie deleniu nulou
        end
        yRatio  = y  / uSafe;           
        DyRatio = Dy / uSafe;
        
        % Fitness zložka pre ustálený stav
        if (signalNotChanged*dt)>15
            didNotMinimized = didNotMinimized + 100*error*error;
            wobbling = wobbling + 1000*Dy*Dy;
        end
        
        % --- Kontrola explózie (Early termination check) ---
        if abs(y) > 500 || abs(u) > 500 || isnan(y) || isnan(u) % Znížená hranica na 500
            yExploded = true;
            break;
        end
    end
    
    % --- FITNESS KOMPILÁCIA ---   
    err = abs(wLog - yLog);
    trackingErr = sum(err.^2);
    
    % Penalizácia prekročenia rozsahu <0;100>
    aboveMax = yLog > 100;     belowMin = yLog < 0;            
    penaltyHigh = sum((yLog(aboveMax) - 100).^2);
    penaltyLow  = sum((0 - yLog(belowMin)).^2);    
    outOfBoundsPenalty = 100 * (penaltyHigh + penaltyLow);
    
    fitnessRatio = [didNotMinimized; trackingErr; wobbling; outOfBoundsPenalty];
    fitness =  didNotMinimized + trackingErr + wobbling + outOfBoundsPenalty;
    
    % Váhovanie fitness podľa b0 (robustnosť)
    fitness = fitness * (10/b0);
    
    if yExploded
        fitness = fitness + 1e9; % Veľká penalizácia
        fitnessRatio = [NaN; NaN; NaN; NaN];
    end
end