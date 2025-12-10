Attribute VB_Name = "LZ77Code_Decompress"
'/******************************************************
'/  Autore   : Morpher.
'/  Grazie a : Gemini, Clomax, Phoenix, Sephiroth 1311
'/             Brisma, Ge0 e a tutti gli altri che
'/             bazzicano su romhacking.it
'/******************************************************
'// Questo modulo nasce per coloro che utilizzano il vb6
'// perchè con il C/C++ non vanno proprio daccordo :P.
'// La routine permette di decomprimere la grafica di DejaVU I&II
'// E ora vediamo di iniziare:

'// Variabili utilizzate dall'intero modulo
Dim AndArray(1 To 8) As Integer   '// Servirà per la routine YoN
Dim BteFlag          As Integer   '// Questa variabile conterrà il byte flag
Dim OutFile          As String    '// Indovinate cosa contiene questa var :D
                                  '// (il file decompresso)
Dim CmpByte(1)       As String    '// Ricordatevi che qui ci vanno
                                  '// 2 valori e non 1 solo.
'// Costanti
Const PoM = -1                    '// Usata nella funzione di conv. da hex a dec

'// Non credo ci sia bisogno di spiegare questa prima
'// linea di codice.
Public Sub Decompress(FleBuffer As String)
    '// Dichiariamo le variabili
    Dim BufLoop     As Long       '// Servirà per il ciclo
    Dim LenBuff     As Long       '// Conterrà la lunghezza del buffer
    Dim BitLoop     As Integer    '// Questo è per il loop dei bits
                                  
    Dim LenJump     As Long       '// Questa è per il salto e...
    Dim LenBytes    As Long       '// ...questa è per il recupero...
    Dim GetLoop     As Long       '// ...e questa è per il loop.
    
    '// Passiamo la lunghezza del buffer alla variabile
    '// , svuotiamo OutFile e azzeriamo BufLoop
    LenBuff = Len(FleBuffer)
    OutFile = vbNullString
    BufLoop = 0
    '// Cominciamo con un bel Do
    Do Until BufLoop = LenBuff
        BufLoop = BufLoop + 1                     '// Incrementiamo bufloop
        BteFlag = Asc(Mid(FleBuffer, BufLoop, 1)) '// Questa var contiene il flag byte
        '// Ecco il ciclo più succoso :)
        For BitLoop = 1 To 8
            BufLoop = BufLoop + 1
            '// Ora, per evitare errori controlliamo se bufloop è maggiore
            '// di lenbuff e se lo è usciamo dalla sub. Il file è decompresso.
            If BufLoop > LenBuff Then Exit Sub
            If YoN(BitLoop) Then        '// Controlliamo se il bit è 1 o 0
                '// Se è 1 bisogna prendere il byte così com'è
                OutFile = OutFile & Mid(FleBuffer, BufLoop, 1)
            Else
                '// Altrimenti è compresso e...
                '// ...prendiamo i byte del salto e del recupero e lavoriamo sui
                '// nibbles (8 bits = 1 byte, 4 bits = 1 nibble). Personalmente
                '// preferisco utilizzare le funzioni di shift (<< o >>) e bitwise
                '// per elaborare i nibbles ma dato che il codice diventerebbe
                '// un tantino più complesso e l'uomo è pigro per sua natura :P
                '// seguirò una via più semplice.
                CmpByte(0) = Hex(Asc(Mid(FleBuffer, BufLoop, 1)))
                BufLoop = BufLoop + 1       '// Incrementiamo il bufloop per prendere
                                            '// il byte successivo e convertiamo ancora in hex
                CmpByte(1) = Hex(Asc(Mid(FleBuffer, BufLoop, 1)))
                Call CheckLen               '// Richiama la sub di controllo
                '// E ora spostiamo i nibbles per ottenere
                '// salto e recupero. Ah, quasi dimenticavo di chiarire
                '// come vanno disposti i nibbles. Immaginiamo di avere 2 byte
                '// e indichiamo con 4 lettere diverse i 4 nibbles di cui sono
                '// composti:
                '// ab cd
                '// Il salto sarà dato da (cab+1) mentre il recupero da (d+2).
                CmpByte(0) = Left(CmpByte(1), 1) & CmpByte(0)
                CmpByte(1) = Right(CmpByte(1), 1)
                
                '// Convertiamo da hex a dec e passiamo tutto alle giuste
                '// variabili:
                LenJump = hDec(CmpByte(0)) + 1
                LenBytes = hDec(CmpByte(1)) + 2
                '// E ora sappiamo dove e quanti caratteri prendere quindi:
                For GetLoop = LenJump To (LenJump + LenBytes)
                    OutFile = OutFile & Mid(OutFile, GetLoop, 1)
                Next GetLoop
            End If
        Next BitLoop
    '// E quindi chiudiamo con un bel Loop
    Loop
