# Verilog-Image-Processing
Am implementat un automat ce contine 25 stari finite: 6 stari pentru task-ul “mirror”, 6 stari pentru task-
ul “grayscale”, si 13 stari pentru “sharpness”. 

 

Pentru task-ul “mirror” am generat o stare initiala(IDLE), apoi am continuat prin citirea pixelilor. Pentru a 
putea privi matricea ca 2 jumatati, operatiunea de citire a pixelilor am impartit-o in  “Read_first_pixel” si 
“Read_last_pixel_write_first_pixel” ; aceasta din urma include simultan si interschimbarea pixelului din 
prima jumatate a pozei, el luand valoarea ultimului pixel din imagine(stanga jos). Apoi, am continuat prin 
scrierea pixelului din a doua jumatate a pozei in locul primului pixel (stanga sus), incrementarea indexilor, 
si finalizarea actiunii ‘mirror’.  

 

Pentru task-ul “grayscale”, am inceput cu o stare initiala (“Initial_gray”), iar pentru citirea pixelilor 
implementat o singura stare (“Read_pixel”). In starea “Maxim_Minim_calculus” sunt calculate minimul si 
maximul dintre cele 3 canale R,G,B al fiecarui pixel(in_pix). Apoi, se trece in starea in care scriem in 
out_pix valoarea ceruta, adica canalele R si B 0 si canalul G media dintre minimul si maximul acestora , 
conform cerintei. Urmeaza starea de incrementare a indexilor, unde se face pentru toata matricea 
deoarece nu mai suntem fortati sa ne oprim la jumatate ca in cazul actiunii ‘mirror’. In final, avem starea 
‘donegr’ care semnalizeaza terminarea actiunii ‘grayscale’. 

 

Pentru task-ul “sharpness”, am inceput cu o stare de initializare “initial_sharpness”, urmata de o stare in 
care citim pixelii din matricea imagine, dar si setam indexii de rand si coloana pentru urmatoarea stare. 
In continuare avem 8 stari de citire a fiecarui vecin al pixelului selectat din matricea imagine. De 
asemenea, acoperim si conditia ca in cazul in care vecinii se afla in afara matricii imagine sa ia valoarea 0. 
Apoi urmeaza starea in care calculam si scriem in out_pix suma celor 9 inmultiri intre elementele 
matricilor (cea de vecini si SharpMatrix). Starea de increment a indexilor si starea ‘sharp_done’ incheie 
actiunea ‘sharpness’. Motivul pentru care eu cred ca nu mi face total ceea ce trebuie in cadrul actiunii 
sharpness este faptul ca nu cred ca citesc de la randul si coloana corespunzatoare fiecarui vecin. 
