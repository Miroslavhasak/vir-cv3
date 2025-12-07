function netOutput = respond(input, i, wm1, wm2, wm3)
    % Vypočíta výstup neurónovej siete (NC) pre daný vstup 'input'.
    % idx (i) je index chromozómu v populácii.
    
    % 1. vrstva
	A1 = (squeeze(wm1(i,:,:)) * input);
	O1 = max(-1, min(1, A1)); % Saturácia -1 až 1
    
    % 2. vrstva
	A2 = (squeeze(wm2(i,:,:)) * O1);
	O2 = max(-1, min(1, A2)); % Saturácia -1 až 1
    
    % Výstupná vrstva
	Y = (squeeze(wm3(i,:,:))' * O2);
    
    % Konečný výstup (akčný zásah)
	netOutput = max(-1, min(1, Y));
end