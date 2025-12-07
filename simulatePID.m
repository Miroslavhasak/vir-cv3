function [fitness, fitnessRatio, yLog, uLog] = simulatePID(Kp, Ki, Kd, scenario, simTime, dt, uMax, a1, b0)
    % Simuluje systém s klasickým PID regulátorom pre jeden scenár.
    
    % --- Fixné systémové parametre ---
    a0 = 1; a2 = 8; a3 = 1; a4 = 1; b1 = 0.1;
    steps = round(simTime / dt);
    
    % Prealokácia logov
    wLog = scenario(1:steps);
    yLog = zeros(steps,1);
    uLog = zeros(steps,1);
    
    % Inicializácia PID a stavov
    int_e = 0;
    prev_error = 0;
    y = 0; Dy = 0; D2y = 0; D3y = 0; % Plant states
    
    for k = 1:steps
        % --- Regulátor PID ---
        w = wLog(k);
        error = w - y;
        int_e = int_e + error * dt;
        dError = (error - prev_error) / dt;
        prev_error = error;
        
        u = Kp * error + Ki * int_e + Kd * dError;
        
        % Saturácia
        u = max(-uMax, min(uMax, u));
        uLog(k) = u;
        
        % --- Dynamika systému (Euler) ---
        if k == 1
            Du = 0;
        else
            Du = (u - uLog(k-1)) / dt;
        end
        
        % 4. derivácia y
        D4y_new = (b1 * Du + b0 * u - a3 * D3y - a2 * D2y - a1 * Dy - a0 * y) / a4;
        
        % Integrácia
        D3y_new = D3y + D4y_new * dt;
        D2y_new = D2y + D3y * dt;
        Dy_new  = Dy  + D2y * dt;
        y_new   = y   + Dy * dt;
        
        % Commit
        D3y = D3y_new; D2y = D2y_new; Dy  = Dy_new; y   = y_new;
        yLog(k) = y;
        
        % --- Kontrola explózie ---
        if abs(y) > 1e6 || abs(u) > 1e6 || isnan(y) || isnan(u)
            yLog(k:end) = y; uLog(k:end) = u;
            break;
        end
    end
    
    % --- FITNESS VÝPOČET ---
    err = abs(wLog - yLog);
    trackingErr = 1 * sum(err.^2);              % ISE
    oscPenalty = 5 * sum(diff(yLog/dt).^2);    % Penalizácia kmitov
    
    overshoot = yLog - wLog;
    overshootPenalty = 5 * sum(overshoot(overshoot > 0).^2); % Penalizácia prekmitu
    
    % Normalizácia
    trackingErr = trackingErr / steps;
    oscPenalty = oscPenalty / (steps - 1);
    overshootPenalty = overshootPenalty / steps;
    
    fitnessRatio = [trackingErr; oscPenalty; overshootPenalty];
    fitness = trackingErr + oscPenalty + overshootPenalty;
end