End Sub

'// Questa routine inizializza alcune variabili, niente più, niente meno
Public Sub MakeVar()
    Dim FillLoop    As Integer
    '// Viene riempito l'array
    For FillLoop = 0 To 7
        AndArray(FillLoop + 1) = 2 ^ FillLoop
    Next FillLoop
End Sub

'// Questa funzione [YoN: Yes or Not (nome molto fantasioso)]
'// restituisce 2 valori: True(1) o False(0) in base ai bits
'// del flag byte. In questo modo è possibile stabilire se
'// bisogna prendere il singolo byte o se il blocco di byte
'// è compresso. (0=Compresso, 1=Non compresso)

Public Function YoN(BitsPos As Integer) As Boolean
    If (BteFlag And AndArray(BitsPos)) = AndArray(BitsPos) Then
    YoN = True
    Else: YoN = False
    End If
End Function

'// Questa funzione converte da hex a dec. Ora in vb non è possibile
'// dichiarare varianti di tipo unsigned (come in c/c++). Detto questo
'// è facile comprendere come, a volte, una routine come questa non possa
'// funzionare a dovere:
'// xxx = Val("&H" & hex)
'// In effetti puo capitare che alcune volte restituisca valori minori di 0.
'// Per evitare questo spiacevole inconveniente ho inserito un check del segno.

Public Function hDec(HexVal As String) As Long
    hDec = Val("&H" & HexVal)
    '// Controlla se il segno è uguale a -1
    '// e se lo è aggiunge &H1000 (65536)
    If Sgn(hDec) = PoM Then hDec = hDec + 65536
End Function

'// Questa sub controlla che il valore hex sia composto da 2 cifre.
'// Se ad esempio abbiamo che Cmpbyte(0) = "A" dobbiamo preporre al valore
'// uno "0". Questo serve per ottenere il GIUSTO salto.

Public Sub CheckLen()
    If Len(CmpByte(0)) < 2 Then CmpByte(0) = "0" & CmpByte(0)
    If Len(CmpByte(1)) < 2 Then CmpByte(1) = "0" & CmpByte(1)
End Sub

'// Al posto di un qualsiasi evento ci piazzo una bella Main
Public Sub Main()
    Dim InFile      As String        '// Buffer del file compresso
    Dim fFile       As Integer       '// Per il freefile
    Dim PathFile    As String        '// Riempila con il percorso del file
    
    PathFile = ""
    fFile = FreeFile
    '// Al posto di PathFile metteteci il percorso del vostro file (provate
    '// con il file FontCompresso.cmp che dovreste trovare nell'archivio)
    Open PathFile For Binary As fFile
        '// Allochiamo spazio nel buffer
        InFile = Space(LOF(fFile))
        '// E carichiamolo tutto d'un colpo
        Get fFile, , InFile
    '// Chiudiamo il file
    Close fFile
    
    Call MakeVar        '// Inizializziamo l'array altrimenti
                        '// la routine non funziona correttamente
    
    '// E ora decomprimiamo il file
    Decompress InFile
                        
    '// Ora tocca a te: mettici i comandi per creare un nuovo file
    '// e scriverci la var OutFile. Vabbè dai lo faccio io:
    fFile = FreeFile
    Open (PathFile & ".dcm") For Binary As fFile
        Put fFile, , OutFile
    Close fFile
    
    '// Non era così difficile :D
    
End Sub
