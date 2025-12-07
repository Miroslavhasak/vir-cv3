function [wm1, wm2, wm3] = weightMatrices(pop, inputs, hidden, outputs)
	% Prevedie vektor váh (chromozóm) z populácie (pop) do matíc W1, W2, W3.
    
	w1i = inputs;	w1h = hidden;	% W1: input x hidden
	w2i = hidden;	w2h = hidden;	% W2: hidden x hidden
	w3i = hidden;	w3o = outputs;	% W3: hidden x output
    
	% Výpočet indexov pre rozdelenie vektora
	z1 = w1i * w1h;
	z2 = z1 + 1;
	z3 = z2 + w1h * w2h - 1;
	z4 = z3 + 1;
	z5 = z4 + w2h * w3o - 1;
    
	popsize = size(pop,1);
	wm1 = zeros(popsize, hidden, inputs);
	wm2 = zeros(popsize, hidden, hidden);
	wm3 = zeros(popsize, outputs, hidden);
    
	for i=1:popsize
		ch1 = pop(i,1:z1);   % Váhy W1
		ch2 = pop(i,z2:z3);  % Váhy W2
		ch3 = pop(i,z4:z5);  % Váhy W3
        
		wm1(i,:,:) = reshape(ch1, w1i, w1h)';
		wm2(i,:,:) = reshape(ch2, w1h, w2h)';
		wm3(i,:,:) = reshape(ch3, w2h, w3o)';
	end
end