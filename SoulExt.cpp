#include "stdio.h"
#include "stdlib.h"

int main(int argc,char* argv[])
{
	//Controllo che siano stati inseriti tutti i parametri
	if (argc<2)
	{
		printf("\nDecompressore per i sottofile degli archivi di SoulBlade by PhOeNiX.\n\n"); 
		printf("Sintassi: SoulExt.exe [File compresso SoulBlade] [File decompresso in uscita]"); 
		exit(0);
	}
	
	//Preparo le variabili necessarie
	FILE* input;
	FILE* output;
	unsigned char numero,byte;
	bool flag;
	int quantita,salto,finefile;
	short quantita1,salto1;
    
	//Apro i file interessati
	input = fopen(argv[1],"rb+");
	output = fopen(argv[2],"wb+");
    
	//Prendo la grendezza del file in entrata per il ciclo
	fseek(input,0,SEEK_END);
    finefile = ftell(input);
	fseek(input,0,SEEK_SET);
	//Inizio del ciclo della decompressione
	while (1)
	{ 
        if(ftell(input)==finefile) goto end; //Per precauzione, ma non dovrebbe mai accadere (non c'è byte riconoscitore di fine file)
        numero = getc(input); //Prendo il byte riconoscitore
        
        /* Se l'ultimo byte riconoscitore utilizza tutti i 7 flag, il compressore aggiunge cmq 
        un successivo byte riconoscitore (nullo), che non fa riferimento ad alcun dato 
        successivo visto che il file è finito. Controllo quindi se il byte riconoscitore 
        che ho appena preso, sia quello di fine file e quindi termino il ciclo */
        if(ftell(input)==finefile) goto end; 
		//Ciclo per la decompressione secondo i 7 flag
		for(int i=0;i<7;i++)
	    {
            //Prendo il flag
		    flag = numero&1;
		    numero >>= 1;

            if (flag) //Se il bit è 1 allora...
			{   
				putc(getc(input),output);//..metto direttamente il byte nel file...
				
			}else //...altrimenti calcolo la coppia salto/recupero.
			{
				//Carico i due byte della coppia:
				salto1 = getc(input); //Primo byte 
                quantita1 = getc(input); //Secondo byte             
				quantita = salto1>>3; //Calcolo la quantità di byte da recuperare
				if (quantita==0) quantita = 32; //Caso particolare: se 0 allora prendo il massimo (32)
				salto = ((salto1<<8)|quantita1)&2047; //Calcolo il salto
				if (salto==0) salto = 2048; //Caso particolare: se 0 allora do il valore 2048
				
				//Ciclo per la scrittura dei dati da recuperare
				for (int k=0;k<quantita;k++)
				    {
					    fseek(output,-salto,SEEK_END); //Mi posiziono...
					    byte = getc(output); //...e prendo un byte.
					    fseek(output,0,SEEK_END); //Vado alla fine del file...
					    putc(byte,output); //... e scrivo il byte recuperato.
					 }
               
		     }
	    if(ftell(input)==finefile) goto end; //Se non tutti i flag del riconoscitore vengono utilizzati allora fermo il ciclo
        }
	
    }
end:	printf("Decompressione completata.");
}

