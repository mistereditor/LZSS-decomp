/*
Questo tool comprime file di ogni genere con una qualità di compressione accettabile.
Per il momento non supporta la compressione massima :), ma ci sto lavorando.
Buona lettura!

PhOeNiX
*/

#include "stdio.h"
#include "stdlib.h"

int main(int argc,char* argv[])
{
    if(argc<2)
    {
         printf("\nTool scritto da PhOeNiX che utilizza una variante della\nLZSS utilizzata dal gioco Soulblade per comprimere i file.\n\nSintassi: SoulCom.exe [Nome file da comprimere] [Nome file compresso in uscita]");
         exit(0);
    }           
    
     //Dichiaro le variabili
    FILE* input;
    FILE* output;
    unsigned char coppia[2],recupero=0,riconoscitore=0;
    unsigned char *buffer;
    short salto=0;
    int i=1,k=0,countnorm=1,countcom=0,filesize=0;
/*------------------------------------------------------------------------------*/    
    input=fopen(argv[1],"rb+");  //Apro...
    output=fopen(argv[2],"wb+"); //...i file.
    fseek(output,1,SEEK_END); //Lascio lo spazio per il primo riconoscitore
    //Alloco il buffer
    fseek(input,0,SEEK_END);
    filesize=ftell(input);
    buffer = new unsigned char[filesize];
    fseek(input,0,SEEK_SET);
    fread(buffer,filesize,1,input);  //Carico il buffer
    putc(buffer[0],output);  //Scrivo il primo byte, visto che ci sarà per forza
    riconoscitore=1;  //Aggiorno il riconoscitore
    while(1)
    {
        if(i==filesize) 
        {
            if(i==1){ fseek(output,0,SEEK_SET); putc(0x81,output); exit(0);} //Se il file è grande un byte, devo fermare il ciclo subito e completare il riconoscitore
            else{exit(0); } //Questo controllo serve ad ogni fine ciclo, per terminare il programma in caso il file sia stato compresso completamente
        }
        while(buffer[i]==buffer[k])  //Controllo fin dove ci sono byte da recuperare
        {
            i++;
            k++;
            recupero++;
            if(recupero==32) break;  //Devo limitare il recupero a 32
            if(i==filesize) break; //Mentre sto cercando, devo stare attento a non sforare nel buffer
        }
        if(recupero<3) //Se ho trovato poco
        { 
            //Se sono arrivato alla fine, vuol dire che non ho trovato niente di utile e scrivo direttamente il byte
            if(i-k==1)
            { 
                //ho trovato poco, scrivo direttamente e mi preparo per una nuova ricerca
                putc(buffer[i-recupero],output); 
                i -=recupero-1; 
                if(i<=2048) k=0;
                else k=i-2048;
                recupero=0; 
                countnorm++; //Ricordo quanti byte normali ho scritto fin ora
                riconoscitore |=1<<(countnorm+countcom-1); //Aggiorno il riconoscitore
            }else //Non sono alla fine:
            {
                i -=recupero; k -=recupero-1; recupero=0; //Ho trovato poco, mi preparo per cercare ancora.
            }
        }else //...Altrimenti...
        {
            
            if(i-k==2048) salto=0;  //Caso particolare per il salto
            else salto=i-k;         //Calcolo il salto normalmente
            if(recupero==32) recupero=0; //Caso particolare per il recupero
            coppia[0]=((recupero<<11)|salto)>>8;   //Preparo la...
            coppia[1]=((recupero<<11)|salto)&255;  //...coppia.
            fwrite(coppia,2,1,output);             //Scrivo la coppia.
            if(i<=2048) k=0;                       //Azzero...
            else k=i-2048;
            recupero=0;                            //...tutto.
            countcom++;  //Ricordo quante coppie ho scritto fin ora  
            //N.B. Non aggiorno il riconoscitore in quanto un OR con 0 shiftato è inutile ;)
        }
        if((countnorm+countcom==7)||(i==filesize)) //Ho finito i 7 flag oppure sono arrivato alla fine del file e completo il riconoscitore cmq
        { 
            riconoscitore |= 0x80; //Completo il riconoscitore
            fseek(output,-(countnorm+2*countcom+1),SEEK_CUR);  //Mi sposto indietro
            putc(riconoscitore,output); //Scrivo il riconoscitore
            if((i==filesize)&&(countnorm+countcom==7)){ fseek(output,0,SEEK_END); putc(0x00,output); } //Se nell'ultimo riconoscitore ho usato tutti i flag, devo scrivere un riconoscitore nullo alla fine (non so perché lo hanno messo)
            else{ fseek(output,1,SEEK_END); } //Torno alla fine del file lasciando un byte libero per il prossimo riconoscitore (+1)
            countnorm=0; countcom=0; riconoscitore=0; //Azzero tutto
        }
    }
delete buffer;
}
