unit uI18n;

interface

uses
  Classes, SysUtils, Forms;

type
  TAppLanguage = (alEnglish, alPortuguese, alSpanish, alFrench, alGerman, alItalian,
                   alPolish, alPortuguesePT, alRomanian, alHungarian, alCzech);

function AppLanguageFromCode(const Code: string): TAppLanguage;
function AppLanguageCode(const Lang: TAppLanguage): string;
procedure SetCurrentLanguage(const Lang: TAppLanguage);
function GetCurrentLanguage: TAppLanguage;
function Tr(const Key, DefaultText: string): string;
function TrText(const DefaultText: string): string;
procedure ApplyTranslationsToForm(AForm: TCustomForm);

implementation

uses
  TypInfo;

var
  GCurrentLanguage: TAppLanguage = alEnglish;
  GEnglish: TStringList = nil;
  GPortuguese: TStringList = nil;
  GSpanish: TStringList = nil;
  GFrench: TStringList = nil;
  GGerman: TStringList = nil;
  GItalian: TStringList = nil;
  GPolish: TStringList = nil;
  GPortuguesePT: TStringList = nil;
  GRomanian: TStringList = nil;
  GHungarian: TStringList = nil;
  GCzech: TStringList = nil;
  GTextEnglish: TStringList = nil;
  GTextPortuguese: TStringList = nil;
  GTextSpanish: TStringList = nil;
  GTextFrench: TStringList = nil;
  GTextGerman: TStringList = nil;
  GTextItalian: TStringList = nil;
  GTextPolish: TStringList = nil;
  GTextPortuguesePT: TStringList = nil;
  GTextRomanian: TStringList = nil;
  GTextHungarian: TStringList = nil;
  GTextCzech: TStringList = nil;

function CreateTable: TStringList;
begin
  Result := TStringList.Create;
  Result.CaseSensitive := False;
  Result.NameValueSeparator := '=';
end;

{ --- Fast binary-search helpers ------------------------------------------- }

function ExtractKeyPart(const S: string; Sep: Char): string;
var
  P: Integer;
begin
  P := Pos(Sep, S);
  if P > 0 then
    Result := Copy(S, 1, P - 1)
  else
    Result := S;
end;

function CompareTableByKey(List: TStringList; Index1, Index2: Integer): Integer;
begin
  Result := CompareText(
    ExtractKeyPart(List[Index1], List.NameValueSeparator),
    ExtractKeyPart(List[Index2], List.NameValueSeparator));
end;

function FastIndexOfName(Table: TStringList; const Name: string): Integer;
var
  Lo, Hi, Mid, Cmp: Integer;
begin
  Result := -1;
  if (Table = nil) or (Table.Count = 0) then Exit;
  Lo := 0;
  Hi := Table.Count - 1;
  while Lo <= Hi do
  begin
    Mid := (Lo + Hi) shr 1;
    Cmp := CompareText(ExtractKeyPart(Table[Mid], Table.NameValueSeparator), Name);
    if Cmp = 0 then
    begin
      Result := Mid;
      Exit;
    end
    else if Cmp < 0 then
      Lo := Mid + 1
    else
      Hi := Mid - 1;
  end;
end;

procedure SortTablesForFastLookup;
begin
  if Assigned(GEnglish)        then GEnglish.CustomSort(CompareTableByKey);
  if Assigned(GPortuguese)     then GPortuguese.CustomSort(CompareTableByKey);
  if Assigned(GSpanish)        then GSpanish.CustomSort(CompareTableByKey);
  if Assigned(GFrench)         then GFrench.CustomSort(CompareTableByKey);
  if Assigned(GGerman)         then GGerman.CustomSort(CompareTableByKey);
  if Assigned(GItalian)        then GItalian.CustomSort(CompareTableByKey);
  if Assigned(GPolish)           then GPolish.CustomSort(CompareTableByKey);
  if Assigned(GPortuguesePT)     then GPortuguesePT.CustomSort(CompareTableByKey);
  if Assigned(GRomanian)         then GRomanian.CustomSort(CompareTableByKey);
  if Assigned(GHungarian)        then GHungarian.CustomSort(CompareTableByKey);
  if Assigned(GCzech)            then GCzech.CustomSort(CompareTableByKey);
  if Assigned(GTextEnglish)      then GTextEnglish.CustomSort(CompareTableByKey);
  if Assigned(GTextPortuguese)   then GTextPortuguese.CustomSort(CompareTableByKey);
  if Assigned(GTextSpanish)      then GTextSpanish.CustomSort(CompareTableByKey);
  if Assigned(GTextFrench)       then GTextFrench.CustomSort(CompareTableByKey);
  if Assigned(GTextGerman)       then GTextGerman.CustomSort(CompareTableByKey);
  if Assigned(GTextItalian)      then GTextItalian.CustomSort(CompareTableByKey);
  if Assigned(GTextPolish)       then GTextPolish.CustomSort(CompareTableByKey);
  if Assigned(GTextPortuguesePT) then GTextPortuguesePT.CustomSort(CompareTableByKey);
  if Assigned(GTextRomanian)     then GTextRomanian.CustomSort(CompareTableByKey);
  if Assigned(GTextHungarian)    then GTextHungarian.CustomSort(CompareTableByKey);
  if Assigned(GTextCzech)        then GTextCzech.CustomSort(CompareTableByKey);
end;

procedure AddRuntimeDialogProgressTranslations;
begin
  { Dialog / progress runtime captions }
  GTextEnglish.Values['Yes'] := 'Yes';
  GTextPortuguese.Values['Yes'] := 'Sim';
  GTextSpanish.Values['Yes'] := 'Si';
  GTextFrench.Values['Yes'] := 'Oui';
  GTextGerman.Values['Yes'] := 'Ja';
  GTextItalian.Values['Yes'] := 'Si';
  GTextPolish.Values['Yes'] := 'Tak';
  GTextRomanian.Values['Yes'] := 'Da';
  GTextHungarian.Values['Yes'] := 'Igen';
  GTextCzech.Values['Yes'] := 'Ano';

  GTextEnglish.Values['No'] := 'No';
  GTextPortuguese.Values['No'] := 'N'#227'o';
  GTextSpanish.Values['No'] := 'No';
  GTextFrench.Values['No'] := 'Non';
  GTextGerman.Values['No'] := 'Nein';
  GTextItalian.Values['No'] := 'No';
  GTextPolish.Values['No'] := 'Nie';
  GTextRomanian.Values['No'] := 'Nu';
  GTextHungarian.Values['No'] := 'Nem';
  GTextCzech.Values['No'] := 'Ne';

  GTextEnglish.Values['OK'] := 'OK';
  GTextPortuguese.Values['OK'] := 'OK';
  GTextSpanish.Values['OK'] := 'OK';
  GTextFrench.Values['OK'] := 'OK';
  GTextGerman.Values['OK'] := 'OK';
  GTextItalian.Values['OK'] := 'OK';
  GTextPolish.Values['OK'] := 'OK';
  GTextRomanian.Values['OK'] := 'OK';
  GTextHungarian.Values['OK'] := 'OK';
  GTextCzech.Values['OK'] := 'OK';

  GTextEnglish.Values['Close'] := 'Close';
  GTextPolish.Values['Close'] := 'Zamknij';
  GTextRomanian.Values['Close'] := 'Inchide';
  GTextHungarian.Values['Close'] := 'Bezar';
  GTextCzech.Values['Close'] := 'Zavrit';

  GTextEnglish.Values['Confirmation'] := 'Confirmation';
  GTextPortuguese.Values['Confirmation'] := 'Confirma'#231#227'o';
  GTextSpanish.Values['Confirmation'] := 'Confirmacion';
  GTextFrench.Values['Confirmation'] := 'Confirmation';
  GTextGerman.Values['Confirmation'] := 'Bestaetigung';
  GTextItalian.Values['Confirmation'] := 'Conferma';
  GTextPolish.Values['Confirmation'] := 'Potwierdzenie';
  GTextRomanian.Values['Confirmation'] := 'Confirmare';
  GTextHungarian.Values['Confirmation'] := 'Megerosites';
  GTextCzech.Values['Confirmation'] := 'Potvrzeni';

  GTextEnglish.Values['Open file from parts ?'] := 'Open file from parts ?';
  GTextPortuguese.Values['Open file from parts ?'] := 'Abrir arquivo pelas partes ?';
  GTextSpanish.Values['Open file from parts ?'] := 'Abrir archivo por partes ?';
  GTextFrench.Values['Open file from parts ?'] := 'Ouvrir le fichier en parties ?';
  GTextGerman.Values['Open file from parts ?'] := 'Datei aus Teilen oeffnen ?';
  GTextItalian.Values['Open file from parts ?'] := 'Aprire file dalle parti ?';
  GTextPolish.Values['Open file from parts ?'] := 'Otworzyc plik z czesci ?';
  GTextRomanian.Values['Open file from parts ?'] := 'Deschide fisierul din parti ?';
  GTextHungarian.Values['Open file from parts ?'] := 'Megnyitod a fajlt reszekbol ?';
  GTextCzech.Values['Open file from parts ?'] := 'Otevrit soubor z casti ?';

  GTextEnglish.Values['Exporting'] := 'Exporting';
  GTextPortuguese.Values['Exporting'] := 'Exportando';
  GTextSpanish.Values['Exporting'] := 'Exportando';
  GTextFrench.Values['Exporting'] := 'Exportation';
  GTextGerman.Values['Exporting'] := 'Exportieren';
  GTextItalian.Values['Exporting'] := 'Esportazione';
  GTextPolish.Values['Exporting'] := 'Eksportowanie';
  GTextRomanian.Values['Exporting'] := 'Exportare';
  GTextHungarian.Values['Exporting'] := 'Exportalas';
  GTextCzech.Values['Exporting'] := 'Export';

  GTextEnglish.Values['Writing'] := 'Writing';
  GTextPortuguese.Values['Writing'] := 'Gravando';
  GTextSpanish.Values['Writing'] := 'Escribiendo';
  GTextFrench.Values['Writing'] := 'Ecriture';
  GTextGerman.Values['Writing'] := 'Schreiben';
  GTextItalian.Values['Writing'] := 'Scrittura';
  GTextPolish.Values['Writing'] := 'Zapisywanie';
  GTextRomanian.Values['Writing'] := 'Scriere';
  GTextHungarian.Values['Writing'] := 'Iras';
  GTextCzech.Values['Writing'] := 'Zapis';

  GTextEnglish.Values['Preparing editing'] := 'Preparing editing';
  GTextPortuguese.Values['Preparing editing'] := 'Preparando edi'#231#227'o';
  GTextSpanish.Values['Preparing editing'] := 'Preparando edicion';
  GTextFrench.Values['Preparing editing'] := 'Preparation de l''edition';
  GTextGerman.Values['Preparing editing'] := 'Bearbeitung vorbereiten';
  GTextItalian.Values['Preparing editing'] := 'Preparazione modifica';
  GTextPolish.Values['Preparing editing'] := 'Przygotowanie edycji';
  GTextRomanian.Values['Preparing editing'] := 'Pregatire editare';
  GTextHungarian.Values['Preparing editing'] := 'Szerkesztes elokeszitese';
  GTextCzech.Values['Preparing editing'] := 'Priprava uprav';

  GTextEnglish.Values['Details'] := 'Details';
  GTextPortuguese.Values['Details'] := 'Detalhes';
  GTextSpanish.Values['Details'] := 'Detalles';
  GTextFrench.Values['Details'] := 'Details';
  GTextGerman.Values['Details'] := 'Details';
  GTextItalian.Values['Details'] := 'Dettagli';
  GTextPolish.Values['Details'] := 'Szczegoly';
  GTextRomanian.Values['Details'] := 'Detalii';
  GTextHungarian.Values['Details'] := 'Reszletek';
  GTextCzech.Values['Details'] := 'Detaily';

  { File details popup (status bar panel / loaded session) }
  GTextEnglish.Values['File details'] := 'File details';
  GTextPortuguese.Values['File details'] := 'Detalhes do arquivo';
  GTextSpanish.Values['File details'] := 'Detalles del archivo';
  GTextFrench.Values['File details'] := 'Details du fichier';
  GTextGerman.Values['File details'] := 'Dateidetails';
  GTextItalian.Values['File details'] := 'Dettagli file';
  GTextPolish.Values['File details'] := 'Szczegoly pliku';
  GTextRomanian.Values['File details'] := 'Detalii fisier';
  GTextHungarian.Values['File details'] := 'Fajl reszletei';
  GTextCzech.Values['File details'] := 'Podrobnosti souboru';
  GTextPortuguesePT.Values['File details'] := 'Detalhes do ficheiro';

  GTextEnglish.Values['Size on disk:'] := 'Size on disk:';
  GTextPortuguese.Values['Size on disk:'] := 'Tamanho no disco:';
  GTextSpanish.Values['Size on disk:'] := 'Tama'#241'o en disco:';
  GTextFrench.Values['Size on disk:'] := 'Taille sur disque:';
  GTextGerman.Values['Size on disk:'] := 'Grosse auf Datentrager:';
  GTextItalian.Values['Size on disk:'] := 'Dimensione su disco:';
  GTextPolish.Values['Size on disk:'] := 'Rozmiar na dysku:';
  GTextRomanian.Values['Size on disk:'] := 'Dimensiune pe disc:';
  GTextHungarian.Values['Size on disk:'] := 'Meret a lemezen:';
  GTextCzech.Values['Size on disk:'] := 'Velikost na disku:';
  GTextPortuguesePT.Values['Size on disk:'] := 'Tamanho em disco:';

  GTextEnglish.Values['bytes'] := 'bytes';
  GTextPortuguese.Values['bytes'] := 'bytes';
  GTextSpanish.Values['bytes'] := 'bytes';
  GTextFrench.Values['bytes'] := 'octets';
  GTextGerman.Values['bytes'] := 'Bytes';
  GTextItalian.Values['bytes'] := 'byte';
  GTextPolish.Values['bytes'] := 'bajtow';
  GTextRomanian.Values['bytes'] := 'octeti';
  GTextHungarian.Values['bytes'] := 'bajt';
  GTextCzech.Values['bytes'] := 'bajtu';
  GTextPortuguesePT.Values['bytes'] := 'bytes';

  GTextEnglish.Values['Modified:'] := 'Modified:';
  GTextPortuguese.Values['Modified:'] := 'Modificado:';
  GTextSpanish.Values['Modified:'] := 'Modificado:';
  GTextFrench.Values['Modified:'] := 'Modifi'#233':';
  GTextGerman.Values['Modified:'] := 'Ge'#228'ndert:';
  GTextItalian.Values['Modified:'] := 'Modificato:';
  GTextPolish.Values['Modified:'] := 'Zmodyfikowano:';
  GTextRomanian.Values['Modified:'] := 'Modificat:';
  GTextHungarian.Values['Modified:'] := 'Modositva:';
  GTextCzech.Values['Modified:'] := 'Zmeneno:';
  GTextPortuguesePT.Values['Modified:'] := 'Modificado:';

  GTextEnglish.Values['Last accessed:'] := 'Last accessed:';
  GTextPortuguese.Values['Last accessed:'] := 'Ultimo acesso:';
  GTextSpanish.Values['Last accessed:'] := 'Ultimo acceso:';
  GTextFrench.Values['Last accessed:'] := 'Dernier acces:';
  GTextGerman.Values['Last accessed:'] := 'Letzter Zugriff:';
  GTextItalian.Values['Last accessed:'] := 'Ultimo accesso:';
  GTextPolish.Values['Last accessed:'] := 'Ostatni dostep:';
  GTextRomanian.Values['Last accessed:'] := 'Ultima accesare:';
  GTextHungarian.Values['Last accessed:'] := 'Utolso hozzaferes:';
  GTextCzech.Values['Last accessed:'] := 'Posledni pristup:';
  GTextPortuguesePT.Values['Last accessed:'] := 'Ultimo acesso:';

  GTextEnglish.Values['Detected encoding (file):'] := 'Detected encoding (file):';
  GTextPortuguese.Values['Detected encoding (file):'] := 'Codificacao detectada (arquivo):';
  GTextSpanish.Values['Detected encoding (file):'] := 'Codificacion detectada (archivo):';
  GTextFrench.Values['Detected encoding (file):'] := 'Encodage detecte (fichier):';
  GTextGerman.Values['Detected encoding (file):'] := 'Erkannte Kodierung (Datei):';
  GTextItalian.Values['Detected encoding (file):'] := 'Codifica rilevata (file):';
  GTextPolish.Values['Detected encoding (file):'] := 'Wykryte kodowanie (plik):';
  GTextRomanian.Values['Detected encoding (file):'] := 'Codare detectata (fisier):';
  GTextHungarian.Values['Detected encoding (file):'] := 'Felismert kodolas (fajl):';
  GTextCzech.Values['Detected encoding (file):'] := 'Detekovane kodovani (soubor):';
  GTextPortuguesePT.Values['Detected encoding (file):'] := 'Codificacao detetada (ficheiro):';

  GTextEnglish.Values['View encoding (list):'] := 'View encoding (list):';
  GTextPortuguese.Values['View encoding (list):'] := 'Codificacao da visualizacao (lista):';
  GTextSpanish.Values['View encoding (list):'] := 'Codificacion de vista (lista):';
  GTextFrench.Values['View encoding (list):'] := 'Encodage d''affichage (liste):';
  GTextGerman.Values['View encoding (list):'] := 'Anzeige-Kodierung (Liste):';
  GTextItalian.Values['View encoding (list):'] := 'Codifica vista (lista):';
  GTextPolish.Values['View encoding (list):'] := 'Kodowanie widoku (lista):';
  GTextRomanian.Values['View encoding (list):'] := 'Codare afisare (lista):';
  GTextHungarian.Values['View encoding (list):'] := 'Nezet kodolas (lista):';
  GTextCzech.Values['View encoding (list):'] := 'Kodovani zobrazeni (seznam):';
  GTextPortuguesePT.Values['View encoding (list):'] := 'Codificacao da vista (lista):';

  GTextEnglish.Values['Read-only session:'] := 'Read-only session:';
  GTextPortuguese.Values['Read-only session:'] := 'Sessao somente leitura:';
  GTextSpanish.Values['Read-only session:'] := 'Sesion solo lectura:';
  GTextFrench.Values['Read-only session:'] := 'Session lecture seule:';
  GTextGerman.Values['Read-only session:'] := 'Nur-Lese-Sitzung:';
  GTextItalian.Values['Read-only session:'] := 'Sessione sola lettura:';
  GTextPolish.Values['Read-only session:'] := 'Sesja tylko do odczytu:';
  GTextRomanian.Values['Read-only session:'] := 'Sesiune numai citire:';
  GTextHungarian.Values['Read-only session:'] := 'Csak olvashato munkamenet:';
  GTextCzech.Values['Read-only session:'] := 'Relace pouze pro cteni:';
  GTextPortuguesePT.Values['Read-only session:'] := 'Sessao so de leitura:';

  GTextEnglish.Values['Word wrap (visual):'] := 'Word wrap (visual):';
  GTextPortuguese.Values['Word wrap (visual):'] := 'Quebra de linha (visual):';
  GTextSpanish.Values['Word wrap (visual):'] := 'Ajuste de linea (visual):';
  GTextFrench.Values['Word wrap (visual):'] := 'Retour a la ligne (visuel):';
  GTextGerman.Values['Word wrap (visual):'] := 'Zeilenumbruch (visuell):';
  GTextItalian.Values['Word wrap (visual):'] := 'A capo automatico (visivo):';
  GTextPolish.Values['Word wrap (visual):'] := 'Zawijanie wierszy (wizualne):';
  GTextRomanian.Values['Word wrap (visual):'] := 'Incadrare text (vizual):';
  GTextHungarian.Values['Word wrap (visual):'] := 'Sortores (vizualis):';
  GTextCzech.Values['Word wrap (visual):'] := 'Zalamovani textu (vizualne):';
  GTextPortuguesePT.Values['Word wrap (visual):'] := 'Quebra de linha (visual):';

  GTextEnglish.Values['Tail / follow mode:'] := 'Tail / follow mode:';
  GTextPortuguese.Values['Tail / follow mode:'] := 'Modo tail / seguir:';
  GTextSpanish.Values['Tail / follow mode:'] := 'Modo tail / seguir:';
  GTextFrench.Values['Tail / follow mode:'] := 'Mode tail / suivi:';
  GTextGerman.Values['Tail / follow mode:'] := 'Tail-/Folgemodus:';
  GTextItalian.Values['Tail / follow mode:'] := 'Modalita tail / segui:';
  GTextPolish.Values['Tail / follow mode:'] := 'Tryb tail / sledzenia:';
  GTextRomanian.Values['Tail / follow mode:'] := 'Mod tail / urmarire:';
  GTextHungarian.Values['Tail / follow mode:'] := 'Tail / kovetes mod:';
  GTextCzech.Values['Tail / follow mode:'] := 'Rezim tail / sledovani:';
  GTextPortuguesePT.Values['Tail / follow mode:'] := 'Modo tail / seguir:';

  GTextEnglish.Values['Line-segmented mode:'] := 'Line-segmented mode:';
  GTextPortuguese.Values['Line-segmented mode:'] := 'Modo segmentado por linha:';
  GTextSpanish.Values['Line-segmented mode:'] := 'Modo segmentado por lineas:';
  GTextFrench.Values['Line-segmented mode:'] := 'Mode segmente par lignes:';
  GTextGerman.Values['Line-segmented mode:'] := 'Zeilensegmentierter Modus:';
  GTextItalian.Values['Line-segmented mode:'] := 'Modalita segmentata per righe:';
  GTextPolish.Values['Line-segmented mode:'] := 'Tryb podzialu na linie:';
  GTextRomanian.Values['Line-segmented mode:'] := 'Mod segmentat pe linii:';
  GTextHungarian.Values['Line-segmented mode:'] := 'Sor szegmentalt mod:';
  GTextCzech.Values['Line-segmented mode:'] := 'Rezim segmentace radku:';
  GTextPortuguesePT.Values['Line-segmented mode:'] := 'Modo segmentado por linha:';

  GTextEnglish.Values['Filter / Grep active:'] := 'Filter / Grep active:';
  GTextPortuguese.Values['Filter / Grep active:'] := 'Filtro / Grep ativo:';
  GTextSpanish.Values['Filter / Grep active:'] := 'Filtro / Grep activo:';
  GTextFrench.Values['Filter / Grep active:'] := 'Filtre / Grep actif:';
  GTextGerman.Values['Filter / Grep active:'] := 'Filter / Grep aktiv:';
  GTextItalian.Values['Filter / Grep active:'] := 'Filtro / Grep attivo:';
  GTextPolish.Values['Filter / Grep active:'] := 'Filtr / Grep aktywny:';
  GTextRomanian.Values['Filter / Grep active:'] := 'Filtru / Grep activ:';
  GTextHungarian.Values['Filter / Grep active:'] := 'Szuro / Grep aktiv:';
  GTextCzech.Values['Filter / Grep active:'] := 'Filtr / Grep aktivni:';
  GTextPortuguesePT.Values['Filter / Grep active:'] := 'Filtro / Grep ativo:';

  GTextEnglish.Values['List mode: list view'] := 'List mode: standard list view';
  GTextPortuguese.Values['List mode: list view'] := 'Modo de lista: lista padrao';
  GTextSpanish.Values['List mode: list view'] := 'Modo de lista: vista de lista estandar';
  GTextFrench.Values['List mode: list view'] := 'Mode liste: liste standard';
  GTextGerman.Values['List mode: list view'] := 'Listenmodus: Standardliste';
  GTextItalian.Values['List mode: list view'] := 'Modalita elenco: vista elenco standard';
  GTextPolish.Values['List mode: list view'] := 'Tryb listy: standardowa lista';
  GTextRomanian.Values['List mode: list view'] := 'Mod lista: vizualizare standard';
  GTextHungarian.Values['List mode: list view'] := 'Listanezet: szabvanyos lista';
  GTextCzech.Values['List mode: list view'] := 'Rezim seznamu: standardni seznam';
  GTextPortuguesePT.Values['List mode: list view'] := 'Modo de lista: vista de lista padrao';

  GTextEnglish.Values['List mode: checkbox list'] := 'List mode: checkbox list';
  GTextPortuguese.Values['List mode: checkbox list'] := 'Modo de lista: lista com caixas de selecao';
  GTextSpanish.Values['List mode: checkbox list'] := 'Modo de lista: lista con casillas';
  GTextFrench.Values['List mode: checkbox list'] := 'Mode liste: cases a cocher';
  GTextGerman.Values['List mode: checkbox list'] := 'Listenmodus: Kontrollkastchenliste';
  GTextItalian.Values['List mode: checkbox list'] := 'Modalita elenco: elenco con caselle';
  GTextPolish.Values['List mode: checkbox list'] := 'Tryb listy: lista z polami wyboru';
  GTextRomanian.Values['List mode: checkbox list'] := 'Mod lista: casete bifare';
  GTextHungarian.Values['List mode: checkbox list'] := 'Listanezet: jelolonegyzet lista';
  GTextCzech.Values['List mode: checkbox list'] := 'Rezim seznamu: seznam se zaskrtavatky';
  GTextPortuguesePT.Values['List mode: checkbox list'] := 'Modo de lista: lista com caixas de verificacao';

  GTextEnglish.Values['Max indexed offset:'] := 'Max indexed offset (bytes):';
  GTextPortuguese.Values['Max indexed offset:'] := 'Deslocamento max. indexado (bytes):';
  GTextSpanish.Values['Max indexed offset:'] := 'Desplazamiento max. indexado (bytes):';
  GTextFrench.Values['Max indexed offset:'] := 'Decalage max. indexe (octets):';
  GTextGerman.Values['Max indexed offset:'] := 'Max. indizierter Offset (Bytes):';
  GTextItalian.Values['Max indexed offset:'] := 'Offset massimo indicizzato (byte):';
  GTextPolish.Values['Max indexed offset:'] := 'Maks. indeksowany offset (bajty):';
  GTextRomanian.Values['Max indexed offset:'] := 'Offset max. indexat (octeti):';
  GTextHungarian.Values['Max indexed offset:'] := 'Max. indexelt eltolodas (bajt):';
  GTextCzech.Values['Max indexed offset:'] := 'Max. indexovany posun (bajty):';
  GTextPortuguesePT.Values['Max indexed offset:'] := 'Deslocamento max. indexado (bytes):';

  GTextEnglish.Values['Read summary (status):'] := 'Read summary (status bar):';
  GTextPortuguese.Values['Read summary (status):'] := 'Resumo da leitura (barra de status):';
  GTextSpanish.Values['Read summary (status):'] := 'Resumen de lectura (barra de estado):';
  GTextFrench.Values['Read summary (status):'] := 'Resume de lecture (barre d''etat):';
  GTextGerman.Values['Read summary (status):'] := 'Lesezusammenfassung (Statusleiste):';
  GTextItalian.Values['Read summary (status):'] := 'Riepilogo lettura (barra di stato):';
  GTextPolish.Values['Read summary (status):'] := 'Podsumowanie odczytu (pasek statusu):';
  GTextRomanian.Values['Read summary (status):'] := 'Rezumat citire (bara de stare):';
  GTextHungarian.Values['Read summary (status):'] := 'Olvasasi osszefoglalo (allapotsor):';
  GTextCzech.Values['Read summary (status):'] := 'Souhrn cteni (stavovy radek):';
  GTextPortuguesePT.Values['Read summary (status):'] := 'Resumo da leitura (barra de estado):';

  GTextEnglish.Values['Text copied to clipboard!'] := 'Text copied to clipboard!';
  GTextPortuguese.Values['Text copied to clipboard!'] := 'Texto copiado para a area de transferencia!';
  GTextSpanish.Values['Text copied to clipboard!'] := 'Texto copiado al portapapeles!';
  GTextFrench.Values['Text copied to clipboard!'] := 'Texte copie dans le presse-papiers!';
  GTextGerman.Values['Text copied to clipboard!'] := 'Text in die Zwischenablage kopiert!';
  GTextItalian.Values['Text copied to clipboard!'] := 'Testo copiato negli Appunti!';
  GTextPolish.Values['Text copied to clipboard!'] := 'Tekst skopiowany do schowka!';
  GTextRomanian.Values['Text copied to clipboard!'] := 'Text copiat in clipboard!';
  GTextHungarian.Values['Text copied to clipboard!'] := 'Szoveg a vagolapra masolva!';
  GTextCzech.Values['Text copied to clipboard!'] := 'Text zkopirovan do schranky!';
  GTextPortuguesePT.Values['Text copied to clipboard!'] := 'Texto copiado para a area de transferencia!';

  { F1 help memo — menu bar hints (View / Options mnemonics) }
  GTextEnglish.Values['Menu bar: Underlined letter = Alt+letter (example: Alt+F, E, V, O for File, Edit, View, Options).'] :=
    'Menu bar: Underlined letter = Alt+letter (example: Alt+F, E, V, O for File, Edit, View, Options).';
  GTextPortuguese.Values['Menu bar: Underlined letter = Alt+letter (example: Alt+F, E, V, O for File, Edit, View, Options).'] :=
    'Barra de menus: letra sublinhada = Alt+letra (ex.: Alt+F, E, V, O para Arquivo, Editar, Visualizar, Op'#231#245'es).';
  GTextSpanish.Values['Menu bar: Underlined letter = Alt+letter (example: Alt+F, E, V, O for File, Edit, View, Options).'] :=
    'Barra de men'#250's: letra subrayada = Alt+letra (p. ej., Alt+F, E, V, O para Archivo, Editar, Ver, Opciones).';
  GTextFrench.Values['Menu bar: Underlined letter = Alt+letter (example: Alt+F, E, V, O for File, Edit, View, Options).'] :=
    'Barre de menus : lettre soulign'#233'e = Alt+lettre (ex. : Alt+F, E, V, O pour Fichier, '#201'dition, Affichage, Options).';
  GTextGerman.Values['Menu bar: Underlined letter = Alt+letter (example: Alt+F, E, V, O for File, Edit, View, Options).'] :=
    'Men'#252'leiste: Unterstrichener Buchstabe = Alt+Buchstabe (z. B. Alt+F, E, V, O f'#252'r Datei, Bearbeiten, Ansicht, Optionen).';
  GTextItalian.Values['Menu bar: Underlined letter = Alt+letter (example: Alt+F, E, V, O for File, Edit, View, Options).'] :=
    'Barra dei menu: lettera sottolineata = Alt+lettera (es. Alt+F, E, V, O per File, Modifica, Visualizza, Opzioni).';
  GTextPolish.Values['Menu bar: Underlined letter = Alt+letter (example: Alt+F, E, V, O for File, Edit, View, Options).'] :=
    'Pasek menu: podkreslona litera = Alt+litera (np. Alt+F, E, V, O dla Plik, Edycja, Widok, Opcje).';
  GTextPortuguesePT.Values['Menu bar: Underlined letter = Alt+letter (example: Alt+F, E, V, O for File, Edit, View, Options).'] :=
    'Barra de menus: letra sublinhada = Alt+letra (ex.: Alt+F, E, V, O para Ficheiro, Editar, Ver, Op'#231#245'es).';
  GTextRomanian.Values['Menu bar: Underlined letter = Alt+letter (example: Alt+F, E, V, O for File, Edit, View, Options).'] :=
    'Bara de meniu: litera subliniata = Alt+litera (ex.: Alt+F, E, V, O pentru Fi'#537'ier, Editare, Vizualizare, Op'#539'iuni).';
  GTextHungarian.Values['Menu bar: Underlined letter = Alt+letter (example: Alt+F, E, V, O for File, Edit, View, Options).'] :=
    'Men'#252'sor: al'#225'h'#250'zott bet'#369' = Alt+bet'#369' (pl. Alt+F, E, V, O: F'#225'jl, Szerkeszt'#233's, N'#233'zet, Be'#225'll'#237't'#225'sok).';
  GTextCzech.Values['Menu bar: Underlined letter = Alt+letter (example: Alt+F, E, V, O for File, Edit, View, Options).'] :=
    'Lista nabidky: podtr'#382'en'#233' p'#237'smeno = Alt+p'#237'smeno (nap'#345'. Alt+F, E, V, O pro Soubor, '#218'pravy, Zobrazen'#237', Moznosti).';

  GTextEnglish.Values['Ctrl+ shortcuts are shown to the right of each menu command.'] :=
    'Ctrl+ shortcuts are shown to the right of each menu command.';
  GTextPortuguese.Values['Ctrl+ shortcuts are shown to the right of each menu command.'] :=
    'Atalhos Ctrl+ aparecem '#224' direita em cada comando do menu.';
  GTextSpanish.Values['Ctrl+ shortcuts are shown to the right of each menu command.'] :=
    'Los atajos Ctrl+ se muestran a la derecha de cada comando del men'#250'.';
  GTextFrench.Values['Ctrl+ shortcuts are shown to the right of each menu command.'] :=
    'Les raccourcis Ctrl+ sont affich'#233's '#224' droite de chaque commande du menu.';
  GTextGerman.Values['Ctrl+ shortcuts are shown to the right of each menu command.'] :=
    'Strg+-Tastenk'#252'rzel stehen rechts neben jedem Men'#252'befehl.';
  GTextItalian.Values['Ctrl+ shortcuts are shown to the right of each menu command.'] :=
    'Le scorciatoie Ctrl+ sono mostrate a destra di ogni comando di menu.';
  GTextPolish.Values['Ctrl+ shortcuts are shown to the right of each menu command.'] :=
    'Skroty Ctrl+ s'#261' widoczne po prawej stronie kazdej pozycji menu.';
  GTextPortuguesePT.Values['Ctrl+ shortcuts are shown to the right of each menu command.'] :=
    'Os atalhos Ctrl+ aparecem '#224' direita de cada comando do menu.';
  GTextRomanian.Values['Ctrl+ shortcuts are shown to the right of each menu command.'] :=
    'Scurtaturile Ctrl+ apar '#238'n dreapta fiecarei comenzi din meniu.';
  GTextHungarian.Values['Ctrl+ shortcuts are shown to the right of each menu command.'] :=
    'A Ctrl+ gyorsbillenty'#369'k a menuparancsok jobb oldal'#225'n jelennek meg.';
  GTextCzech.Values['Ctrl+ shortcuts are shown to the right of each menu command.'] :=
    'Zkratky Ctrl+ jsou vpravo u kazdeho prikazu nabidky.';

  GTextEnglish.Values['Export Help Content'] := 'Export Help Content';
  GTextPortuguese.Values['Export Help Content'] := 'Exportar conte'#250'do da ajuda';
  GTextSpanish.Values['Export Help Content'] := 'Exportar contenido de la ayuda';
  GTextFrench.Values['Export Help Content'] := 'Exporter le contenu de l''aide';
  GTextGerman.Values['Export Help Content'] := 'Hilfeinhalt exportieren';
  GTextItalian.Values['Export Help Content'] := 'Esporta contenuto guida';
  GTextPolish.Values['Export Help Content'] := 'Eksportuj zawartosc pomocy';
  GTextPortuguesePT.Values['Export Help Content'] := 'Exportar conte'#250'do da ajuda';
  GTextRomanian.Values['Export Help Content'] := 'Exporta continutul ajutorului';
  GTextHungarian.Values['Export Help Content'] := 'Sugo tartalom exportalasa';
  GTextCzech.Values['Export Help Content'] := 'Exportovat obsah napovedy';

  { View menu — list font zoom (same step as Ctrl+wheel on list) }
  GTextEnglish.Values['Zoom &in (list)'] := 'Zoom &in (list)';
  GTextPortuguese.Values['Zoom &in (list)'] := '&Aumentar zoom da lista';
  GTextSpanish.Values['Zoom &in (list)'] := '&Aumentar zoom de la lista';
  GTextFrench.Values['Zoom &in (list)'] := 'Zoom &avant (liste)';
  GTextGerman.Values['Zoom &in (list)'] := '&Vergr'#246#223'ern (Liste)';
  GTextItalian.Values['Zoom &in (list)'] := 'Zoom &avanti (lista)';
  GTextPolish.Values['Zoom &in (list)'] := 'Powi'#281'ksz zoom listy';
  GTextPortuguesePT.Values['Zoom &in (list)'] := '&Aumentar zoom da lista';
  GTextRomanian.Values['Zoom &in (list)'] := 'M'#259're'#537'te zoom list'#259;
  GTextHungarian.Values['Zoom &in (list)'] := 'Nagy'#237't'#225's (lista)';
  GTextCzech.Values['Zoom &in (list)'] := '&Zv'#283't'#353'it (seznam)';

  GTextEnglish.Values['Zoom o&ut (list)'] := 'Zoom o&ut (list)';
  GTextPortuguese.Values['Zoom o&ut (list)'] := 'Diminuir z&oom da lista';
  GTextSpanish.Values['Zoom o&ut (list)'] := 'Reducir z&oom de la lista';
  GTextFrench.Values['Zoom o&ut (list)'] := 'Zoom a&rri'#232're (liste)';
  GTextGerman.Values['Zoom o&ut (list)'] := 'Ver&kleinern (Liste)';
  GTextItalian.Values['Zoom o&ut (list)'] := 'Zoom i&ndietro (lista)';
  GTextPolish.Values['Zoom o&ut (list)'] := 'Pomniejsz zoom listy';
  GTextPortuguesePT.Values['Zoom o&ut (list)'] := 'Diminuir z&oom da lista';
  GTextRomanian.Values['Zoom o&ut (list)'] := 'Mic'#351'oreaz'#259' zoom list'#259;
  GTextHungarian.Values['Zoom o&ut (list)'] := 'Kicsiny'#237't'#233's (lista)';
  GTextCzech.Values['Zoom o&ut (list)'] := 'Zmen'#353'it (seznam)';

  { F1 help — View menu list zoom shortcuts }
  GTextEnglish.Values['  Ctrl+Num+ .......... Zoom in list font (View menu)'] :=
    '  Ctrl+Num+ .......... Zoom in list font (View menu)';
  GTextPortuguese.Values['  Ctrl+Num+ .......... Zoom in list font (View menu)'] :=
    '  Ctrl+Num+ .......... Aumentar zoom da fonte da lista (menu Visualizar)';
  GTextSpanish.Values['  Ctrl+Num+ .......... Zoom in list font (View menu)'] :=
    '  Ctrl+Num+ .......... Aumentar zoom de fuente de lista (menu Ver)';
  GTextFrench.Values['  Ctrl+Num+ .......... Zoom in list font (View menu)'] :=
    '  Ctrl+Num+ .......... Zoom avant police de liste (menu Affichage)';
  GTextGerman.Values['  Ctrl+Num+ .......... Zoom in list font (View menu)'] :=
    '  Ctrl+Num+ .......... Listen-Schrift vergr'#246#223'ern (Ansicht-Men'#252')';
  GTextItalian.Values['  Ctrl+Num+ .......... Zoom in list font (View menu)'] :=
    '  Ctrl+Num+ .......... Ingrandisci carattere lista (menu Visualizza)';
  GTextPolish.Values['  Ctrl+Num+ .......... Zoom in list font (View menu)'] :=
    '  Ctrl+Num+ .......... Powi'#281'ksz czcionk'#281' listy (menu Widok)';
  GTextPortuguesePT.Values['  Ctrl+Num+ .......... Zoom in list font (View menu)'] :=
    '  Ctrl+Num+ .......... Aumentar zoom do tipo de letra da lista (menu Ver)';
  GTextRomanian.Values['  Ctrl+Num+ .......... Zoom in list font (View menu)'] :=
    '  Ctrl+Num+ .......... M'#259're'#537'te fontul listei (meniu Vizualizare)';
  GTextHungarian.Values['  Ctrl+Num+ .......... Zoom in list font (View menu)'] :=
    '  Ctrl+Num+ .......... Lista bet'#369'm'#233'ret n'#246'vel'#233'se (N'#233'zet men'#252')';
  GTextCzech.Values['  Ctrl+Num+ .......... Zoom in list font (View menu)'] :=
    '  Ctrl+Num+ .......... Zv'#283't'#353'it p'#237'smo seznamu (nab'#237'dka Zobrazen'#237')';

  GTextEnglish.Values['  Ctrl+Num- .......... Zoom out list font (View menu)'] :=
    '  Ctrl+Num- .......... Zoom out list font (View menu)';
  GTextPortuguese.Values['  Ctrl+Num- .......... Zoom out list font (View menu)'] :=
    '  Ctrl+Num- .......... Diminuir zoom da fonte da lista (menu Visualizar)';
  GTextSpanish.Values['  Ctrl+Num- .......... Zoom out list font (View menu)'] :=
    '  Ctrl+Num- .......... Reducir zoom de fuente de lista (menu Ver)';
  GTextFrench.Values['  Ctrl+Num- .......... Zoom out list font (View menu)'] :=
    '  Ctrl+Num- .......... Zoom arri'#232're police de liste (menu Affichage)';
  GTextGerman.Values['  Ctrl+Num- .......... Zoom out list font (View menu)'] :=
    '  Ctrl+Num- .......... Listen-Schrift verkleinern (Ansicht-Men'#252')';
  GTextItalian.Values['  Ctrl+Num- .......... Zoom out list font (View menu)'] :=
    '  Ctrl+Num- .......... Riduci carattere lista (menu Visualizza)';
  GTextPolish.Values['  Ctrl+Num- .......... Zoom out list font (View menu)'] :=
    '  Ctrl+Num- .......... Pomniejsz czcionk'#281' listy (menu Widok)';
  GTextPortuguesePT.Values['  Ctrl+Num- .......... Zoom out list font (View menu)'] :=
    '  Ctrl+Num- .......... Diminuir zoom do tipo de letra da lista (menu Ver)';
  GTextRomanian.Values['  Ctrl+Num- .......... Zoom out list font (View menu)'] :=
    '  Ctrl+Num- .......... Mic'#351'oreaz'#259' fontul listei (meniu Vizualizare)';
  GTextHungarian.Values['  Ctrl+Num- .......... Zoom out list font (View menu)'] :=
    '  Ctrl+Num- .......... Lista bet'#369'm'#233'ret cs'#246'kkent'#233'se (N'#233'zet men'#252')';
  GTextCzech.Values['  Ctrl+Num- .......... Zoom out list font (View menu)'] :=
    '  Ctrl+Num- .......... Zmen'#353'it p'#237'smo seznamu (nab'#237'dka Zobrazen'#237')';

  GTextEnglish.Values['Allow'] := 'Allow';
  GTextPortuguese.Values['Allow'] := 'Permitir';
  GTextSpanish.Values['Allow'] := 'Permitir';
  GTextFrench.Values['Allow'] := 'Autoriser';
  GTextGerman.Values['Allow'] := 'Erlauben';
  GTextItalian.Values['Allow'] := 'Consenti';
  GTextPolish.Values['Allow'] := 'Zezwol';
  GTextRomanian.Values['Allow'] := 'Permite';
  GTextHungarian.Values['Allow'] := 'Engedelyez';
  GTextCzech.Values['Allow'] := 'Povolit';

  GTextEnglish.Values['animation'] := 'animation';
  GTextPortuguese.Values['animation'] := 'anima'#231#227'o';
  GTextSpanish.Values['animation'] := 'animacion';
  GTextFrench.Values['animation'] := 'animation';
  GTextGerman.Values['animation'] := 'Animation';
  GTextItalian.Values['animation'] := 'animazione';
  GTextPolish.Values['animation'] := 'animacje';
  GTextRomanian.Values['animation'] := 'animatie';
  GTextHungarian.Values['animation'] := 'animacio';
  GTextCzech.Values['animation'] := 'animace';

  GTextEnglish.Values['Custom PPI: '] := 'Custom PPI: ';
  GTextPortuguese.Values['Custom PPI: '] := 'PPI customizado: ';
  GTextSpanish.Values['Custom PPI: '] := 'PPI personalizado: ';
  GTextFrench.Values['Custom PPI: '] := 'PPI personnalise: ';
  GTextGerman.Values['Custom PPI: '] := 'Benutzerdefiniertes PPI: ';
  GTextItalian.Values['Custom PPI: '] := 'PPI personalizzato: ';
  GTextPolish.Values['Custom PPI: '] := 'Niestandardowe PPI: ';
  GTextRomanian.Values['Custom PPI: '] := 'PPI personalizat: ';
  GTextHungarian.Values['Custom PPI: '] := 'Egyedi PPI: ';
  GTextCzech.Values['Custom PPI: '] := 'Vlastni PPI: ';

  GTextEnglish.Values['FastFile - Help & Feature Reference'] := 'FastFile - Help & Feature Reference';
  GTextPortuguese.Values['FastFile - Help & Feature Reference'] := 'FastFile - Ajuda e Refer'#234'ncia de Recursos';
  GTextSpanish.Values['FastFile - Help & Feature Reference'] := 'FastFile - Ayuda y Referencia de Funciones';
  GTextFrench.Values['FastFile - Help & Feature Reference'] := 'FastFile - Aide et Reference des Fonctions';
  GTextGerman.Values['FastFile - Help & Feature Reference'] := 'FastFile - Hilfe und Funktionsreferenz';
  GTextItalian.Values['FastFile - Help & Feature Reference'] := 'FastFile - Guida e Riferimento Funzionalita';
  GTextPolish.Values['FastFile - Help & Feature Reference'] := 'FastFile - Pomoc i Opis Funkcji';
  GTextRomanian.Values['FastFile - Help & Feature Reference'] := 'FastFile - Ajutor si Referinta Functionalitati';
  GTextHungarian.Values['FastFile - Help & Feature Reference'] := 'FastFile - Segitseg es Funkcio Referencia';
  GTextCzech.Values['FastFile - Help & Feature Reference'] := 'FastFile - Napoveda a Prehled Funkci';

  { AI panel / inter-application session runtime }
  GTextEnglish.Values['AI Panel'] := 'AI Panel';
  GTextPortuguese.Values['AI Panel'] := 'Painel IA';
  GTextSpanish.Values['AI Panel'] := 'Panel IA';
  GTextFrench.Values['AI Panel'] := 'Panneau IA';
  GTextGerman.Values['AI Panel'] := 'KI-Panel';
  GTextItalian.Values['AI Panel'] := 'Pannello IA';
  GTextPolish.Values['AI Panel'] := 'Panel AI';
  GTextPortuguesePT.Values['AI Panel'] := 'Painel IA';
  GTextRomanian.Values['AI Panel'] := 'Panou IA';
  GTextHungarian.Values['AI Panel'] := 'MI panel';
  GTextCzech.Values['AI Panel'] := 'Panel AI';

  GTextEnglish.Values['AI workspace panel.'] := 'AI workspace panel.';
  GTextPortuguese.Values['AI workspace panel.'] := 'Painel de trabalho da IA.';
  GTextSpanish.Values['AI workspace panel.'] := 'Panel de trabajo de IA.';
  GTextFrench.Values['AI workspace panel.'] := 'Panneau de travail IA.';
  GTextGerman.Values['AI workspace panel.'] := 'KI-Arbeitsbereich.';
  GTextItalian.Values['AI workspace panel.'] := 'Pannello di lavoro IA.';
  GTextPolish.Values['AI workspace panel.'] := 'Panel roboczy AI.';
  GTextPortuguesePT.Values['AI workspace panel.'] := 'Painel de trabalho da IA.';
  GTextRomanian.Values['AI workspace panel.'] := 'Panou de lucru IA.';
  GTextHungarian.Values['AI workspace panel.'] := 'MI munkaterulet panel.';
  GTextCzech.Values['AI workspace panel.'] := 'Pracovni panel AI.';

  GTextEnglish.Values['Click the Consumer AI button to start an inter-application session.'] := 'Click the Consumer AI button to start an inter-application session.';
  GTextPortuguese.Values['Click the Consumer AI button to start an inter-application session.'] := 'Clique no bot'#227'o Consumer AI para iniciar uma sess'#227'o interaplica'#231#245'es.';
  GTextSpanish.Values['Click the Consumer AI button to start an inter-application session.'] := 'Haga clic en Consumer AI para iniciar una sesion entre aplicaciones.';
  GTextFrench.Values['Click the Consumer AI button to start an inter-application session.'] := 'Cliquez sur Consumer AI pour demarrer une session inter-applications.';
  GTextGerman.Values['Click the Consumer AI button to start an inter-application session.'] := 'Klicken Sie auf Consumer AI, um eine anwendungsuebergreifende Sitzung zu starten.';
  GTextItalian.Values['Click the Consumer AI button to start an inter-application session.'] := 'Fai clic su Consumer AI per avviare una sessione tra applicazioni.';
  GTextPolish.Values['Click the Consumer AI button to start an inter-application session.'] := 'Kliknij Consumer AI, aby uruchomic sesje miedzy aplikacjami.';
  GTextPortuguesePT.Values['Click the Consumer AI button to start an inter-application session.'] := 'Clique no bot'#227'o Consumer AI para iniciar uma sess'#227'o interaplica'#231#245'es.';
  GTextRomanian.Values['Click the Consumer AI button to start an inter-application session.'] := 'Apasa Consumer AI pentru a porni o sesiune intre aplicatii.';
  GTextHungarian.Values['Click the Consumer AI button to start an inter-application session.'] := 'Kattintson a Consumer AI gombra az alkalmazasok kozotti munkamenethez.';
  GTextCzech.Values['Click the Consumer AI button to start an inter-application session.'] := 'Kliknete na Consumer AI pro spusteni relace mezi aplikacemi.';

  GTextEnglish.Values['Export transcript'] := 'Export transcript';
  GTextPortuguese.Values['Export transcript'] := 'Exportar transcri'#231#227'o';
  GTextSpanish.Values['Export transcript'] := 'Exportar transcripcion';
  GTextFrench.Values['Export transcript'] := 'Exporter la transcription';
  GTextGerman.Values['Export transcript'] := 'Transkript exportieren';
  GTextItalian.Values['Export transcript'] := 'Esporta trascrizione';
  GTextPolish.Values['Export transcript'] := 'Eksportuj transkrypcje';
  GTextPortuguesePT.Values['Export transcript'] := 'Exportar transcri'#231#227'o';
  GTextRomanian.Values['Export transcript'] := 'Exporta transcript';
  GTextHungarian.Values['Export transcript'] := 'Atirat export';
  GTextCzech.Values['Export transcript'] := 'Export prepisu';

  GTextEnglish.Values['Clear transcript'] := 'Clear transcript';
  GTextPortuguese.Values['Clear transcript'] := 'Limpar transcri'#231#227'o';
  GTextSpanish.Values['Clear transcript'] := 'Limpiar transcripcion';
  GTextFrench.Values['Clear transcript'] := 'Effacer la transcription';
  GTextGerman.Values['Clear transcript'] := 'Transkript leeren';
  GTextItalian.Values['Clear transcript'] := 'Cancella trascrizione';
  GTextPolish.Values['Clear transcript'] := 'Wyczysc transkrypcje';
  GTextPortuguesePT.Values['Clear transcript'] := 'Limpar transcri'#231#227'o';
  GTextRomanian.Values['Clear transcript'] := 'Sterge transcript';
  GTextHungarian.Values['Clear transcript'] := 'Atirat torlese';
  GTextCzech.Values['Clear transcript'] := 'Vymazat prepis';

  GTextEnglish.Values['Restart session'] := 'Restart session';
  GTextPortuguese.Values['Restart session'] := 'Reiniciar sess'#227'o';
  GTextSpanish.Values['Restart session'] := 'Reiniciar sesion';
  GTextFrench.Values['Restart session'] := 'Redemarrer la session';
  GTextGerman.Values['Restart session'] := 'Sitzung neu starten';
  GTextItalian.Values['Restart session'] := 'Riavvia sessione';
  GTextPolish.Values['Restart session'] := 'Uruchom sesje ponownie';
  GTextPortuguesePT.Values['Restart session'] := 'Reiniciar sess'#227'o';
  GTextRomanian.Values['Restart session'] := 'Reporneste sesiunea';
  GTextHungarian.Values['Restart session'] := 'Munkamenet ujrainditas';
  GTextCzech.Values['Restart session'] := 'Restart relace';

  GTextEnglish.Values['Disconnected'] := 'Disconnected';
  GTextPortuguese.Values['Disconnected'] := 'Desconectado';
  GTextSpanish.Values['Disconnected'] := 'Desconectado';
  GTextFrench.Values['Disconnected'] := 'Deconnecte';
  GTextGerman.Values['Disconnected'] := 'Getrennt';
  GTextItalian.Values['Disconnected'] := 'Disconnesso';
  GTextPolish.Values['Disconnected'] := 'Rozlaczono';
  GTextPortuguesePT.Values['Disconnected'] := 'Desconectado';
  GTextRomanian.Values['Disconnected'] := 'Deconectat';
  GTextHungarian.Values['Disconnected'] := 'Kapcsolat bontva';
  GTextCzech.Values['Disconnected'] := 'Odpojeno';

  GTextEnglish.Values['Connected'] := 'Connected';
  GTextPortuguese.Values['Connected'] := 'Conectado';
  GTextSpanish.Values['Connected'] := 'Conectado';
  GTextFrench.Values['Connected'] := 'Connecte';
  GTextGerman.Values['Connected'] := 'Verbunden';
  GTextItalian.Values['Connected'] := 'Connesso';
  GTextPolish.Values['Connected'] := 'Polaczono';
  GTextPortuguesePT.Values['Connected'] := 'Conectado';
  GTextRomanian.Values['Connected'] := 'Conectat';
  GTextHungarian.Values['Connected'] := 'Kapcsolodva';
  GTextCzech.Values['Connected'] := 'Pripojeno';

  GTextEnglish.Values['Transcript cleared'] := 'Transcript cleared';
  GTextPortuguese.Values['Transcript cleared'] := 'Transcri'#231#227'o limpa';
  GTextSpanish.Values['Transcript cleared'] := 'Transcripcion limpiada';
  GTextFrench.Values['Transcript cleared'] := 'Transcription effacee';
  GTextGerman.Values['Transcript cleared'] := 'Transkript geleert';
  GTextItalian.Values['Transcript cleared'] := 'Trascrizione pulita';
  GTextPolish.Values['Transcript cleared'] := 'Transkrypcja wyczyszczona';
  GTextPortuguesePT.Values['Transcript cleared'] := 'Transcri'#231#227'o limpa';
  GTextRomanian.Values['Transcript cleared'] := 'Transcript sters';
  GTextHungarian.Values['Transcript cleared'] := 'Atirat torolve';
  GTextCzech.Values['Transcript cleared'] := 'Prepis vymazan';

  GTextEnglish.Values['Nothing to export'] := 'Nothing to export';
  GTextPortuguese.Values['Nothing to export'] := 'Nada para exportar';
  GTextSpanish.Values['Nothing to export'] := 'Nada para exportar';
  GTextFrench.Values['Nothing to export'] := 'Rien a exporter';
  GTextGerman.Values['Nothing to export'] := 'Nichts zu exportieren';
  GTextItalian.Values['Nothing to export'] := 'Niente da esportare';
  GTextPolish.Values['Nothing to export'] := 'Brak danych do eksportu';
  GTextPortuguesePT.Values['Nothing to export'] := 'Nada para exportar';
  GTextRomanian.Values['Nothing to export'] := 'Nimic de exportat';
  GTextHungarian.Values['Nothing to export'] := 'Nincs mit exportalni';
  GTextCzech.Values['Nothing to export'] := 'Neni co exportovat';

  GTextEnglish.Values['Transcript exported to: '] := 'Transcript exported to: ';
  GTextPortuguese.Values['Transcript exported to: '] := 'Transcri'#231#227'o exportada para: ';
  GTextSpanish.Values['Transcript exported to: '] := 'Transcripcion exportada a: ';
  GTextFrench.Values['Transcript exported to: '] := 'Transcription exportee vers: ';
  GTextGerman.Values['Transcript exported to: '] := 'Transkript exportiert nach: ';
  GTextItalian.Values['Transcript exported to: '] := 'Trascrizione esportata in: ';
  GTextPolish.Values['Transcript exported to: '] := 'Transkrypcja wyeksportowana do: ';
  GTextPortuguesePT.Values['Transcript exported to: '] := 'Transcri'#231#227'o exportada para: ';
  GTextRomanian.Values['Transcript exported to: '] := 'Transcript exportat in: ';
  GTextHungarian.Values['Transcript exported to: '] := 'Atirat exportalva ide: ';
  GTextCzech.Values['Transcript exported to: '] := 'Prepis exportovan do: ';

  GTextEnglish.Values['Starting Python Consumer AI inter-application session...'] := 'Starting Python Consumer AI inter-application session...';
  GTextPortuguese.Values['Starting Python Consumer AI inter-application session...'] := 'Iniciando sess'#227'o interaplica'#231#245'es do Python Consumer AI...';
  GTextSpanish.Values['Starting Python Consumer AI inter-application session...'] := 'Iniciando sesion entre aplicaciones de Python Consumer AI...';
  GTextFrench.Values['Starting Python Consumer AI inter-application session...'] := 'Demarrage de la session inter-applications Python Consumer AI...';
  GTextGerman.Values['Starting Python Consumer AI inter-application session...'] := 'Anwendungsuebergreifende Sitzung von Python Consumer AI wird gestartet...';
  GTextItalian.Values['Starting Python Consumer AI inter-application session...'] := 'Avvio della sessione tra applicazioni di Python Consumer AI...';
  GTextPolish.Values['Starting Python Consumer AI inter-application session...'] := 'Uruchamianie sesji miedzy aplikacjami Python Consumer AI...';
  GTextPortuguesePT.Values['Starting Python Consumer AI inter-application session...'] := 'A iniciar sess'#227'o interaplica'#231#245'es do Python Consumer AI...';
  GTextRomanian.Values['Starting Python Consumer AI inter-application session...'] := 'Pornire sesiune intre aplicatii Python Consumer AI...';
  GTextHungarian.Values['Starting Python Consumer AI inter-application session...'] := 'A Python Consumer AI alkalmazasok kozotti munkamenet inditasa...';
  GTextCzech.Values['Starting Python Consumer AI inter-application session...'] := 'Spousteni meziplatformni relace Python Consumer AI...';

  GTextEnglish.Values['Waiting for Python...'] := 'Waiting for Python...';
  GTextPortuguese.Values['Waiting for Python...'] := 'Aguardando Python...';
  GTextSpanish.Values['Waiting for Python...'] := 'Esperando Python...';
  GTextFrench.Values['Waiting for Python...'] := 'En attente de Python...';
  GTextGerman.Values['Waiting for Python...'] := 'Warte auf Python...';
  GTextItalian.Values['Waiting for Python...'] := 'In attesa di Python...';
  GTextPolish.Values['Waiting for Python...'] := 'Oczekiwanie na Python...';
  GTextPortuguesePT.Values['Waiting for Python...'] := 'A aguardar Python...';
  GTextRomanian.Values['Waiting for Python...'] := 'Asteptare Python...';
  GTextHungarian.Values['Waiting for Python...'] := 'Varakozas Pythonra...';
  GTextCzech.Values['Waiting for Python...'] := 'Cekani na Python...';

  GTextEnglish.Values['Awaiting input'] := 'Awaiting input';
  GTextPortuguese.Values['Awaiting input'] := 'Aguardando entrada';
  GTextSpanish.Values['Awaiting input'] := 'Esperando entrada';
  GTextFrench.Values['Awaiting input'] := 'En attente de saisie';
  GTextGerman.Values['Awaiting input'] := 'Warte auf Eingabe';
  GTextItalian.Values['Awaiting input'] := 'In attesa di input';
  GTextPolish.Values['Awaiting input'] := 'Oczekiwanie na dane';
  GTextPortuguesePT.Values['Awaiting input'] := 'A aguardar entrada';
  GTextRomanian.Values['Awaiting input'] := 'Asteptare input';
  GTextHungarian.Values['Awaiting input'] := 'Bemenetre var';
  GTextCzech.Values['Awaiting input'] := 'Ceka na vstup';

  GTextEnglish.Values['No valid source file'] := 'No valid source file';
  GTextPortuguese.Values['No valid source file'] := 'Nenhum arquivo fonte v'#225'lido';
  GTextSpanish.Values['No valid source file'] := 'No hay archivo fuente valido';
  GTextFrench.Values['No valid source file'] := 'Aucun fichier source valide';
  GTextGerman.Values['No valid source file'] := 'Keine gueltige Quelldatei';
  GTextItalian.Values['No valid source file'] := 'Nessun file sorgente valido';
  GTextPolish.Values['No valid source file'] := 'Brak poprawnego pliku zrodlowego';
  GTextPortuguesePT.Values['No valid source file'] := 'Nenhum ficheiro fonte v'#225'lido';
  GTextRomanian.Values['No valid source file'] := 'Niciun fisier sursa valid';
  GTextHungarian.Values['No valid source file'] := 'Nincs ervenyes forrasfajl';
  GTextCzech.Values['No valid source file'] := 'Zadny platny zdrojovy soubor';

  GTextEnglish.Values['Select a valid input file before starting Consumer AI.'] := 'Select a valid input file before starting Consumer AI.';
  GTextPortuguese.Values['Select a valid input file before starting Consumer AI.'] := 'Selecione um arquivo de entrada v'#225'lido antes de iniciar o Consumer AI.';
  GTextSpanish.Values['Select a valid input file before starting Consumer AI.'] := 'Seleccione un archivo de entrada valido antes de iniciar Consumer AI.';
  GTextFrench.Values['Select a valid input file before starting Consumer AI.'] := 'Selectionnez un fichier valide avant de demarrer Consumer AI.';
  GTextGerman.Values['Select a valid input file before starting Consumer AI.'] := 'Waehlen Sie vor dem Start von Consumer AI eine gueltige Datei.';
  GTextItalian.Values['Select a valid input file before starting Consumer AI.'] := 'Seleziona un file valido prima di avviare Consumer AI.';
  GTextPolish.Values['Select a valid input file before starting Consumer AI.'] := 'Wybierz poprawny plik wejsciowy przed uruchomieniem Consumer AI.';
  GTextPortuguesePT.Values['Select a valid input file before starting Consumer AI.'] := 'Selecione um ficheiro de entrada v'#225'lido antes de iniciar o Consumer AI.';
  GTextRomanian.Values['Select a valid input file before starting Consumer AI.'] := 'Selectati un fisier valid inainte de a porni Consumer AI.';
  GTextHungarian.Values['Select a valid input file before starting Consumer AI.'] := 'Valasszon ervenyes bemeneti fajlt a Consumer AI inditasa elott.';
  GTextCzech.Values['Select a valid input file before starting Consumer AI.'] := 'Pred spustenim Consumer AI vyberte platny vstupni soubor.';

  GTextEnglish.Values['Script not found'] := 'Script not found';
  GTextPortuguese.Values['Script not found'] := 'Script n'#227'o encontrado';
  GTextSpanish.Values['Script not found'] := 'Script no encontrado';
  GTextFrench.Values['Script not found'] := 'Script introuvable';
  GTextGerman.Values['Script not found'] := 'Skript nicht gefunden';
  GTextItalian.Values['Script not found'] := 'Script non trovato';
  GTextPolish.Values['Script not found'] := 'Nie znaleziono skryptu';
  GTextPortuguesePT.Values['Script not found'] := 'Script n'#227'o encontrado';
  GTextRomanian.Values['Script not found'] := 'Script negasit';
  GTextHungarian.Values['Script not found'] := 'Script nem talalhato';
  GTextCzech.Values['Script not found'] := 'Skript nenalezen';

  GTextEnglish.Values['FastFile AI engine not found.'] := 'FastFile AI engine not found.';
  GTextPortuguese.Values['FastFile AI engine not found.'] := 'Motor FastFile AI n'#227'o encontrado.';
  GTextSpanish.Values['FastFile AI engine not found.'] := 'Motor FastFile AI no encontrado.';
  GTextFrench.Values['FastFile AI engine not found.'] := 'Moteur FastFile AI introuvable.';
  GTextGerman.Values['FastFile AI engine not found.'] := 'FastFile AI-Modul nicht gefunden.';
  GTextItalian.Values['FastFile AI engine not found.'] := 'Motore FastFile AI non trovato.';
  GTextPolish.Values['FastFile AI engine not found.'] := 'Nie znaleziono silnika FastFile AI.';
  GTextPortuguesePT.Values['FastFile AI engine not found.'] := 'Motor FastFile AI n'#227'o encontrado.';
  GTextRomanian.Values['FastFile AI engine not found.'] := 'Motorul FastFile AI nu a fost gasit.';
  GTextHungarian.Values['FastFile AI engine not found.'] := 'A FastFile AI motor nem talalhato.';
  GTextCzech.Values['FastFile AI engine not found.'] := 'Modul FastFile AI nebyl nalezen.';

  GTextEnglish.Values['Pipe error'] := 'Pipe error';
  GTextPortuguese.Values['Pipe error'] := 'Erro de pipe';
  GTextSpanish.Values['Pipe error'] := 'Error de pipe';
  GTextFrench.Values['Pipe error'] := 'Erreur de pipe';
  GTextGerman.Values['Pipe error'] := 'Pipe-Fehler';
  GTextItalian.Values['Pipe error'] := 'Errore pipe';
  GTextPolish.Values['Pipe error'] := 'Blad pipe';
  GTextPortuguesePT.Values['Pipe error'] := 'Erro de pipe';
  GTextRomanian.Values['Pipe error'] := 'Eroare pipe';
  GTextHungarian.Values['Pipe error'] := 'Pipe hiba';
  GTextCzech.Values['Pipe error'] := 'Chyba pipe';

  GTextEnglish.Values['Could not create stdout pipe.'] := 'Could not create stdout pipe.';
  GTextPortuguese.Values['Could not create stdout pipe.'] := 'N'#227'o foi poss'#237'vel criar o pipe stdout.';
  GTextSpanish.Values['Could not create stdout pipe.'] := 'No se pudo crear el pipe stdout.';
  GTextFrench.Values['Could not create stdout pipe.'] := 'Impossible de creer le pipe stdout.';
  GTextGerman.Values['Could not create stdout pipe.'] := 'Stdout-Pipe konnte nicht erstellt werden.';
  GTextItalian.Values['Could not create stdout pipe.'] := 'Impossibile creare pipe stdout.';
  GTextPolish.Values['Could not create stdout pipe.'] := 'Nie mozna utworzyc potoku stdout.';
  GTextPortuguesePT.Values['Could not create stdout pipe.'] := 'N'#227'o foi poss'#237'vel criar o pipe stdout.';
  GTextRomanian.Values['Could not create stdout pipe.'] := 'Nu s-a putut crea pipe stdout.';
  GTextHungarian.Values['Could not create stdout pipe.'] := 'Nem sikerult letrehozni a stdout pipe-ot.';
  GTextCzech.Values['Could not create stdout pipe.'] := 'Nelze vytvorit stdout pipe.';

  GTextEnglish.Values['Could not create stdin pipe.'] := 'Could not create stdin pipe.';
  GTextPortuguese.Values['Could not create stdin pipe.'] := 'N'#227'o foi poss'#237'vel criar o pipe stdin.';
  GTextSpanish.Values['Could not create stdin pipe.'] := 'No se pudo crear el pipe stdin.';
  GTextFrench.Values['Could not create stdin pipe.'] := 'Impossible de creer le pipe stdin.';
  GTextGerman.Values['Could not create stdin pipe.'] := 'Stdin-Pipe konnte nicht erstellt werden.';
  GTextItalian.Values['Could not create stdin pipe.'] := 'Impossibile creare pipe stdin.';
  GTextPolish.Values['Could not create stdin pipe.'] := 'Nie mozna utworzyc potoku stdin.';
  GTextPortuguesePT.Values['Could not create stdin pipe.'] := 'N'#227'o foi poss'#237'vel criar o pipe stdin.';
  GTextRomanian.Values['Could not create stdin pipe.'] := 'Nu s-a putut crea pipe stdin.';
  GTextHungarian.Values['Could not create stdin pipe.'] := 'Nem sikerult letrehozni a stdin pipe-ot.';
  GTextCzech.Values['Could not create stdin pipe.'] := 'Nelze vytvorit stdin pipe.';

  GTextEnglish.Values['Launch error'] := 'Launch error';
  GTextPortuguese.Values['Launch error'] := 'Erro de inicializa'#231#227'o';
  GTextSpanish.Values['Launch error'] := 'Error de inicio';
  GTextFrench.Values['Launch error'] := 'Erreur de lancement';
  GTextGerman.Values['Launch error'] := 'Startfehler';
  GTextItalian.Values['Launch error'] := 'Errore di avvio';
  GTextPolish.Values['Launch error'] := 'Blad uruchomienia';
  GTextPortuguesePT.Values['Launch error'] := 'Erro de arranque';
  GTextRomanian.Values['Launch error'] := 'Eroare la pornire';
  GTextHungarian.Values['Launch error'] := 'Inditasi hiba';
  GTextCzech.Values['Launch error'] := 'Chyba spusteni';

  GTextEnglish.Values['Could not start python/py process.'] := 'Could not start python/py process.';
  GTextPortuguese.Values['Could not start python/py process.'] := 'N'#227'o foi poss'#237'vel iniciar o processo python/py.';
  GTextSpanish.Values['Could not start python/py process.'] := 'No se pudo iniciar el proceso python/py.';
  GTextFrench.Values['Could not start python/py process.'] := 'Impossible de demarrer le processus python/py.';
  GTextGerman.Values['Could not start python/py process.'] := 'Python/py-Prozess konnte nicht gestartet werden.';
  GTextItalian.Values['Could not start python/py process.'] := 'Impossibile avviare il processo python/py.';
  GTextPolish.Values['Could not start python/py process.'] := 'Nie mozna uruchomic procesu python/py.';
  GTextPortuguesePT.Values['Could not start python/py process.'] := 'N'#227'o foi poss'#237'vel iniciar o processo python/py.';
  GTextRomanian.Values['Could not start python/py process.'] := 'Nu s-a putut porni procesul python/py.';
  GTextHungarian.Values['Could not start python/py process.'] := 'Nem sikerult elinditani a python/py folyamatot.';
  GTextCzech.Values['Could not start python/py process.'] := 'Nelze spustit python/py proces.';

  GTextEnglish.Values['File: '] := 'File: ';
  GTextPortuguese.Values['File: '] := 'Arquivo: ';
  GTextSpanish.Values['File: '] := 'Archivo: ';
  GTextFrench.Values['File: '] := 'Fichier: ';
  GTextGerman.Values['File: '] := 'Datei: ';
  GTextItalian.Values['File: '] := 'File: ';
  GTextPolish.Values['File: '] := 'Plik: ';
  GTextPortuguesePT.Values['File: '] := 'Ficheiro: ';
  GTextRomanian.Values['File: '] := 'Fisier: ';
  GTextHungarian.Values['File: '] := 'Fajl: ';
  GTextCzech.Values['File: '] := 'Soubor: ';

  GTextEnglish.Values['Starting...'] := 'Starting...';
  GTextPortuguese.Values['Starting...'] := 'Iniciando...';
  GTextSpanish.Values['Starting...'] := 'Iniciando...';
  GTextFrench.Values['Starting...'] := 'Demarrage...';
  GTextGerman.Values['Starting...'] := 'Startet...';
  GTextItalian.Values['Starting...'] := 'Avvio...';
  GTextPolish.Values['Starting...'] := 'Uruchamianie...';
  GTextPortuguesePT.Values['Starting...'] := 'A iniciar...';
  GTextRomanian.Values['Starting...'] := 'Pornire...';
  GTextHungarian.Values['Starting...'] := 'Inditas...';
  GTextCzech.Values['Starting...'] := 'Spousteni...';

  GTextEnglish.Values['Select all'] := 'Select all';
  GTextPortuguese.Values['Select all'] := 'Selecionar tudo';
  GTextSpanish.Values['Select all'] := 'Seleccionar todo';
  GTextFrench.Values['Select all'] := 'Tout selectionner';
  GTextGerman.Values['Select all'] := 'Alles auswaehlen';
  GTextItalian.Values['Select all'] := 'Seleziona tutto';
  GTextPolish.Values['Select all'] := 'Zaznacz wszystko';
  GTextPortuguesePT.Values['Select all'] := 'Selecionar tudo';
  GTextRomanian.Values['Select all'] := 'Selecteaza tot';
  GTextHungarian.Values['Select all'] := 'Osszes kijelolese';
  GTextCzech.Values['Select all'] := 'Vybrat vse';

  GTextEnglish.Values['Send'] := 'Send';
  GTextPortuguese.Values['Send'] := 'Enviar';
  GTextSpanish.Values['Send'] := 'Enviar';
  GTextFrench.Values['Send'] := 'Envoyer';
  GTextGerman.Values['Send'] := 'Senden';
  GTextItalian.Values['Send'] := 'Invia';
  GTextPolish.Values['Send'] := 'Wyslij';
  GTextPortuguesePT.Values['Send'] := 'Enviar';
  GTextRomanian.Values['Send'] := 'Trimite';
  GTextHungarian.Values['Send'] := 'Kuldes';
  GTextCzech.Values['Send'] := 'Odeslat';

  GTextEnglish.Values['More'] := 'More';
  GTextPortuguese.Values['More'] := 'Mais';
  GTextSpanish.Values['More'] := 'M'#225's';
  GTextFrench.Values['More'] := 'Plus';
  GTextGerman.Values['More'] := 'Mehr';
  GTextItalian.Values['More'] := 'Altro';
  GTextPolish.Values['More'] := 'Wiecej';
  GTextPortuguesePT.Values['More'] := 'Mais';
  GTextRomanian.Values['More'] := 'Mai mult';
  GTextHungarian.Values['More'] := 'Tobb';
  GTextCzech.Values['More'] := 'Vice';

  GTextEnglish.Values['Read-only &session'] := 'Read-only &session';
  GTextPortuguese.Values['Read-only &session'] := 'Sess'#227'o somente &leitura';
  GTextSpanish.Values['Read-only &session'] := 'Sesi'#243'n solo &lectura';
  GTextFrench.Values['Read-only &session'] := 'Session lecture &seule';
  GTextGerman.Values['Read-only &session'] := '&Nur-Lese-Sitzung';
  GTextItalian.Values['Read-only &session'] := 'Sessione solo &lettura';
  GTextPolish.Values['Read-only &session'] := 'Sesja tylko do &odczytu';
  GTextPortuguesePT.Values['Read-only &session'] := 'Sess'#227'o apenas de &leitura';
  GTextRomanian.Values['Read-only &session'] := 'Sesiune doar &citire';
  GTextHungarian.Values['Read-only &session'] := '&Csak olvashato munkamenet';
  GTextCzech.Values['Read-only &session'] := 'Relace pouze pro &cteni';

  GTextEnglish.Values['Read-only session'] := 'Read-only session';
  GTextPortuguese.Values['Read-only session'] := 'Sess'#227'o somente leitura';
  GTextSpanish.Values['Read-only session'] := 'Sesi'#243'n solo lectura';
  GTextFrench.Values['Read-only session'] := 'Session lecture seule';
  GTextGerman.Values['Read-only session'] := 'Nur-Lese-Sitzung';
  GTextItalian.Values['Read-only session'] := 'Sessione solo lettura';
  GTextPolish.Values['Read-only session'] := 'Sesja tylko do odczytu';
  GTextPortuguesePT.Values['Read-only session'] := 'Sess'#227'o apenas de leitura';
  GTextRomanian.Values['Read-only session'] := 'Sesiune doar citire';
  GTextHungarian.Values['Read-only session'] := 'Csak olvashato munkamenet';
  GTextCzech.Values['Read-only session'] := 'Relace pouze pro cteni';

  GTextEnglish.Values['Read-only'] := 'Read-only';
  GTextPortuguese.Values['Read-only'] := 'Somente leitura';
  GTextSpanish.Values['Read-only'] := 'Solo lectura';
  GTextFrench.Values['Read-only'] := 'Lecture seule';
  GTextGerman.Values['Read-only'] := 'Nur lesen';
  GTextItalian.Values['Read-only'] := 'Sola lettura';
  GTextPolish.Values['Read-only'] := 'Tylko do odczytu';
  GTextPortuguesePT.Values['Read-only'] := 'Apenas leitura';
  GTextRomanian.Values['Read-only'] := 'Doar citire';
  GTextHungarian.Values['Read-only'] := 'Csak olvashato';
  GTextCzech.Values['Read-only'] := 'Pouze pro cteni';

  GTextEnglish.Values['Read-only session is enabled. Turn it off in Options to edit or save the file.'] :=
    'Read-only session is enabled. Turn it off in Options to edit or save the file.';
  GTextPortuguese.Values['Read-only session is enabled. Turn it off in Options to edit or save the file.'] :=
    'A sess'#227'o somente leitura est'#225' ativa. Desative em Op'#231#245'es para editar ou gravar o arquivo.';
  GTextSpanish.Values['Read-only session is enabled. Turn it off in Options to edit or save the file.'] :=
    'La sesi'#243'n solo lectura est'#225' activa. Desact'#237'vela en Opciones para editar o guardar el archivo.';
  GTextFrench.Values['Read-only session is enabled. Turn it off in Options to edit or save the file.'] :=
    'La session lecture seule est activ'#233'e. D'#233'sactivez-la dans Options pour modifier ou enregistrer le fichier.';
  GTextGerman.Values['Read-only session is enabled. Turn it off in Options to edit or save the file.'] :=
    'Die Nur-Lese-Sitzung ist aktiv. Schalten Sie sie unter Optionen aus, um die Datei zu bearbeiten oder zu speichern.';
  GTextItalian.Values['Read-only session is enabled. Turn it off in Options to edit or save the file.'] :=
    'La sessione solo lettura '#232' attiva. Disattivala in Opzioni per modificare o salvare il file.';
  GTextPolish.Values['Read-only session is enabled. Turn it off in Options to edit or save the file.'] :=
    'Sesja tylko do odczytu jest w'#322#261'czona. Wy'#322#261'cz j'#261' w Opcjach, aby edytowa'#263' lub zapisa'#263' plik.';
  GTextPortuguesePT.Values['Read-only session is enabled. Turn it off in Options to edit or save the file.'] :=
    'A sess'#227'o apenas de leitura est'#225' activa. Desactive-a em Op'#231#245'es para editar ou gravar o ficheiro.';
  GTextRomanian.Values['Read-only session is enabled. Turn it off in Options to edit or save the file.'] :=
    'Sesiunea doar citire este activ'#259'. Dezactivati-o din Optiuni pentru a edita sau salva fisierul.';
  GTextHungarian.Values['Read-only session is enabled. Turn it off in Options to edit or save the file.'] :=
    'A csak olvashato munkamenet be van kapcsolva. Kapcsolja ki a Beallitasokban a szerkeszteshez vagy menteshez.';
  GTextCzech.Values['Read-only session is enabled. Turn it off in Options to edit or save the file.'] :=
    'Relace pouze pro cteni je zapnuta. Vypnete ji v Moznostech, chcete-li soubor upravit nebo ulozit.';

  GTextEnglish.Values['View encoding: forced (list decode only; file on disk unchanged).'] :=
    'View encoding: forced (list decode only; file on disk unchanged).';
  GTextPortuguese.Values['View encoding: forced (list decode only; file on disk unchanged).'] :=
    'Codifica'#231#227'o da visualiza'#231#227'o: for'#231'ada (s'#243' decodifica a lista; arquivo no disco inalterado).';
  GTextSpanish.Values['View encoding: forced (list decode only; file on disk unchanged).'] :=
    'Codificaci'#243'n de vista: forzada (solo decodifica la lista; archivo en disco sin cambios).';
  GTextFrench.Values['View encoding: forced (list decode only; file on disk unchanged).'] :=
    'Encodage d''affichage : forc'#233' (d'#233'code seulement la liste ; fichier sur disque inchang'#233').';
  GTextGerman.Values['View encoding: forced (list decode only; file on disk unchanged).'] :=
    'Ansichtskodierung: erzwungen (nur Listen-Decode; Datei auf der Platte unver'#228'ndert).';
  GTextItalian.Values['View encoding: forced (list decode only; file on disk unchanged).'] :=
    'Encoding vista: forzato (solo decodifica elenco; file su disco invariato).';
  GTextPolish.Values['View encoding: forced (list decode only; file on disk unchanged).'] :=
    'Kodowanie widoku: wymuszone (tylko dekodowanie listy; plik na dysku bez zmian).';
  GTextPortuguesePT.Values['View encoding: forced (list decode only; file on disk unchanged).'] :=
    'Codifica'#231#227'o da vista: for'#231'ada (s'#243' descodifica a lista; ficheiro no disco inalterado).';
  GTextRomanian.Values['View encoding: forced (list decode only; file on disk unchanged).'] :=
    'Codificare vizualizare: fortat'#259' (numai decodare list'#259'; fi'#537'ierul pe disc neschimbat).';
  GTextHungarian.Values['View encoding: forced (list decode only; file on disk unchanged).'] :=
    'Nezet kodolas: kenyszeritett (csak lista dekodolas; lemezen a fajl valtozatlan).';
  GTextCzech.Values['View encoding: forced (list decode only; file on disk unchanged).'] :=
    'Kodovani zobrazeni: vynucene (pouze dekodovani seznamu; soubor na disku beze zmeny).';

  GTextEnglish.Values['View encoding: default (list follows detected BOM/heuristics).'] :=
    'View encoding: default (list follows detected BOM/heuristics).';
  GTextPortuguese.Values['View encoding: default (list follows detected BOM/heuristics).'] :=
    'Codifica'#231#227'o da visualiza'#231#227'o: padr'#227'o (a lista segue BOM/heur'#237'sticas detectados).';
  GTextSpanish.Values['View encoding: default (list follows detected BOM/heuristics).'] :=
    'Codificaci'#243'n de vista: predeterminada (la lista sigue el BOM/heur'#237'stica detectados).';
  GTextFrench.Values['View encoding: default (list follows detected BOM/heuristics).'] :=
    'Encodage d''affichage : d'#233'faut (la liste suit le BOM/heuristique d'#233'tect'#233's).';
  GTextGerman.Values['View encoding: default (list follows detected BOM/heuristics).'] :=
    'Ansichtskodierung: Standard (Liste folgt erkanntem BOM/Heuristik).';
  GTextItalian.Values['View encoding: default (list follows detected BOM/heuristics).'] :=
    'Encoding vista: predefinito (l''elenco segue BOM/euristica rilevati).';
  GTextPolish.Values['View encoding: default (list follows detected BOM/heuristics).'] :=
    'Kodowanie widoku: domy'#347'lne (lista wed'#322'ug wykrytego BOM/heurystyki).';
  GTextPortuguesePT.Values['View encoding: default (list follows detected BOM/heuristics).'] :=
    'Codifica'#231#227'o da vista: predefinida (a lista segue o BOM/heur'#237'stica detectados).';
  GTextRomanian.Values['View encoding: default (list follows detected BOM/heuristics).'] :=
    'Codificare vizualizare: implicit'#259' (lista urmeaz'#259' BOM/euristica detectate).';
  GTextHungarian.Values['View encoding: default (list follows detected BOM/heuristics).'] :=
    'Nezet kodolas: alapertelmezett (lista az eszlelt BOM/heurisztika szerint).';
  GTextCzech.Values['View encoding: default (list follows detected BOM/heuristics).'] :=
    'Kodovani zobrazeni: vychozi (seznam podle detekovaneho BOM/heuristiky).';

  GTextEnglish.Values['[Line truncated for display: %s bytes total.]'] :=
    '[Line truncated for display: %s bytes total.]';
  GTextPortuguese.Values['[Line truncated for display: %s bytes total.]'] :=
    '[Linha truncada para exibi'#231#227'o: %s bytes no total.]';
  GTextSpanish.Values['[Line truncated for display: %s bytes total.]'] :=
    '[L'#237'nea truncada para mostrar: %s bytes en total.]';
  GTextFrench.Values['[Line truncated for display: %s bytes total.]'] :=
    '[Ligne tronqu'#233'e pour l''affichage : %s octets au total.]';
  GTextGerman.Values['[Line truncated for display: %s bytes total.]'] :=
    '[Zeile zur Anzeige gek'#252'rzt: %s Bytes gesamt.]';
  GTextItalian.Values['[Line truncated for display: %s bytes total.]'] :=
    '[Riga troncata per la visualizzazione: %s byte totali.]';
  GTextPolish.Values['[Line truncated for display: %s bytes total.]'] :=
    '[Linia obci'#281'ta do podgl'#261'du: %s bajt'#243'w razem.]';
  GTextPortuguesePT.Values['[Line truncated for display: %s bytes total.]'] :=
    '[Linha truncada para exibi'#231#227'o: %s bytes no total.]';
  GTextRomanian.Values['[Line truncated for display: %s bytes total.]'] :=
    '[Linie trunchiat'#259' pentru afi'#537'are: %s octe'#539'i in total.]';
  GTextHungarian.Values['[Line truncated for display: %s bytes total.]'] :=
    '[Sor megjeleniteshez csonkitva: %s bajt osszesen.]';
  GTextCzech.Values['[Line truncated for display: %s bytes total.]'] :=
    '[Radek zkracen pro zobrazeni: %s bajtu celkem.]';

  GTextEnglish.Values['Quit'] := 'Quit';
  GTextPortuguese.Values['Quit'] := 'Sair';
  GTextSpanish.Values['Quit'] := 'Salir';
  GTextFrench.Values['Quit'] := 'Quitter';
  GTextGerman.Values['Quit'] := 'Beenden';
  GTextItalian.Values['Quit'] := 'Esci';
  GTextPolish.Values['Quit'] := 'Wyjdz';
  GTextPortuguesePT.Values['Quit'] := 'Sair';
  GTextRomanian.Values['Quit'] := 'Iesire';
  GTextHungarian.Values['Quit'] := 'Kilepes';
  GTextCzech.Values['Quit'] := 'Ukoncit';

  GTextEnglish.Values['I don''t know'] := 'I don''t know';
  GTextPortuguese.Values['I don''t know'] := 'N'#227'o sei';
  GTextSpanish.Values['I don''t know'] := 'No se';
  GTextFrench.Values['I don''t know'] := 'Je ne sais pas';
  GTextGerman.Values['I don''t know'] := 'Ich weiss nicht';
  GTextItalian.Values['I don''t know'] := 'Non lo so';
  GTextPolish.Values['I don''t know'] := 'Nie wiem';
  GTextPortuguesePT.Values['I don''t know'] := 'N'#227'o sei';
  GTextRomanian.Values['I don''t know'] := 'Nu stiu';
  GTextHungarian.Values['I don''t know'] := 'Nem tudom';
  GTextCzech.Values['I don''t know'] := 'Nevim';
end;

procedure AddNewLanguagesTabComponentCoverage;
begin
  { Stability overrides for Delphi 7 ANSI rendering (RO/CS critical UI) }
  GTextRomanian.Values['Read'] := 'Citire';
  GTextRomanian.Values['&File'] := '&Fisier';
  GTextCzech.Values['Read'] := 'Cteni';

  GTextRomanian.Values['&Options'] := '&Optiuni';
  GTextRomanian.Values['&Help'] := '&Ajutor';
  GTextRomanian.Values['Find Files'] := 'Gaseste fisiere';
  GTextRomanian.Values['Name && Location'] := 'Nume && Locatie';

  GTextCzech.Values['&Options'] := '&Moznosti';
  GTextCzech.Values['&Help'] := '&Napoveda';
  GTextCzech.Values['Find Files'] := 'Hledat soubory';
  GTextCzech.Values['Name && Location'] := 'Nazev && Umisteni';

  { List/grid headers }
  GTextPolish.Values['Line #'] := 'Linia #';
  GTextRomanian.Values['Line #'] := 'Linia #';
  GTextHungarian.Values['Line #'] := 'Sor #';
  GTextCzech.Values['Line #'] := 'Radek #';

  GTextPolish.Values['Content'] := 'Zawartosc';
  GTextRomanian.Values['Content'] := 'Continut';
  GTextHungarian.Values['Content'] := 'Tartalom';
  GTextCzech.Values['Content'] := 'Obsah';

  GTextPolish.Values['Name'] := 'Nazwa';
  GTextRomanian.Values['Name'] := 'Nume';
  GTextHungarian.Values['Name'] := 'Nev';
  GTextCzech.Values['Name'] := 'Nazev';

  GTextPolish.Values['Location'] := 'Lokalizacja';
  GTextRomanian.Values['Location'] := 'Locatie';
  GTextHungarian.Values['Location'] := 'Hely';
  GTextCzech.Values['Location'] := 'Umisteni';

  GTextPolish.Values['Size'] := 'Rozmiar';
  GTextRomanian.Values['Size'] := 'Dimensiune';
  GTextHungarian.Values['Size'] := 'Meret';
  GTextCzech.Values['Size'] := 'Velikost';

  GTextPolish.Values['Modified'] := 'Zmodyfikowano';
  GTextRomanian.Values['Modified'] := 'Modificat';
  GTextHungarian.Values['Modified'] := 'Modositva';
  GTextCzech.Values['Modified'] := 'Zmeneno';

  { Find Files labels }
  GTextPolish.Values['File Name (Separate multiple names with semicolon):'] := 'Nazwa pliku (oddziel wiele nazw srednikiem):';
  GTextRomanian.Values['File Name (Separate multiple names with semicolon):'] := 'Nume fisier (separati mai multe nume cu punct si virgula):';
  GTextHungarian.Values['File Name (Separate multiple names with semicolon):'] := 'Fajlnev (tobb nevet pontosvesszovel valasszon el):';
  GTextCzech.Values['File Name (Separate multiple names with semicolon):'] := 'Nazev souboru (vice nazvu oddelte strednikem):';

  GTextPolish.Values['Location (Separate multiple directories with semicolon):'] := 'Lokalizacja (oddziel wiele katalogow srednikiem):';
  GTextRomanian.Values['Location (Separate multiple directories with semicolon):'] := 'Locatie (separati mai multe directoare cu punct si virgula):';
  GTextHungarian.Values['Location (Separate multiple directories with semicolon):'] := 'Hely (tobb mappat pontosvesszovel valasszon el):';
  GTextCzech.Values['Location (Separate multiple directories with semicolon):'] := 'Umisteni (vice slozek oddelte strednikem):';

  GTextPolish.Values['Content:'] := 'Zawartosc:';
  GTextRomanian.Values['Content:'] := 'Continut:';
  GTextHungarian.Values['Content:'] := 'Tartalom:';
  GTextCzech.Values['Content:'] := 'Obsah:';

  { File attributes/date filters }
  GTextPolish.Values['Before Date:'] := 'Przed data:';
  GTextRomanian.Values['Before Date:'] := 'Inainte de data:';
  GTextHungarian.Values['Before Date:'] := 'Datum elott:';
  GTextCzech.Values['Before Date:'] := 'Pred datem:';

  GTextPolish.Values['Before Time:'] := 'Przed czasem:';
  GTextRomanian.Values['Before Time:'] := 'Inainte de ora:';
  GTextHungarian.Values['Before Time:'] := 'Ido elott:';
  GTextCzech.Values['Before Time:'] := 'Pred casem:';

  GTextPolish.Values['After Date:'] := 'Po dacie:';
  GTextRomanian.Values['After Date:'] := 'Dupa data:';
  GTextHungarian.Values['After Date:'] := 'Datum utan:';
  GTextCzech.Values['After Date:'] := 'Po datu:';

  GTextPolish.Values['After Time:'] := 'Po czasie:';
  GTextRomanian.Values['After Time:'] := 'Dupa ora:';
  GTextHungarian.Values['After Time:'] := 'Ido utan:';
  GTextCzech.Values['After Time:'] := 'Po case:';

  GTextPolish.Values['At Most:'] := 'Maksymalnie:';
  GTextRomanian.Values['At Most:'] := 'Cel mult:';
  GTextHungarian.Values['At Most:'] := 'Legfeljebb:';
  GTextCzech.Values['At Most:'] := 'Nejvice:';

  GTextPolish.Values['At Least:'] := 'Co najmniej:';
  GTextRomanian.Values['At Least:'] := 'Cel putin:';
  GTextHungarian.Values['At Least:'] := 'Legalabb:';
  GTextCzech.Values['At Least:'] := 'Alespon:';

  GTextPolish.Values['Attributes'] := 'Atrybuty';
  GTextRomanian.Values['Attributes'] := 'Atribute';
  GTextHungarian.Values['Attributes'] := 'Attributumok';
  GTextCzech.Values['Attributes'] := 'Atributy';

  GTextPolish.Values['System'] := 'Systemowy';
  GTextRomanian.Values['System'] := 'Sistem';
  GTextHungarian.Values['System'] := 'Rendszer';
  GTextCzech.Values['System'] := 'System';

  GTextPolish.Values['Hidden'] := 'Ukryty';
  GTextRomanian.Values['Hidden'] := 'Ascuns';
  GTextHungarian.Values['Hidden'] := 'Rejtett';
  GTextCzech.Values['Hidden'] := 'Skryty';

  GTextPolish.Values['Readonly'] := 'Tylko do odczytu';
  GTextRomanian.Values['Readonly'] := 'Doar citire';
  GTextHungarian.Values['Readonly'] := 'Csak olvashato';
  GTextCzech.Values['Readonly'] := 'Jen pro cteni';

  GTextPolish.Values['Archive'] := 'Archiwum';
  GTextRomanian.Values['Archive'] := 'Arhiva';
  GTextHungarian.Values['Archive'] := 'Archiv';
  GTextCzech.Values['Archive'] := 'Archiv';

  GTextPolish.Values['Directory'] := 'Katalog';
  GTextRomanian.Values['Directory'] := 'Director';
  GTextHungarian.Values['Directory'] := 'Konyvtar';
  GTextCzech.Values['Directory'] := 'Adresar';

  GTextPolish.Values['Compressed'] := 'Skompresowany';
  GTextRomanian.Values['Compressed'] := 'Comprimat';
  GTextHungarian.Values['Compressed'] := 'Tomoritett';
  GTextCzech.Values['Compressed'] := 'Komprimovany';

  GTextPolish.Values['Encrypted'] := 'Zaszyfrowany';
  GTextRomanian.Values['Encrypted'] := 'Criptat';
  GTextHungarian.Values['Encrypted'] := 'Titkositott';
  GTextCzech.Values['Encrypted'] := 'Sifrovany';

  GTextPolish.Values['Offline'] := 'Offline';
  GTextRomanian.Values['Offline'] := 'Offline';
  GTextHungarian.Values['Offline'] := 'Offline';
  GTextCzech.Values['Offline'] := 'Offline';

  GTextPolish.Values['Sparse File'] := 'Plik sparse';
  GTextRomanian.Values['Sparse File'] := 'Fisier sparse';
  GTextHungarian.Values['Sparse File'] := 'Ritka fajl';
  GTextCzech.Values['Sparse File'] := 'Ridky soubor';

  GTextPolish.Values['Reparse Point'] := 'Punkt ponownej analizy';
  GTextRomanian.Values['Reparse Point'] := 'Punct de reanaliza';
  GTextHungarian.Values['Reparse Point'] := 'Ujraelemzesi pont';
  GTextCzech.Values['Reparse Point'] := 'Bod preparsovani';

  GTextPolish.Values['Temporary'] := 'Tymczasowy';
  GTextRomanian.Values['Temporary'] := 'Temporar';
  GTextHungarian.Values['Temporary'] := 'Ideiglenes';
  GTextCzech.Values['Temporary'] := 'Docasny';

  GTextPolish.Values['Device'] := 'Urzadzenie';
  GTextRomanian.Values['Device'] := 'Dispozitiv';
  GTextHungarian.Values['Device'] := 'Eszkoz';
  GTextCzech.Values['Device'] := 'Zarizeni';

  GTextPolish.Values['Normal'] := 'Normalny';
  GTextRomanian.Values['Normal'] := 'Normal';
  GTextHungarian.Values['Normal'] := 'Normal';
  GTextCzech.Values['Normal'] := 'Normalni';

  GTextPolish.Values['Not Content Indexed'] := 'Nieindeksowany';
  GTextRomanian.Values['Not Content Indexed'] := 'Neindexat';
  GTextHungarian.Values['Not Content Indexed'] := 'Nem indexelt';
  GTextCzech.Values['Not Content Indexed'] := 'Neindexovany';

  GTextPolish.Values['Virtual'] := 'Wirtualny';
  GTextRomanian.Values['Virtual'] := 'Virtual';
  GTextHungarian.Values['Virtual'] := 'Virtualis';
  GTextCzech.Values['Virtual'] := 'Virtualni';

  { Folders/files exclude tab controls }
  GTextPolish.Values['Folders'] := 'Foldery';
  GTextRomanian.Values['Folders'] := 'Foldere';
  GTextHungarian.Values['Folders'] := 'Mappak';
  GTextCzech.Values['Folders'] := 'Slozky';

  GTextPolish.Values['Files'] := 'Pliki';
  GTextRomanian.Values['Files'] := 'Fisiere';
  GTextHungarian.Values['Files'] := 'Fajlok';
  GTextCzech.Values['Files'] := 'Soubory';

  GTextPolish.Values['Insert from prompt'] := 'Wstaw z promptu';
  GTextRomanian.Values['Insert from prompt'] := 'Insereaza din prompt';
  GTextHungarian.Values['Insert from prompt'] := 'Beszuras promptbol';
  GTextCzech.Values['Insert from prompt'] := 'Vlozit z promptu';

  GTextPolish.Values['Delete'] := 'Usun';
  GTextRomanian.Values['Delete'] := 'Sterge';
  GTextHungarian.Values['Delete'] := 'Torles';
  GTextCzech.Values['Delete'] := 'Smazat';

  GTextPolish.Values['Import file extensions'] := 'Importuj rozszerzenia plikow';
  GTextRomanian.Values['Import file extensions'] := 'Import extensii fisiere';
  GTextHungarian.Values['Import file extensions'] := 'Fajlkiterjesztesek importja';
  GTextCzech.Values['Import file extensions'] := 'Import pripon souboru';

  GTextPolish.Values['Import'] := 'Importuj';
  GTextRomanian.Values['Import'] := 'Importa';
  GTextHungarian.Values['Import'] := 'Import';
  GTextCzech.Values['Import'] := 'Import';

  { Top toolbar i18n labels }
  GTextPolish.Values['Change scaling'] := 'Zmien skale';
  GTextRomanian.Values['Change scaling'] := 'Schimba scalarea';
  GTextHungarian.Values['Change scaling'] := 'Meretezes valtas';
  GTextCzech.Values['Change scaling'] := 'Zmenit meritko';

  GTextPolish.Values['Skin name:'] := 'Nazwa skorki:';
  GTextRomanian.Values['Skin name:'] := 'Nume tema:';
  GTextHungarian.Values['Skin name:'] := 'Skin nev:';
  GTextCzech.Values['Skin name:'] := 'Nazev skinu:';

  GTextPolish.Values['Active'] := 'Aktywny';
  GTextRomanian.Values['Active'] := 'Activ';
  GTextHungarian.Values['Active'] := 'Aktiv';
  GTextCzech.Values['Active'] := 'Aktivni';

  GTextPolish.Values['Allow animation'] := 'Zezwol na animacje';
  GTextRomanian.Values['Allow animation'] := 'Permite animatie';
  GTextHungarian.Values['Allow animation'] := 'Animacio engedelyezese';
  GTextCzech.Values['Allow animation'] := 'Povolit animaci';

  GTextPolish.Values['Exit'] := 'Wyjscie';
  GTextRomanian.Values['Exit'] := 'Iesire';
  GTextHungarian.Values['Exit'] := 'Kilepes';
  GTextCzech.Values['Exit'] := 'Ukoncit';

  { Missing runtime/find/help keys used in MainUnit }
  GTextPolish.Values[' (DEFAULT view)'] := ' (WIDOK DOMYSLNY)';
  GTextRomanian.Values[' (DEFAULT view)'] := ' (VIZUALIZARE IMPLICITA)';
  GTextHungarian.Values[' (DEFAULT view)'] := ' (ALAPERTELMEZETT NEZET)';
  GTextCzech.Values[' (DEFAULT view)'] := ' (VYCHOZI ZOBRAZENI)';

  GTextPolish.Values['&Copy'] := '&Kopiuj';
  GTextRomanian.Values['&Copy'] := '&Copiaza';
  GTextHungarian.Values['&Copy'] := '&Masolas';
  GTextCzech.Values['&Copy'] := '&Kopirovat';

  GTextPolish.Values['&Export...'] := '&Eksport...';
  GTextRomanian.Values['&Export...'] := '&Export...';
  GTextHungarian.Values['&Export...'] := '&Export...';
  GTextCzech.Values['&Export...'] := '&Export...';

  GTextPolish.Values['(Yes = Case Sensitive / No = Ignore case)'] := '(Tak = wrazliwe na wielkosc liter / Nie = ignoruj)';
  GTextRomanian.Values['(Yes = Case Sensitive / No = Ignore case)'] := '(Da = sensibil la majuscule / Nu = ignora)';
  GTextHungarian.Values['(Yes = Case Sensitive / No = Ignore case)'] := '(Igen = kis/nagybetu erzekeny / Nem = figyelmen kivul)';
  GTextCzech.Values['(Yes = Case Sensitive / No = Ignore case)'] := '(Ano = rozlisovat velikost / Ne = ignorovat)';

  GTextPolish.Values['Case sensitive search?'] := 'Wyszukiwanie wrazliwe na wielkosc liter?';
  GTextRomanian.Values['Case sensitive search?'] := 'Cautare sensibila la majuscule?';
  GTextHungarian.Values['Case sensitive search?'] := 'Kis/nagybetu erzekeny kereses?';
  GTextCzech.Values['Case sensitive search?'] := 'Rozlisovat velka/mala pismena?';

  GTextPolish.Values['Content copied to clipboard.'] := 'Zawartosc skopiowana do schowka.';
  GTextRomanian.Values['Content copied to clipboard.'] := 'Continut copiat in clipboard.';
  GTextHungarian.Values['Content copied to clipboard.'] := 'Tartalom a vagolapra masolva.';
  GTextCzech.Values['Content copied to clipboard.'] := 'Obsah zkopirovan do schranky.';

  GTextPolish.Values['Content exported to memo.'] := 'Zawartosc wyeksportowana do memo.';
  GTextRomanian.Values['Content exported to memo.'] := 'Continut exportat in memo.';
  GTextHungarian.Values['Content exported to memo.'] := 'Tartalom memo-ba exportalva.';
  GTextCzech.Values['Content exported to memo.'] := 'Obsah exportovan do memo.';

  GTextPolish.Values['Contents copied to the clipboard. Just paste (CTRL+V).'] := 'Zawartosc skopiowana do schowka. Wklej (CTRL+V).';
  GTextRomanian.Values['Contents copied to the clipboard. Just paste (CTRL+V).'] := 'Continut copiat in clipboard. Lipiti cu (CTRL+V).';
  GTextHungarian.Values['Contents copied to the clipboard. Just paste (CTRL+V).'] := 'Tartalom vagolapra masolva. Illeszd be (CTRL+V).';
  GTextCzech.Values['Contents copied to the clipboard. Just paste (CTRL+V).'] := 'Obsah zkopirovan do schranky. Vlozte (CTRL+V).';

  GTextPolish.Values['Detected on file: '] := 'Wykryto w pliku: ';
  GTextRomanian.Values['Detected on file: '] := 'Detectat in fisier: ';
  GTextHungarian.Values['Detected on file: '] := 'Fajlban eszlelve: ';
  GTextCzech.Values['Detected on file: '] := 'Zjisteno v souboru: ';

  GTextPolish.Values['Does not re-read file. DEFAULT = BOM/heuristics.'] := 'Nie czyta pliku ponownie. DOMYSLNIE = BOM/heurystyka.';
  GTextRomanian.Values['Does not re-read file. DEFAULT = BOM/heuristics.'] := 'Nu reciteste fisierul. IMPLICIT = BOM/euristica.';
  GTextHungarian.Values['Does not re-read file. DEFAULT = BOM/heuristics.'] := 'Nem olvassa ujra a fajlt. ALAP = BOM/heurisztika.';
  GTextCzech.Values['Does not re-read file. DEFAULT = BOM/heuristics.'] := 'Necte soubor znovu. VYCHOZI = BOM/heuristika.';

  GTextPolish.Values['Does not re-read file. Pick UTF-8 / ANSI / UTF-16 to force.'] := 'Nie czyta pliku ponownie. Wybierz UTF-8 / ANSI / UTF-16 aby wymusic.';
  GTextRomanian.Values['Does not re-read file. Pick UTF-8 / ANSI / UTF-16 to force.'] := 'Nu reciteste fisierul. Alegeti UTF-8 / ANSI / UTF-16 pentru fortare.';
  GTextHungarian.Values['Does not re-read file. Pick UTF-8 / ANSI / UTF-16 to force.'] := 'Nem olvassa ujra a fajlt. Valassz UTF-8 / ANSI / UTF-16 kenyszert.';
  GTextCzech.Values['Does not re-read file. Pick UTF-8 / ANSI / UTF-16 to force.'] := 'Necte soubor znovu. Vyberte UTF-8 / ANSI / UTF-16 pro vynuceni.';

  GTextPolish.Values['Error'] := 'Blad';
  GTextRomanian.Values['Error'] := 'Eroare';
  GTextHungarian.Values['Error'] := 'Hiba';
  GTextCzech.Values['Error'] := 'Chyba';

  GTextPolish.Values['Extension files exclusion'] := 'Wykluczenie rozszerzen plikow';
  GTextRomanian.Values['Extension files exclusion'] := 'Excludere extensii fisiere';
  GTextHungarian.Values['Extension files exclusion'] := 'Fajlkiterjesztes kizarasa';
  GTextCzech.Values['Extension files exclusion'] := 'Vylouceni pripon souboru';

  GTextPolish.Values['File created:'] := 'Utworzono plik:';
  GTextRomanian.Values['File created:'] := 'Fisier creat:';
  GTextHungarian.Values['File created:'] := 'Fajl letrehozva:';
  GTextCzech.Values['File created:'] := 'Soubor vytvoren:';

  GTextPolish.Values['File saved with success.'] := 'Plik zapisano pomyslnie.';
  GTextRomanian.Values['File saved with success.'] := 'Fisier salvat cu succes.';
  GTextHungarian.Values['File saved with success.'] := 'Fajl sikeresen mentve.';
  GTextCzech.Values['File saved with success.'] := 'Soubor uspesne ulozen.';

  GTextPolish.Values['files generated successfully.'] := 'Pliki wygenerowano pomyslnie.';
  GTextRomanian.Values['files generated successfully.'] := 'Fisiere generate cu succes.';
  GTextHungarian.Values['files generated successfully.'] := 'Fajlok sikeresen generalva.';
  GTextCzech.Values['files generated successfully.'] := 'Soubory byly uspesne vygenerovany.';

  GTextPolish.Values['Files:'] := 'Pliki:';
  GTextRomanian.Values['Files:'] := 'Fisiere:';
  GTextHungarian.Values['Files:'] := 'Fajlok:';
  GTextCzech.Values['Files:'] := 'Soubory:';

  GTextPolish.Values['Filter / Grep'] := 'Filtr / Grep';
  GTextRomanian.Values['Filter / Grep'] := 'Filtru / Grep';
  GTextHungarian.Values['Filter / Grep'] := 'Szuro / Grep';
  GTextCzech.Values['Filter / Grep'] := 'Filtr / Grep';

  GTextPolish.Values['Folder saved with success.'] := 'Folder zapisano pomyslnie.';
  GTextRomanian.Values['Folder saved with success.'] := 'Folder salvat cu succes.';
  GTextHungarian.Values['Folder saved with success.'] := 'Mappa sikeresen mentve.';
  GTextCzech.Values['Folder saved with success.'] := 'Slozka uspesne ulozena.';

  GTextPolish.Values['Folders exclusion'] := 'Wykluczenie folderow';
  GTextRomanian.Values['Folders exclusion'] := 'Excludere foldere';
  GTextHungarian.Values['Folders exclusion'] := 'Mappa kizarasa';
  GTextCzech.Values['Folders exclusion'] := 'Vylouceni slozek';

  GTextPolish.Values['Hide the watermark?'] := 'Ukryc znak wodny?';
  GTextRomanian.Values['Hide the watermark?'] := 'Ascundeti watermark-ul?';
  GTextHungarian.Values['Hide the watermark?'] := 'Elrejted a vizjelet?';
  GTextCzech.Values['Hide the watermark?'] := 'Skryt watermark?';

  GTextPolish.Values['Information'] := 'Informacja';
  GTextRomanian.Values['Information'] := 'Informatii';
  GTextHungarian.Values['Information'] := 'Informacio';
  GTextCzech.Values['Information'] := 'Informace';

  GTextPolish.Values['Ir para linha'] := 'Przejdz do linii';
  GTextRomanian.Values['Ir para linha'] := 'Mergi la linie';
  GTextHungarian.Values['Ir para linha'] := 'Ugras sorra';
  GTextCzech.Values['Ir para linha'] := 'Prejit na radek';

  GTextPolish.Values['It is under development.'] := 'To jest w trakcie rozwoju.';
  GTextRomanian.Values['It is under development.'] := 'Este in dezvoltare.';
  GTextHungarian.Values['It is under development.'] := 'Fejlesztes alatt all.';
  GTextCzech.Values['It is under development.'] := 'Je ve vyvoji.';

  GTextPolish.Values['It will be removed from the list. Confirm ?'] := 'Zostanie usuniete z listy. Potwierdzic?';
  GTextRomanian.Values['It will be removed from the list. Confirm ?'] := 'Va fi sters din lista. Confirmati?';
  GTextHungarian.Values['It will be removed from the list. Confirm ?'] := 'A listabol torolve lesz. Megerosit?';
  GTextCzech.Values['It will be removed from the list. Confirm ?'] := 'Bude odstraneno ze seznamu. Potvrdit?';

  GTextPolish.Values['Line: %d  Col: %d'] := 'Linia: %d  Kol: %d';
  GTextRomanian.Values['Line: %d  Col: %d'] := 'Linie: %d  Col: %d';
  GTextHungarian.Values['Line: %d  Col: %d'] := 'Sor: %d  Oszlop: %d';
  GTextCzech.Values['Line: %d  Col: %d'] := 'Radek: %d  Sloupec: %d';

  GTextPolish.Values['Line: 0  Col: 0'] := 'Linia: 0  Kol: 0';
  GTextRomanian.Values['Line: 0  Col: 0'] := 'Linie: 0  Col: 0';
  GTextHungarian.Values['Line: 0  Col: 0'] := 'Sor: 0  Oszlop: 0';
  GTextCzech.Values['Line: 0  Col: 0'] := 'Radek: 0  Sloupec: 0';

  GTextPolish.Values['Lines: %d'] := 'Linii: %d';
  GTextRomanian.Values['Lines: %d'] := 'Linii: %d';
  GTextHungarian.Values['Lines: %d'] := 'Sorok: %d';
  GTextCzech.Values['Lines: %d'] := 'Radky: %d';

  GTextPolish.Values['List view uses: '] := 'Widok listy uzywa: ';
  GTextRomanian.Values['List view uses: '] := 'Lista foloseste: ';
  GTextHungarian.Values['List view uses: '] := 'Lista nezet hasznalja: ';
  GTextCzech.Values['List view uses: '] := 'Seznam pouziva: ';

  GTextPolish.Values['No match on current line.'] := 'Brak dopasowania w biezacej linii.';
  GTextRomanian.Values['No match on current line.'] := 'Nicio potrivire pe linia curenta.';
  GTextHungarian.Values['No match on current line.'] := 'Nincs talalat az aktualis sorban.';
  GTextCzech.Values['No match on current line.'] := 'Na aktualnim radku neni shoda.';

  GTextPolish.Values['No match selected. Use Find Next first.'] := 'Nie wybrano dopasowania. Najpierw Uzyj Znajdz Nastepne.';
  GTextRomanian.Values['No match selected. Use Find Next first.'] := 'Nu este selectata nicio potrivire. Folositi mai intai Gaseste urmatorul.';
  GTextHungarian.Values['No match selected. Use Find Next first.'] := 'Nincs kijelolt talalat. Elobb hasznald Kovetkezo keresese.';
  GTextCzech.Values['No match selected. Use Find Next first.'] := 'Neni vybrana zadna shoda. Nejprve pouzijte Najit dalsi.';

  GTextPolish.Values['Numero da linha (1..'] := 'Numer linii (od 1 do ';
  GTextRomanian.Values['Numero da linha (1..'] := 'Numar linie (de la 1 la ';
  GTextHungarian.Values['Numero da linha (1..'] := 'Sorszam (1-tol ';
  GTextCzech.Values['Numero da linha (1..'] := 'Cislo radku (od 1 do ';

  GTextPolish.Values['Please enter a search word.'] := 'Wpisz szukane slowo.';
  GTextRomanian.Values['Please enter a search word.'] := 'Introduceti un cuvant de cautare.';
  GTextHungarian.Values['Please enter a search word.'] := 'Adjon meg keresesi szot.';
  GTextCzech.Values['Please enter a search word.'] := 'Zadejte hledane slovo.';

  GTextPolish.Values['Please enter with file extension to exclude in the files search'] := 'Podaj rozszerzenie pliku do wykluczenia z wyszukiwania plikow';
  GTextRomanian.Values['Please enter with file extension to exclude in the files search'] := 'Introduceti extensia de fisier de exclus din cautare';
  GTextHungarian.Values['Please enter with file extension to exclude in the files search'] := 'Adja meg a kizarando fajlkiterjesztest a kereseshez';
  GTextCzech.Values['Please enter with file extension to exclude in the files search'] := 'Zadejte priponu souboru k vylouceni z hledani';

  GTextPolish.Values['Please enter with folder extension to exclude in the files search'] := 'Podaj rozszerzenie folderu do wykluczenia z wyszukiwania plikow';
  GTextRomanian.Values['Please enter with folder extension to exclude in the files search'] := 'Introduceti extensia folderului de exclus din cautare';
  GTextHungarian.Values['Please enter with folder extension to exclude in the files search'] := 'Adja meg a kizarando mappa kiterjesztest a kereseshez';
  GTextCzech.Values['Please enter with folder extension to exclude in the files search'] := 'Zadejte priponu slozky k vylouceni z hledani';

  GTextPolish.Values['Replace All'] := 'Zamien wszystko';
  GTextRomanian.Values['Replace All'] := 'Inlocuieste tot';
  GTextHungarian.Values['Replace All'] := 'Osszes csere';
  GTextCzech.Values['Replace All'] := 'Nahradit vse';

  GTextPolish.Values['Replace all occurrences of "'] := 'Zamien wszystkie wystapienia "';
  GTextRomanian.Values['Replace all occurrences of "'] := 'Inlocuieste toate aparitiile lui "';
  GTextHungarian.Values['Replace all occurrences of "'] := 'Csere minden elofordulasra: "';
  GTextCzech.Values['Replace all occurrences of "'] := 'Nahradit vsechny vyskyty "';

  GTextPolish.Values['Replaced on line'] := 'Zamieniono w linii';
  GTextRomanian.Values['Replaced on line'] := 'Inlocuit pe linia';
  GTextHungarian.Values['Replaced on line'] := 'Csere ezen a soron';
  GTextCzech.Values['Replaced on line'] := 'Nahrazeno na radku';

  GTextPolish.Values['Replaced on line '] := 'Zamieniono w linii ';
  GTextRomanian.Values['Replaced on line '] := 'Inlocuit pe linia ';
  GTextHungarian.Values['Replaced on line '] := 'Csere ezen a soron ';
  GTextCzech.Values['Replaced on line '] := 'Nahrazeno na radku ';

  GTextPolish.Values['Search'] := 'Szukaj';
  GTextRomanian.Values['Search'] := 'Cauta';
  GTextHungarian.Values['Search'] := 'Kereses';
  GTextCzech.Values['Search'] := 'Hledat';

  GTextPolish.Values['Shortcut:'] := 'Skrot:';
  GTextRomanian.Values['Shortcut:'] := 'Scurtatura:';
  GTextHungarian.Values['Shortcut:'] := 'Gyorsbillentyu:';
  GTextCzech.Values['Shortcut:'] := 'Zkratka:';

  GTextPolish.Values['Shortcut: '] := 'Skrot: ';
  GTextRomanian.Values['Shortcut: '] := 'Scurtatura: ';
  GTextHungarian.Values['Shortcut: '] := 'Gyorsbillentyu: ';
  GTextCzech.Values['Shortcut: '] := 'Zkratka: ';

  GTextPolish.Values['Show only lines containing:'] := 'Pokaz tylko linie zawierajace:';
  GTextRomanian.Values['Show only lines containing:'] := 'Afiseaza doar liniile care contin:';
  GTextHungarian.Values['Show only lines containing:'] := 'Csak az ezeket tartalmazo sorok:';
  GTextCzech.Values['Show only lines containing:'] := 'Zobrazit jen radky obsahujici:';

  GTextPolish.Values['This operation cannot be undone.'] := 'Tej operacji nie mozna cofnac.';
  GTextRomanian.Values['This operation cannot be undone.'] := 'Aceasta operatie nu poate fi anulata.';
  GTextHungarian.Values['This operation cannot be undone.'] := 'Ez a muvelet nem vonhato vissza.';
  GTextCzech.Values['This operation cannot be undone.'] := 'Tuto operaci nelze vratit zpet.';

  GTextPolish.Values['Type the text to search:'] := 'Wpisz tekst do wyszukania:';
  GTextRomanian.Values['Type the text to search:'] := 'Introduceti textul de cautat:';
  GTextHungarian.Values['Type the text to search:'] := 'Ird be a keresendo szoveget:';
  GTextCzech.Values['Type the text to search:'] := 'Zadejte hledany text:';

  GTextPolish.Values['Version History'] := 'Historia wersji';
  GTextPortuguesePT.Values['&Version History'] := '&Hist'#243'rico de vers'#245'es';
  GTextPortuguesePT.Values['Version History'] := 'Hist'#243'rico de vers'#245'es';
  GTextRomanian.Values['Version History'] := 'Istoric versiuni';
  GTextHungarian.Values['Version History'] := 'Verzio tortenet';
  GTextCzech.Values['Version History'] := 'Historie verzi';

  GTextPolish.Values['View: ANSI (raw / system)'] := 'Widok: ANSI (surowy / system)';
  GTextRomanian.Values['View: ANSI (raw / system)'] := 'Vizualizare: ANSI (raw / sistem)';
  GTextHungarian.Values['View: ANSI (raw / system)'] := 'Nezet: ANSI (nyers / rendszer)';
  GTextCzech.Values['View: ANSI (raw / system)'] := 'Zobrazeni: ANSI (raw / system)';

  GTextPolish.Values['View: DEFAULT (detected)'] := 'Widok: DOMYSLNY (wykryty)';
  GTextRomanian.Values['View: DEFAULT (detected)'] := 'Vizualizare: IMPLICIT (detectat)';
  GTextHungarian.Values['View: DEFAULT (detected)'] := 'Nezet: ALAPERTELMEZETT (eszlelve)';
  GTextCzech.Values['View: DEFAULT (detected)'] := 'Zobrazeni: VYCHOZI (detekovano)';

  GTextPolish.Values['View: UTF-16 BE'] := 'Widok: UTF-16 BE';
  GTextRomanian.Values['View: UTF-16 BE'] := 'Vizualizare: UTF-16 BE';
  GTextHungarian.Values['View: UTF-16 BE'] := 'Nezet: UTF-16 BE';
  GTextCzech.Values['View: UTF-16 BE'] := 'Zobrazeni: UTF-16 BE';

  GTextPolish.Values['View: UTF-16 LE'] := 'Widok: UTF-16 LE';
  GTextRomanian.Values['View: UTF-16 LE'] := 'Vizualizare: UTF-16 LE';
  GTextHungarian.Values['View: UTF-16 LE'] := 'Nezet: UTF-16 LE';
  GTextCzech.Values['View: UTF-16 LE'] := 'Zobrazeni: UTF-16 LE';

  GTextPolish.Values['View: UTF-8'] := 'Widok: UTF-8';
  GTextRomanian.Values['View: UTF-8'] := 'Vizualizare: UTF-8';
  GTextHungarian.Values['View: UTF-8'] := 'Nezet: UTF-8';
  GTextCzech.Values['View: UTF-8'] := 'Zobrazeni: UTF-8';
end;

{ --------------------------------------------------------------------------- }

procedure AddCommonTranslationsBaseLanguageOptions;
begin

  GEnglish.Values['status.system_ready'] := 'System Ready';
  GPortuguese.Values['status.system_ready'] := 'Sistema pronto';
  GSpanish.Values['status.system_ready'] := 'Sistema listo';
  GFrench.Values['status.system_ready'] := 'Syst'#232'me pr'#234't';
  GGerman.Values['status.system_ready'] := 'System bereit';
  GItalian.Values['status.system_ready'] := 'Sistema pronto';

  GEnglish.Values['popup.listview.read'] := 'Read';
  GPortuguese.Values['popup.listview.read'] := 'Ler';
  GSpanish.Values['popup.listview.read'] := 'Leer';
  GFrench.Values['popup.listview.read'] := 'Lire';
  GGerman.Values['popup.listview.read'] := 'Lesen';
  GItalian.Values['popup.listview.read'] := 'Leggi';

  GEnglish.Values['popup.listview.separator'] := '-';
  GPortuguese.Values['popup.listview.separator'] := '-';
  GSpanish.Values['popup.listview.separator'] := '-';
  GFrench.Values['popup.listview.separator'] := '-';
  GGerman.Values['popup.listview.separator'] := '-';
  GItalian.Values['popup.listview.separator'] := '-';

  GEnglish.Values['popup.listview.write'] := 'Write';
  GPortuguese.Values['popup.listview.write'] := 'Escrever';
  GSpanish.Values['popup.listview.write'] := 'Escribir';
  GFrench.Values['popup.listview.write'] := '#201'#233'crire';
  GGerman.Values['popup.listview.write'] := 'Schreiben';
  GItalian.Values['popup.listview.write'] := 'Scrivi';

  GEnglish.Values['popup.listview.split_files'] := 'Split Files';
  GPortuguese.Values['popup.listview.split_files'] := 'Dividir Arquivos';
  GSpanish.Values['popup.listview.split_files'] := 'Dividir Archivos';
  GFrench.Values['popup.listview.split_files'] := 'Diviser les fichiers';
  GGerman.Values['popup.listview.split_files'] := 'Dateien aufteilen';
  GItalian.Values['popup.listview.split_files'] := 'Dividi file';

  GEnglish.Values['popup.listview.show_checkboxes'] := 'Show CheckBoxes';
  GPortuguese.Values['popup.listview.show_checkboxes'] := 'Mostrar CheckBoxes';
  GSpanish.Values['popup.listview.show_checkboxes'] := 'Mostrar casillas';
  GFrench.Values['popup.listview.show_checkboxes'] := 'Afficher les cases';
  GGerman.Values['popup.listview.show_checkboxes'] := 'Kontrollk'#228'stchen anzeigen';
  GItalian.Values['popup.listview.show_checkboxes'] := 'Mostra caselle';

  GEnglish.Values['popup.listview.delete_lines'] := 'Delete Lines';
  GPortuguese.Values['popup.listview.delete_lines'] := 'Excluir Linhas';
  GSpanish.Values['popup.listview.delete_lines'] := 'Eliminar l'#237'neas';
  GFrench.Values['popup.listview.delete_lines'] := 'Supprimer les lignes';
  GGerman.Values['popup.listview.delete_lines'] := 'Zeilen l'#246'schen';
  GItalian.Values['popup.listview.delete_lines'] := 'Elimina righe';

  GEnglish.Values['popup.listview.clear'] := 'Clear';
  GPortuguese.Values['popup.listview.clear'] := 'Limpar';
  GSpanish.Values['popup.listview.clear'] := 'Limpiar';
  GFrench.Values['popup.listview.clear'] := 'Effacer';
  GGerman.Values['popup.listview.clear'] := 'Leeren';
  GItalian.Values['popup.listview.clear'] := 'Svuota';

  GEnglish.Values['popup.listview.export_clipboard'] := 'Export to Clipboard';
  GPortuguese.Values['popup.listview.export_clipboard'] := 'Exportar para a '#193'rea de Transfer'#234'ncia';
  GSpanish.Values['popup.listview.export_clipboard'] := 'Exportar al portapapeles';
  GFrench.Values['popup.listview.export_clipboard'] := 'Exporter dans le presse-papiers';
  GGerman.Values['popup.listview.export_clipboard'] := 'In die Zwischenablage exportieren';
  GItalian.Values['popup.listview.export_clipboard'] := 'Esporta negli appunti';

  GEnglish.Values['popup.listview.export_file'] := 'Export to File';
  GPortuguese.Values['popup.listview.export_file'] := 'Exportar para Arquivo';
  GSpanish.Values['popup.listview.export_file'] := 'Exportar a archivo';
  GFrench.Values['popup.listview.export_file'] := 'Exporter dans un fichier';
  GGerman.Values['popup.listview.export_file'] := 'In Datei exportieren';
  GItalian.Values['popup.listview.export_file'] := 'Esporta in file';

  GEnglish.Values['language.option.english'] := 'English';
  GPortuguese.Values['language.option.english'] := 'Ingl'#234's';
  GSpanish.Values['language.option.english'] := 'Ingl'#233's';
  GFrench.Values['language.option.english'] := 'Anglais';
  GGerman.Values['language.option.english'] := 'Englisch';
  GItalian.Values['language.option.english'] := 'Inglese';

  GEnglish.Values['language.option.portuguese_brazil'] := 'Portuguese (Brazil)';
  GPortuguese.Values['language.option.portuguese_brazil'] := 'Portugu'#234's (Brasil)';
  GSpanish.Values['language.option.portuguese_brazil'] := 'Portugu'#233's (Brasil)';
  GFrench.Values['language.option.portuguese_brazil'] := 'Portugais (Br'#233'sil)';
  GGerman.Values['language.option.portuguese_brazil'] := 'Portugiesisch (Brasilien)';
  GItalian.Values['language.option.portuguese_brazil'] := 'Portoghese (Brasile)';

  GEnglish.Values['language.option.spanish'] := 'Spanish';
  GPortuguese.Values['language.option.spanish'] := 'Espanhol';
  GSpanish.Values['language.option.spanish'] := 'Espa'#241'ol';
  GFrench.Values['language.option.spanish'] := 'Espagnol';
  GGerman.Values['language.option.spanish'] := 'Spanisch';
  GItalian.Values['language.option.spanish'] := 'Spagnolo';

  GEnglish.Values['language.option.french'] := 'French';
  GPortuguese.Values['language.option.french'] := 'Franc'#234's';
  GSpanish.Values['language.option.french'] := 'Franc'#233's';
  GFrench.Values['language.option.french'] := 'Fran'#231'ais';
  GGerman.Values['language.option.french'] := 'Franz'#246'sisch';
  GItalian.Values['language.option.french'] := 'Francese';

  GEnglish.Values['language.option.german'] := 'German';
  GPortuguese.Values['language.option.german'] := 'Alem'#227'o';
  GSpanish.Values['language.option.german'] := 'Alem'#225'n';
  GFrench.Values['language.option.german'] := 'Allemand';
  GGerman.Values['language.option.german'] := 'Deutsch';
  GItalian.Values['language.option.german'] := 'Tedesco';

  GEnglish.Values['language.option.italian'] := 'Italian';
  GPortuguese.Values['language.option.italian'] := 'Italiano';
  GSpanish.Values['language.option.italian'] := 'Italiano';
  GFrench.Values['language.option.italian'] := 'Italien';
  GGerman.Values['language.option.italian'] := 'Italienisch';
  GItalian.Values['language.option.italian'] := 'Italiano';
end;

procedure AddCommonTranslationsNewLanguageOptions;
begin
  GEnglish.Values['language.option.polish']            := 'Polish';
  GPortuguese.Values['language.option.polish']         := 'Polon'#234's';
  GSpanish.Values['language.option.polish']            := 'Polaco';
  GFrench.Values['language.option.polish']             := 'Polonais';
  GGerman.Values['language.option.polish']             := 'Polnisch';
  GItalian.Values['language.option.polish']            := 'Polacco';
  GPolish.Values['language.option.polish']             := 'Polski';
  GPortuguesePT.Values['language.option.polish']       := 'Polon'#234's';
  GRomanian.Values['language.option.polish']           := 'Polonez'#227;
  GHungarian.Values['language.option.polish']          := 'Lengyel';
  GCzech.Values['language.option.polish']              := 'Polsk'#253;

  GEnglish.Values['language.option.portuguese_portugal']      := 'Portuguese (Portugal)';
  GPortuguese.Values['language.option.portuguese_portugal']   := 'Portugu'#234's (Portugal)';
  GSpanish.Values['language.option.portuguese_portugal']      := 'Portugu'#233's (Portugal)';
  GFrench.Values['language.option.portuguese_portugal']       := 'Portugais (Portugal)';
  GGerman.Values['language.option.portuguese_portugal']       := 'Portugiesisch (Portugal)';
  GItalian.Values['language.option.portuguese_portugal']      := 'Portoghese (Portogallo)';
  GPolish.Values['language.option.portuguese_portugal']       := 'Portugalski';
  GPortuguesePT.Values['language.option.portuguese_portugal'] := 'Portugu'#234's (Portugal)';
  GRomanian.Values['language.option.portuguese_portugal']     := 'Portughez'#227' (Portugalia)';
  GHungarian.Values['language.option.portuguese_portugal']    := 'Portug'#225'l (Portug'#225'lia)';
  GCzech.Values['language.option.portuguese_portugal']        := 'Portugalsk'#253;

  GEnglish.Values['language.option.romanian']      := 'Romanian';
  GPortuguese.Values['language.option.romanian']   := 'Romeno';
  GSpanish.Values['language.option.romanian']      := 'Rumano';
  GFrench.Values['language.option.romanian']       := 'Roumain';
  GGerman.Values['language.option.romanian']       := 'Rum'#228'nisch';
  GItalian.Values['language.option.romanian']      := 'Rumeno';
  GPolish.Values['language.option.romanian']       := 'Rumu'#241'ski';
  GPortuguesePT.Values['language.option.romanian'] := 'Romeno';
  GRomanian.Values['language.option.romanian']     := 'Rom'#226'n'#227'';
  GHungarian.Values['language.option.romanian']    := 'Rom'#225'n';
  GCzech.Values['language.option.romanian']        := 'Rumunsk'#253;

  GEnglish.Values['language.option.hungarian']      := 'Hungarian';
  GPortuguese.Values['language.option.hungarian']   := 'H'#250'ngaro';
  GSpanish.Values['language.option.hungarian']      := 'H'#250'ngaro';
  GFrench.Values['language.option.hungarian']       := 'Hongrois';
  GGerman.Values['language.option.hungarian']       := 'Ungarisch';
  GItalian.Values['language.option.hungarian']      := 'Ungherese';
  GPolish.Values['language.option.hungarian']       := 'W'#234'gierski';
  GPortuguesePT.Values['language.option.hungarian'] := 'H'#250'ngaro';
  GRomanian.Values['language.option.hungarian']     := 'Maghiar'#227'';
  GHungarian.Values['language.option.hungarian']    := 'Magyar';
  GCzech.Values['language.option.hungarian']        := 'Ma'#239'arsk'#253;

  GEnglish.Values['language.option.czech']      := 'Czech';
  GPortuguese.Values['language.option.czech']   := 'Tcheco';
  GSpanish.Values['language.option.czech']      := 'Checo';
  GFrench.Values['language.option.czech']       := 'Tch'#232'que';
  GGerman.Values['language.option.czech']       := 'Tschechisch';
  GItalian.Values['language.option.czech']      := 'Ceco';
  GPolish.Values['language.option.czech']       := 'Czeski';
  GPortuguesePT.Values['language.option.czech'] := 'Checo';
  GRomanian.Values['language.option.czech']     := 'Ceh'#227'';
  GHungarian.Values['language.option.czech']    := 'Cseh';
  GCzech.Values['language.option.czech']        := #200'e'#154'tina';
end;

procedure AddCommonTranslationsLateDialogsAndFolders;
begin
  { --- Folders Exclude tab: grid column headers and action buttons --------}
  GTextPortuguese.Values['Folders']          := 'Pastas';
  GTextSpanish.Values['Folders']             := 'Carpetas';
  GTextFrench.Values['Folders']              := 'Dossiers';
  GTextGerman.Values['Folders']              := 'Ordner';
  GTextItalian.Values['Folders']             := 'Cartelle';

  GTextPortuguese.Values['Files']            := 'Arquivos';
  GTextSpanish.Values['Files']               := 'Archivos';
  GTextFrench.Values['Files']                := 'Fichiers';
  GTextGerman.Values['Files']                := 'Dateien';
  GTextItalian.Values['Files']               := 'File';

  GTextPortuguese.Values['Insert from prompt'] := 'Inserir via prompt';
  GTextSpanish.Values['Insert from prompt']    := 'Insertar desde aviso';
  GTextFrench.Values['Insert from prompt']     := 'Ins'#233'rer via invite';
  GTextGerman.Values['Insert from prompt']     := 'Per Eingabe einf'#252'gen';
  GTextItalian.Values['Insert from prompt']    := 'Inserisci da prompt';

  GTextPortuguese.Values['Delete']           := 'Excluir';
  GTextSpanish.Values['Delete']              := 'Eliminar';
  GTextFrench.Values['Delete']               := 'Supprimer';
  GTextGerman.Values['Delete']               := 'L'#246'schen';
  GTextItalian.Values['Delete']              := 'Elimina';

  { --- Line editor operations -------------------------------------------- }
  GTextEnglish.Values['Duplicate Line']    := 'Duplicate Line';
  GTextPortuguese.Values['Duplicate Line'] := 'Duplicar linha';
  GTextSpanish.Values['Duplicate Line']    := 'Duplicar l'#237'nea';
  GTextFrench.Values['Duplicate Line']     := 'Dupliquer la ligne';
  GTextGerman.Values['Duplicate Line']     := 'Zeile duplizieren';
  GTextItalian.Values['Duplicate Line']    := 'Duplica riga';

  { --- Delete confirmation dialog ----------------------------------------- }
  GTextEnglish.Values['It will be removed from the list. Confirm ?']    := 'It will be removed from the list. Confirm ?';
  GTextPortuguese.Values['It will be removed from the list. Confirm ?'] := 'Ser'#225' removido da lista. Confirmar?';
  GTextSpanish.Values['It will be removed from the list. Confirm ?']    := 'Ser'#225' eliminado de la lista. '#191'Confirmar?';
  GTextFrench.Values['It will be removed from the list. Confirm ?']     := 'Il sera supprim'#233' de la liste. Confirmer?';
  GTextGerman.Values['It will be removed from the list. Confirm ?']     := 'Wird aus der Liste entfernt. Best'#228'tigen?';
  GTextItalian.Values['It will be removed from the list. Confirm ?']    := 'Sar'#224' rimosso dall''elenco. Confermare?';

  GTextEnglish.Values['Delete confirmation']    := 'Delete confirmation';
  GTextPortuguese.Values['Delete confirmation'] := 'Confirma'#231#227'o de exclus'#227'o';
  GTextSpanish.Values['Delete confirmation']    := 'Confirmaci'#243'n de eliminaci'#243'n';
  GTextFrench.Values['Delete confirmation']     := 'Confirmation de suppression';
  GTextGerman.Values['Delete confirmation']     := 'L'#246'schbest'#228'tigung';
  GTextItalian.Values['Delete confirmation']    := 'Conferma eliminazione';

  { --- Import file extensions dialog -------------------------------------- }
  GTextEnglish.Values['Importing file extensions to exclude from search']    := 'Importing file extensions to exclude from search';
  GTextPortuguese.Values['Importing file extensions to exclude from search'] := 'Importar extens'#245'es de arquivo para excluir da busca';
  GTextSpanish.Values['Importing file extensions to exclude from search']    := 'Importar extensiones de archivo para excluir de la b'#250'squeda';
  GTextFrench.Values['Importing file extensions to exclude from search']     := 'Importer des extensions de fichier '#224' exclure de la recherche';
  GTextGerman.Values['Importing file extensions to exclude from search']     := 'Dateiendungen f'#252'r Ausschluss importieren';
  GTextItalian.Values['Importing file extensions to exclude from search']    := 'Importa estensioni file da escludere dalla ricerca';

  GTextEnglish.Values['Import file extensions']    := 'Import file extensions';
  GTextPortuguese.Values['Import file extensions'] := 'Importar extens'#245'es';
  GTextSpanish.Values['Import file extensions']    := 'Importar extensiones';
  GTextFrench.Values['Import file extensions']     := 'Importer extensions';
  GTextGerman.Values['Import file extensions']     := 'Endungen importieren';
  GTextItalian.Values['Import file extensions']    := 'Importa estensioni';

  GTextEnglish.Values['Import']    := 'Import';
  GTextPortuguese.Values['Import'] := 'Importar';
  GTextSpanish.Values['Import']    := 'Importar';
  GTextFrench.Values['Import']     := 'Importer';
  GTextGerman.Values['Import']     := 'Importieren';
  GTextItalian.Values['Import']    := 'Importa';

  GTextEnglish.Values['Operation cancelled.']    := 'Operation cancelled.';
  GTextPortuguese.Values['Operation cancelled.'] := 'Opera'#231#227'o cancelada.';
  GTextSpanish.Values['Operation cancelled.']    := 'Operaci'#243'n cancelada.';
  GTextFrench.Values['Operation cancelled.']     := 'Op'#233'ration annul'#233'e.';
  GTextGerman.Values['Operation cancelled.']     := 'Vorgang abgebrochen.';
  GTextItalian.Values['Operation cancelled.']    := 'Operazione annullata.';

  { --- Merge files (file-in-file) ---------------------------------------- }
  GTextEnglish.Values['Merge &files...'] := 'Merge &files...';
  GTextPortuguese.Values['Merge &files...'] := 'Mesclar &arquivos...';
  GTextSpanish.Values['Merge &files...'] := 'Combinar &archivos...';
  GTextFrench.Values['Merge &files...'] := 'Fusionner &fichiers...';
  GTextGerman.Values['Merge &files...'] := '&Dateien zusammenfuehren...';
  GTextItalian.Values['Merge &files...'] := 'Unisci &file...';

  GTextEnglish.Values['Merge files'] := 'Merge files';
  GTextPortuguese.Values['Merge files'] := 'Mesclar arquivos';
  GTextSpanish.Values['Merge files'] := 'Combinar archivos';
  GTextFrench.Values['Merge files'] := 'Fusionner les fichiers';
  GTextGerman.Values['Merge files'] := 'Dateien zusammenfuehren';
  GTextItalian.Values['Merge files'] := 'Unisci file';

  GTextEnglish.Values['Destination file (current):'] := 'Destination file (current):';
  GTextPortuguese.Values['Destination file (current):'] := 'Arquivo de destino (atual):';
  GTextSpanish.Values['Destination file (current):'] := 'Archivo de destino (actual):';
  GTextFrench.Values['Destination file (current):'] := 'Fichier de destination (actuel) :';
  GTextGerman.Values['Destination file (current):'] := 'Zieldatei (aktuell):';
  GTextItalian.Values['Destination file (current):'] := 'File di destinazione (corrente):';

  GTextEnglish.Values['Source file (type path or use picker):'] := 'Source file (type path or use picker):';
  GTextPortuguese.Values['Source file (type path or use picker):'] := 'Arquivo de origem (digite o caminho ou use o seletor):';
  GTextSpanish.Values['Source file (type path or use picker):'] := 'Archivo de origen (escriba la ruta o use el selector):';
  GTextFrench.Values['Source file (type path or use picker):'] := 'Fichier source (saisissez le chemin ou utilisez le selecteur) :';
  GTextGerman.Values['Source file (type path or use picker):'] := 'Quelldatei (Pfad eingeben oder Dateiauswahl nutzen):';
  GTextItalian.Values['Source file (type path or use picker):'] := 'File sorgente (digita il percorso o usa il selettore):';

  GTextEnglish.Values['All files (*.*)|*.*'] := 'All files (*.*)|*.*';
  GTextPortuguese.Values['All files (*.*)|*.*'] := 'Todos os arquivos (*.*)|*.*';
  GTextSpanish.Values['All files (*.*)|*.*'] := 'Todos los archivos (*.*)|*.*';
  GTextFrench.Values['All files (*.*)|*.*'] := 'Tous les fichiers (*.*)|*.*';
  GTextGerman.Values['All files (*.*)|*.*'] := 'Alle Dateien (*.*)|*.*';
  GTextItalian.Values['All files (*.*)|*.*'] := 'Tutti i file (*.*)|*.*';

  GTextEnglish.Values['Merge mode'] := 'Merge mode';
  GTextPortuguese.Values['Merge mode'] := 'Modo de mesclagem';
  GTextSpanish.Values['Merge mode'] := 'Modo de combinacion';
  GTextFrench.Values['Merge mode'] := 'Mode de fusion';
  GTextGerman.Values['Merge mode'] := 'Zusammenfuehrungsmodus';
  GTextItalian.Values['Merge mode'] := 'Modalita di unione';

  GTextEnglish.Values['Insert source at beginning (first line).'] := 'Insert source at beginning (first line).';
  GTextPortuguese.Values['Insert source at beginning (first line).'] := 'Inserir origem no inicio (primeira linha).';
  GTextSpanish.Values['Insert source at beginning (first line).'] := 'Insertar origen al inicio (primera linea).';
  GTextFrench.Values['Insert source at beginning (first line).'] := 'Inserer la source au debut (premiere ligne).';
  GTextGerman.Values['Insert source at beginning (first line).'] := 'Quelle am Anfang einfuegen (erste Zeile).';
  GTextItalian.Values['Insert source at beginning (first line).'] := 'Inserisci origine all''inizio (prima riga).';

  GTextEnglish.Values['Insert source after destination line:'] := 'Insert source after destination line:';
  GTextPortuguese.Values['Insert source after destination line:'] := 'Inserir origem apos a linha do destino:';
  GTextSpanish.Values['Insert source after destination line:'] := 'Insertar origen despues de la linea de destino:';
  GTextFrench.Values['Insert source after destination line:'] := 'Inserer la source apres la ligne de destination :';
  GTextGerman.Values['Insert source after destination line:'] := 'Quelle nach Zielzeile einfuegen:';
  GTextItalian.Values['Insert source after destination line:'] := 'Inserisci origine dopo la riga di destinazione:';

  GTextEnglish.Values['Insert source at end of destination file.'] := 'Insert source at end of destination file.';
  GTextPortuguese.Values['Insert source at end of destination file.'] := 'Inserir origem no final do arquivo de destino.';
  GTextSpanish.Values['Insert source at end of destination file.'] := 'Insertar origen al final del archivo de destino.';
  GTextFrench.Values['Insert source at end of destination file.'] := 'Inserer la source a la fin du fichier de destination.';
  GTextGerman.Values['Insert source at end of destination file.'] := 'Quelle am Ende der Zieldatei einfuegen.';
  GTextItalian.Values['Insert source at end of destination file.'] := 'Inserisci origine alla fine del file di destinazione.';

  GTextEnglish.Values['Line number (valid range: 1..totalLines-1):'] := 'Line number (valid range: 1 to total lines - 1):';
  GTextPortuguese.Values['Line number (valid range: 1..totalLines-1):'] := 'Numero da linha (intervalo valido: 1 a total de linhas - 1):';
  GTextSpanish.Values['Line number (valid range: 1..totalLines-1):'] := 'Numero de linea (rango valido: 1 a total de lineas - 1):';
  GTextFrench.Values['Line number (valid range: 1..totalLines-1):'] := 'Numero de ligne (intervalle valide : 1 a total des lignes - 1) :';
  GTextGerman.Values['Line number (valid range: 1..totalLines-1):'] := 'Zeilennummer (gueltiger Bereich: 1 bis Gesamtzeilen - 1):';
  GTextItalian.Values['Line number (valid range: 1..totalLines-1):'] := 'Numero riga (intervallo valido: da 1 a totale righe - 1):';
  GTextPolish.Values['Line number (valid range: 1..totalLines-1):'] := 'Numer linii (prawidlowy zakres: od 1 do laczna liczba linii - 1):';
  GTextRomanian.Values['Line number (valid range: 1..totalLines-1):'] := 'Numar linie (interval valid: de la 1 la total linii - 1):';
  GTextHungarian.Values['Line number (valid range: 1..totalLines-1):'] := 'Sorszam (ervenyes tartomany: 1-tol sorok osszesen - 1-ig):';
  GTextCzech.Values['Line number (valid range: 1..totalLines-1):'] := 'Cislo radku (platny rozsah: 1 az celkovy pocet radku - 1):';
  GTextPortuguesePT.Values['Line number (valid range: 1..totalLines-1):'] := 'Numero da linha (intervalo valido: 1 a total de linhas - 1):';

  GTextEnglish.Values['Tip: press ESC to cancel.'] := 'Tip: press ESC to cancel.';
  GTextPortuguese.Values['Tip: press ESC to cancel.'] := 'Dica: pressione ESC para cancelar.';
  GTextSpanish.Values['Tip: press ESC to cancel.'] := 'Sugerencia: presione ESC para cancelar.';
  GTextFrench.Values['Tip: press ESC to cancel.'] := 'Astuce : appuyez sur ESC pour annuler.';
  GTextGerman.Values['Tip: press ESC to cancel.'] := 'Tipp: ESC druecken, um abzubrechen.';
  GTextItalian.Values['Tip: press ESC to cancel.'] := 'Suggerimento: premi ESC per annullare.';

  GTextEnglish.Values['You can drag and drop the source file into this window.'] := 'You can drag and drop the source file into this window.';
  GTextPortuguese.Values['You can drag and drop the source file into this window.'] := 'Voce pode arrastar e soltar o arquivo de origem nesta janela.';
  GTextSpanish.Values['You can drag and drop the source file into this window.'] := 'Puede arrastrar y soltar el archivo de origen en esta ventana.';
  GTextFrench.Values['You can drag and drop the source file into this window.'] := 'Vous pouvez glisser-deposer le fichier source dans cette fenetre.';
  GTextGerman.Values['You can drag and drop the source file into this window.'] := 'Sie koennen die Quelldatei in dieses Fenster ziehen und ablegen.';
  GTextItalian.Values['You can drag and drop the source file into this window.'] := 'Puoi trascinare e rilasciare il file sorgente in questa finestra.';

  GTextEnglish.Values['Confirm'] := 'Confirm';
  GTextPortuguese.Values['Confirm'] := 'Confirmar';
  GTextSpanish.Values['Confirm'] := 'Confirmar';
  GTextFrench.Values['Confirm'] := 'Confirmer';
  GTextGerman.Values['Confirm'] := 'Bestaetigen';
  GTextItalian.Values['Confirm'] := 'Conferma';

  GTextEnglish.Values['Please select/read the destination file first.'] := 'Please select/read the destination file first.';
  GTextPortuguese.Values['Please select/read the destination file first.'] := 'Selecione/leia primeiro o arquivo de destino.';
  GTextSpanish.Values['Please select/read the destination file first.'] := 'Seleccione/lea primero el archivo de destino.';
  GTextFrench.Values['Please select/read the destination file first.'] := 'Selectionnez/lisez d''abord le fichier de destination.';
  GTextGerman.Values['Please select/read the destination file first.'] := 'Bitte zuerst die Zieldatei auswaehlen/einlesen.';
  GTextItalian.Values['Please select/read the destination file first.'] := 'Seleziona/leggi prima il file di destinazione.';

  GTextEnglish.Values['Destination file not found.'] := 'Destination file not found.';
  GTextPortuguese.Values['Destination file not found.'] := 'Arquivo de destino nao encontrado.';
  GTextSpanish.Values['Destination file not found.'] := 'Archivo de destino no encontrado.';
  GTextFrench.Values['Destination file not found.'] := 'Fichier de destination introuvable.';
  GTextGerman.Values['Destination file not found.'] := 'Zieldatei nicht gefunden.';
  GTextItalian.Values['Destination file not found.'] := 'File di destinazione non trovato.';

  GTextEnglish.Values['Source file is required.'] := 'Source file is required.';
  GTextPortuguese.Values['Source file is required.'] := 'Arquivo de origem e obrigatorio.';
  GTextSpanish.Values['Source file is required.'] := 'El archivo de origen es obligatorio.';
  GTextFrench.Values['Source file is required.'] := 'Le fichier source est obligatoire.';
  GTextGerman.Values['Source file is required.'] := 'Quelldatei ist erforderlich.';
  GTextItalian.Values['Source file is required.'] := 'Il file sorgente e obbligatorio.';

  GTextEnglish.Values['Source file not found.'] := 'Source file not found.';
  GTextPortuguese.Values['Source file not found.'] := 'Arquivo de origem nao encontrado.';
  GTextSpanish.Values['Source file not found.'] := 'Archivo de origen no encontrado.';
  GTextFrench.Values['Source file not found.'] := 'Fichier source introuvable.';
  GTextGerman.Values['Source file not found.'] := 'Quelldatei nicht gefunden.';
  GTextItalian.Values['Source file not found.'] := 'File sorgente non trovato.';

  GTextEnglish.Values['Source and destination files must be different.'] := 'Source and destination files must be different.';
  GTextPortuguese.Values['Source and destination files must be different.'] := 'Arquivos de origem e destino devem ser diferentes.';
  GTextSpanish.Values['Source and destination files must be different.'] := 'Los archivos de origen y destino deben ser diferentes.';
  GTextFrench.Values['Source and destination files must be different.'] := 'Les fichiers source et destination doivent etre differents.';
  GTextGerman.Values['Source and destination files must be different.'] := 'Quell- und Zieldatei muessen unterschiedlich sein.';
  GTextItalian.Values['Source and destination files must be different.'] := 'I file sorgente e destinazione devono essere diversi.';

  GTextEnglish.Values['Could not open source file: '] := 'Could not open source file: ';
  GTextPortuguese.Values['Could not open source file: '] := 'Nao foi possivel abrir o arquivo de origem: ';
  GTextSpanish.Values['Could not open source file: '] := 'No se pudo abrir el archivo de origen: ';
  GTextFrench.Values['Could not open source file: '] := 'Impossible d''ouvrir le fichier source : ';
  GTextGerman.Values['Could not open source file: '] := 'Quelldatei konnte nicht geoeffnet werden: ';
  GTextItalian.Values['Could not open source file: '] := 'Impossibile aprire il file sorgente: ';

  GTextEnglish.Values['Destination file is in use by another process: '] := 'Destination file is in use by another process: ';
  GTextPortuguese.Values['Destination file is in use by another process: '] := 'Arquivo de destino esta em uso por outro processo: ';
  GTextSpanish.Values['Destination file is in use by another process: '] := 'El archivo de destino esta en uso por otro proceso: ';
  GTextFrench.Values['Destination file is in use by another process: '] := 'Le fichier de destination est utilise par un autre processus : ';
  GTextGerman.Values['Destination file is in use by another process: '] := 'Zieldatei wird von einem anderen Prozess verwendet: ';
  GTextItalian.Values['Destination file is in use by another process: '] := 'Il file di destinazione e in uso da un altro processo: ';

  GTextEnglish.Values['Destination file must have at least 2 lines for insertion by line.'] := 'Destination file must have at least 2 lines for insertion by line.';
  GTextPortuguese.Values['Destination file must have at least 2 lines for insertion by line.'] := 'Arquivo de destino deve ter ao menos 2 linhas para insercao por linha.';
  GTextSpanish.Values['Destination file must have at least 2 lines for insertion by line.'] := 'El archivo de destino debe tener al menos 2 lineas para insercion por linea.';
  GTextFrench.Values['Destination file must have at least 2 lines for insertion by line.'] := 'Le fichier de destination doit avoir au moins 2 lignes pour une insertion por ligne.';
  GTextGerman.Values['Destination file must have at least 2 lines for insertion by line.'] := 'Die Zieldatei muss mindestens 2 Zeilen fuer zeilenbasiertes Einfuegen haben.';
  GTextItalian.Values['Destination file must have at least 2 lines for insertion by line.'] := 'Il file di destinazione deve avere almeno 2 righe per inserimento per riga.';

  GTextEnglish.Values['Invalid line. Use a value from %d to %d.'] := 'Invalid line. Use a value from %d to %d.';
  GTextPortuguese.Values['Invalid line. Use a value from %d to %d.'] := 'Linha invalida. Use um valor de %d a %d.';
  GTextSpanish.Values['Invalid line. Use a value from %d to %d.'] := 'Linea invalida. Use un valor de %d a %d.';
  GTextFrench.Values['Invalid line. Use a value from %d to %d.'] := 'Ligne invalide. Utilisez une valeur entre %d et %d.';
  GTextGerman.Values['Invalid line. Use a value from %d to %d.'] := 'Ungueltige Zeile. Verwenden Sie einen Wert von %d bis %d.';
  GTextItalian.Values['Invalid line. Use a value from %d to %d.'] := 'Riga non valida. Usa un valore da %d a %d.';
  GTextPolish.Values['Invalid line. Use a value from %d to %d.'] := 'Nieprawidlowa linia. Uzyj wartosci od %d do %d.';
  GTextRomanian.Values['Invalid line. Use a value from %d to %d.'] := 'Linie invalida. Folositi o valoare de la %d la %d.';
  GTextHungarian.Values['Invalid line. Use a value from %d to %d.'] := 'Ervenytelen sor. Hasznaljon %d es %d kozotti erteket.';
  GTextCzech.Values['Invalid line. Use a value from %d to %d.'] := 'Neplatny radek. Pouzijte hodnotu od %d do %d.';
  GTextPortuguesePT.Values['Invalid line. Use a value from %d to %d.'] := 'Linha invalida. Use um valor de %d a %d.';

  GTextEnglish.Values['Could not resolve insertion position. Read destination file again and retry.'] := 'Could not resolve insertion position. Read destination file again and retry.';
  GTextPortuguese.Values['Could not resolve insertion position. Read destination file again and retry.'] := 'Nao foi possivel resolver a posicao de insercao. Leia novamente o arquivo de destino e tente de novo.';
  GTextSpanish.Values['Could not resolve insertion position. Read destination file again and retry.'] := 'No se pudo resolver la posicion de insercion. Lea de nuevo el archivo de destino e intente otra vez.';
  GTextFrench.Values['Could not resolve insertion position. Read destination file again and retry.'] := 'Impossible de determiner la position d''insertion. Relisez le fichier destination et reessayez.';
  GTextGerman.Values['Could not resolve insertion position. Read destination file again and retry.'] := 'Einfuegeposition konnte nicht bestimmt werden. Zieldatei erneut einlesen und erneut versuchen.';
  GTextItalian.Values['Could not resolve insertion position. Read destination file again and retry.'] := 'Impossibile determinare la posizione di inserimento. Rileggi il file di destinazione e riprova.';

  GTextEnglish.Values['Merging files...'] := 'Merging files...';
  GTextPortuguese.Values['Merging files...'] := 'Mesclando arquivos...';
  GTextSpanish.Values['Merging files...'] := 'Combinando archivos...';
  GTextFrench.Values['Merging files...'] := 'Fusion des fichiers...';
  GTextGerman.Values['Merging files...'] := 'Dateien werden zusammengefuehrt...';
  GTextItalian.Values['Merging files...'] := 'Unione file in corso...';

  GTextEnglish.Values['Merge files error: '] := 'Merge files error: ';
  GTextPortuguese.Values['Merge files error: '] := 'Erro ao mesclar arquivos: ';
  GTextSpanish.Values['Merge files error: '] := 'Error al combinar archivos: ';
  GTextFrench.Values['Merge files error: '] := 'Erreur de fusion des fichiers : ';
  GTextGerman.Values['Merge files error: '] := 'Fehler beim Zusammenfuehren von Dateien: ';
  GTextItalian.Values['Merge files error: '] := 'Errore unione file: ';

  GTextEnglish.Values['Merge files completed in: %s millisecs.'] := 'Merge files completed in: %s millisecs.';
  GTextPortuguese.Values['Merge files completed in: %s millisecs.'] := 'Mesclagem de arquivos concluida em: %s millisecs.';
  GTextSpanish.Values['Merge files completed in: %s millisecs.'] := 'Combinacion de archivos finalizada en: %s millisecs.';
  GTextFrench.Values['Merge files completed in: %s millisecs.'] := 'Fusion des fichiers terminee en : %s millisecs.';
  GTextGerman.Values['Merge files completed in: %s millisecs.'] := 'Dateien wurden in %s millisecs. zusammengefuehrt.';
  GTextItalian.Values['Merge files completed in: %s millisecs.'] := 'Unione file completata in: %s millisecs.';
  GTextPolish.Values['Merge files completed in: %s millisecs.'] := 'Polaczanie plikow zakonczylo sie w: %s millisecs.';
  GTextRomanian.Values['Merge files completed in: %s millisecs.'] := 'Fuziunea fisierelor finalizata in: %s millisecs.';
  GTextHungarian.Values['Merge files completed in: %s millisecs.'] := 'Fajlok osszefuzese befejezodott: %s millisecs.';
  GTextCzech.Values['Merge files completed in: %s millisecs.'] := 'Slucovani souboru dokonceno za: %s millisecs.';
  GTextPortuguesePT.Values['Merge files completed in: %s millisecs.'] := 'Mesclagem de ficheiros concluida em: %s millisecs.';

  { --- Split file into equal parts (byte targets + LF boundaries) ---------- }
  GTextEnglish.Values['Split file into e&qual parts...'] := 'Split file into e&qual parts...';
  GTextPortuguese.Values['Split file into e&qual parts...'] := 'Dividir arquivo em partes &iguais...';
  GTextSpanish.Values['Split file into e&qual parts...'] := 'Dividir archivo en partes &iguales...';
  GTextFrench.Values['Split file into e&qual parts...'] := 'Diviser le fichier en parties &egales...';
  GTextGerman.Values['Split file into e&qual parts...'] := 'Datei in &gleich grosse Teile teilen...';
  GTextItalian.Values['Split file into e&qual parts...'] := 'Dividi file in parti &uguali...';
  GTextPolish.Values['Split file into e&qual parts...'] := 'Podziel plik na &rowne czesci...';
  GTextPortuguesePT.Values['Split file into e&qual parts...'] := 'Dividir ficheiro em partes &iguais...';
  GTextRomanian.Values['Split file into e&qual parts...'] := 'Imparte fisierul in parti &egale...';
  GTextHungarian.Values['Split file into e&qual parts...'] := 'Fajl felosztasa egyenlo reszekre...';
  GTextCzech.Values['Split file into e&qual parts...'] := 'Rozdelit soubor na stejne &casti...';

  GTextEnglish.Values['Split file into equal parts'] := 'Split file into equal parts';
  GTextPortuguese.Values['Split file into equal parts'] := 'Dividir arquivo em partes iguais';
  GTextSpanish.Values['Split file into equal parts'] := 'Dividir archivo en partes iguales';
  GTextFrench.Values['Split file into equal parts'] := 'Diviser le fichier en parties egales';
  GTextGerman.Values['Split file into equal parts'] := 'Datei in gleich grosse Teile teilen';
  GTextItalian.Values['Split file into equal parts'] := 'Dividi file in parti uguali';
  GTextPolish.Values['Split file into equal parts'] := 'Podziel plik na rowne czesci';
  GTextPortuguesePT.Values['Split file into equal parts'] := 'Dividir ficheiro em partes iguais';
  GTextRomanian.Values['Split file into equal parts'] := 'Imparte fisierul in parti egale';
  GTextHungarian.Values['Split file into equal parts'] := 'Fajl felosztasa egyenlo reszekre';
  GTextCzech.Values['Split file into equal parts'] := 'Rozdelit soubor na stejne casti';

  GTextEnglish.Values['Source file to split (path or picker):'] := 'Source file to split (path or picker):';
  GTextPortuguese.Values['Source file to split (path or picker):'] := 'Arquivo de origem a dividir (caminho ou seletor):';
  GTextSpanish.Values['Source file to split (path or picker):'] := 'Archivo de origen a dividir (ruta o selector):';
  GTextFrench.Values['Source file to split (path or picker):'] := 'Fichier source a diviser (chemin ou selecteur) :';
  GTextGerman.Values['Source file to split (path or picker):'] := 'Zu teilende Quelldatei (Pfad oder Auswahl):';
  GTextItalian.Values['Source file to split (path or picker):'] := 'File sorgente da dividere (percorso o selettore):';
  GTextPolish.Values['Source file to split (path or picker):'] := 'Plik zrodlowy do podzialu (sciezka lub wybierz):';
  GTextPortuguesePT.Values['Source file to split (path or picker):'] := 'Ficheiro de origem a dividir (caminho ou seletor):';
  GTextRomanian.Values['Source file to split (path or picker):'] := 'Fisier sursa de impartit (cale sau selector):';
  GTextHungarian.Values['Source file to split (path or picker):'] := 'Felosztando forrasfajl (utvonal vagy tallozo):';
  GTextCzech.Values['Source file to split (path or picker):'] := 'Zdrojovy soubor k rozdeleni (cesta nebo dialog):';

  GTextEnglish.Values['Number of parts (2..1000):'] := 'Number of parts (2..1000):';
  GTextPortuguese.Values['Number of parts (2..1000):'] := 'Numero de partes (2..1000):';
  GTextSpanish.Values['Number of parts (2..1000):'] := 'Numero de partes (2..1000):';
  GTextFrench.Values['Number of parts (2..1000):'] := 'Nombre de parties (2..1000) :';
  GTextGerman.Values['Number of parts (2..1000):'] := 'Anzahl der Teile (2..1000):';
  GTextItalian.Values['Number of parts (2..1000):'] := 'Numero di parti (2..1000):';
  GTextPolish.Values['Number of parts (2..1000):'] := 'Liczba czesci (2..1000):';
  GTextPortuguesePT.Values['Number of parts (2..1000):'] := 'Numero de partes (2..1000):';
  GTextRomanian.Values['Number of parts (2..1000):'] := 'Numar de parti (2..1000):';
  GTextHungarian.Values['Number of parts (2..1000):'] := 'Reszek szama (2..1000):';
  GTextCzech.Values['Number of parts (2..1000):'] := 'Pocet casti (2..1000):';

  GTextEnglish.Values['Parts are sized evenly by bytes; each part ends only after a complete line (LF). Part sizes may differ slightly.'] :=
    'Parts are sized evenly by bytes; each part ends only after a complete line (LF). Part sizes may differ slightly.';
  GTextPortuguese.Values['Parts are sized evenly by bytes; each part ends only after a complete line (LF). Part sizes may differ slightly.'] :=
    'As partes sao balanceadas por bytes; cada parte termina somente apos uma linha completa (LF). Os tamanhos podem variar um pouco.';
  GTextSpanish.Values['Parts are sized evenly by bytes; each part ends only after a complete line (LF). Part sizes may differ slightly.'] :=
    'Las partes se equilibran por bytes; cada parte termina solo despues de una linea completa (LF). Los tamanos pueden variar ligeramente.';
  GTextFrench.Values['Parts are sized evenly by bytes; each part ends only after a complete line (LF). Part sizes may differ slightly.'] :=
    'Les parties sont equilibrees en octets; chaque partie se termine seulement apres une ligne complete (LF). Les tailles peuvent varier legerement.';
  GTextGerman.Values['Parts are sized evenly by bytes; each part ends only after a complete line (LF). Part sizes may differ slightly.'] :=
    'Die Teile sind nach Bytes ausgeglichen; jedes Teil endet erst nach einer vollstaendigen Zeile (LF). Groessen koennen leicht abweichen.';
  GTextItalian.Values['Parts are sized evenly by bytes; each part ends only after a complete line (LF). Part sizes may differ slightly.'] :=
    'Le parti sono bilanciate per byte; ogni parte termina solo dopo una riga completa (LF). Le dimensioni possono variare leggermente.';
  GTextPolish.Values['Parts are sized evenly by bytes; each part ends only after a complete line (LF). Part sizes may differ slightly.'] :=
    'Czesci sa wyrownane wg bajtow; kazda czesc konczy sie dopiero po pelnej linii (LF). Rozmiary moga sie nieznacznie roznic.';
  GTextPortuguesePT.Values['Parts are sized evenly by bytes; each part ends only after a complete line (LF). Part sizes may differ slightly.'] :=
    'As partes sao balanceadas por bytes; cada parte termina apenas apos uma linha completa (LF). Os tamanhos podem variar ligeiramente.';
  GTextRomanian.Values['Parts are sized evenly by bytes; each part ends only after a complete line (LF). Part sizes may differ slightly.'] :=
    'Partile sunt echilibrate pe octeti; fiecare parte se termina numai dupa o linie completa (LF). Dimensiunile pot varia usor.';
  GTextHungarian.Values['Parts are sized evenly by bytes; each part ends only after a complete line (LF). Part sizes may differ slightly.'] :=
    'A reszek bajt szerint vannak kiegyensulyozva; minden resz csak teljes sor (LF) utan er veget. A meretek kis mertekben elterhetnek.';
  GTextCzech.Values['Parts are sized evenly by bytes; each part ends only after a complete line (LF). Part sizes may differ slightly.'] :=
    'Casti jsou vyvazene podle bajtu; kazda cast konci az po uplnem radku (LF). Velikosti se mohou mirne lisit.';

  GTextEnglish.Values['Number of parts must be between %d and %d.'] := 'Number of parts must be between %d and %d.';
  GTextPortuguese.Values['Number of parts must be between %d and %d.'] := 'O numero de partes deve estar entre %d e %d.';
  GTextSpanish.Values['Number of parts must be between %d and %d.'] := 'El numero de partes debe estar entre %d y %d.';
  GTextFrench.Values['Number of parts must be between %d and %d.'] := 'Le nombre de parties doit etre entre %d et %d.';
  GTextGerman.Values['Number of parts must be between %d and %d.'] := 'Die Anzahl der Teile muss zwischen %d und %d liegen.';
  GTextItalian.Values['Number of parts must be between %d and %d.'] := 'Il numero di parti deve essere tra %d e %d.';
  GTextPolish.Values['Number of parts must be between %d and %d.'] := 'Liczba czesci musi byc miedzy %d a %d.';
  GTextPortuguesePT.Values['Number of parts must be between %d and %d.'] := 'O numero de partes deve estar entre %d e %d.';
  GTextRomanian.Values['Number of parts must be between %d and %d.'] := 'Numarul de parti trebuie sa fie intre %d si %d.';
  GTextHungarian.Values['Number of parts must be between %d and %d.'] := 'A reszek szama %d es %d kozott kell legyen.';
  GTextCzech.Values['Number of parts must be between %d and %d.'] := 'Pocet casti musi byt mezi %d a %d.';

  GTextEnglish.Values['Could not count lines in the source file.'] := 'Could not count lines in the source file.';
  GTextPortuguese.Values['Could not count lines in the source file.'] := 'Nao foi possivel contar as linhas do arquivo de origem.';
  GTextSpanish.Values['Could not count lines in the source file.'] := 'No se pudieron contar las lineas del archivo de origen.';
  GTextFrench.Values['Could not count lines in the source file.'] := 'Impossible de compter les lignes du fichier source.';
  GTextGerman.Values['Could not count lines in the source file.'] := 'Zeilen der Quelldatei konnten nicht gezaehlt werden.';
  GTextItalian.Values['Could not count lines in the source file.'] := 'Impossibile contare le righe del file sorgente.';
  GTextPolish.Values['Could not count lines in the source file.'] := 'Nie mozna policzyc linii w pliku zrodlowym.';
  GTextPortuguesePT.Values['Could not count lines in the source file.'] := 'Nao foi possivel contar as linhas do ficheiro de origem.';
  GTextRomanian.Values['Could not count lines in the source file.'] := 'Nu s-au putut numara liniile din fisierul sursa.';
  GTextHungarian.Values['Could not count lines in the source file.'] := 'A forrasfajl sorait nem sikerult megszamolni.';
  GTextCzech.Values['Could not count lines in the source file.'] := 'Nepodarilo se spocitat radky ve zdrojovem souboru.';

  GTextEnglish.Values['Not enough lines in the file for this many parts (lines: %d, parts: %d).'] :=
    'Not enough lines in the file for this many parts (lines: %d, parts: %d).';
  GTextPortuguese.Values['Not enough lines in the file for this many parts (lines: %d, parts: %d).'] :=
    'Linhas insuficientes no arquivo para este numero de partes (linhas: %d, partes: %d).';
  GTextSpanish.Values['Not enough lines in the file for this many parts (lines: %d, parts: %d).'] :=
    'No hay suficientes lineas en el archivo para tantas partes (lineas: %d, partes: %d).';
  GTextFrench.Values['Not enough lines in the file for this many parts (lines: %d, parts: %d).'] :=
    'Pas assez de lignes dans le fichier pour autant de parties (lignes : %d, parties : %d).';
  GTextGerman.Values['Not enough lines in the file for this many parts (lines: %d, parts: %d).'] :=
    'Nicht genug Zeilen in der Datei fuer so viele Teile (Zeilen: %d, Teile: %d).';
  GTextItalian.Values['Not enough lines in the file for this many parts (lines: %d, parts: %d).'] :=
    'Righe insufficienti nel file per cosi tante parti (righe: %d, parti: %d).';
  GTextPolish.Values['Not enough lines in the file for this many parts (lines: %d, parts: %d).'] :=
    'Za malo linii w pliku dla tylu czesci (linie: %d, czesci: %d).';
  GTextPortuguesePT.Values['Not enough lines in the file for this many parts (lines: %d, parts: %d).'] :=
    'Linhas insuficientes no ficheiro para este numero de partes (linhas: %d, partes: %d).';
  GTextRomanian.Values['Not enough lines in the file for this many parts (lines: %d, parts: %d).'] :=
    'Prea putine linii in fisier pentru atatea parti (linii: %d, parti: %d).';
  GTextHungarian.Values['Not enough lines in the file for this many parts (lines: %d, parts: %d).'] :=
    'Nincs eleg sor a fajlban ennyi reszhez (sorok: %d, reszek: %d).';
  GTextCzech.Values['Not enough lines in the file for this many parts (lines: %d, parts: %d).'] :=
    'V souboru neni dost radku pro tolik casti (radku: %d, casti: %d).';

  GTextEnglish.Values['Splitting file into equal parts...'] := 'Splitting file into equal parts...';
  GTextPortuguese.Values['Splitting file into equal parts...'] := 'Dividindo arquivo em partes iguais...';
  GTextSpanish.Values['Splitting file into equal parts...'] := 'Dividiendo archivo en partes iguales...';
  GTextFrench.Values['Splitting file into equal parts...'] := 'Division du fichier en parties egales...';
  GTextGerman.Values['Splitting file into equal parts...'] := 'Datei wird in gleich grosse Teile geteilt...';
  GTextItalian.Values['Splitting file into equal parts...'] := 'Divisione del file in parti uguali...';
  GTextPolish.Values['Splitting file into equal parts...'] := 'Dzielenie pliku na rowne czesci...';
  GTextPortuguesePT.Values['Splitting file into equal parts...'] := 'A dividir ficheiro em partes iguais...';
  GTextRomanian.Values['Splitting file into equal parts...'] := 'Impartire fisier in parti egale...';
  GTextHungarian.Values['Splitting file into equal parts...'] := 'Fajl felosztasa egyenlo reszekre...';
  GTextCzech.Values['Splitting file into equal parts...'] := 'Rozdelovani souboru na stejne casti...';

  GTextEnglish.Values['Split equal parts error: '] := 'Split equal parts error: ';
  GTextPortuguese.Values['Split equal parts error: '] := 'Erro ao dividir em partes iguais: ';
  GTextSpanish.Values['Split equal parts error: '] := 'Error al dividir en partes iguales: ';
  GTextFrench.Values['Split equal parts error: '] := 'Erreur de division en parties egales : ';
  GTextGerman.Values['Split equal parts error: '] := 'Fehler beim Teilen in gleiche Teile: ';
  GTextItalian.Values['Split equal parts error: '] := 'Errore divisione in parti uguali: ';
  GTextPolish.Values['Split equal parts error: '] := 'Blad podzialu na rowne czesci: ';
  GTextPortuguesePT.Values['Split equal parts error: '] := 'Erro ao dividir em partes iguais: ';
  GTextRomanian.Values['Split equal parts error: '] := 'Eroare la impartirea in parti egale: ';
  GTextHungarian.Values['Split equal parts error: '] := 'Hiba az egyenlo reszekre osztasnal: ';
  GTextCzech.Values['Split equal parts error: '] := 'Chyba pri rozdeleni na stejne casti: ';

  { Split equal parts: resultado (chaves curtas para Format) }
  GTextEnglish.Values['SplitEqualParts.SuccessFormat'] :=
    'The split operation finished successfully.'#13#10#13#10 +
    'Parts written: %d'#13#10#13#10 +
    'Output folder:'#13#10'%s'#13#10#13#10 +
    'First output file:'#13#10'%s'#13#10#13#10 +
    'Last output file:'#13#10'%s'#13#10#13#10 +
    'Elapsed time: %s';
  GTextPortuguese.Values['SplitEqualParts.SuccessFormat'] :=
    'A divisao foi concluida com sucesso.'#13#10#13#10 +
    'Partes gravadas: %d'#13#10#13#10 +
    'Pasta de saida:'#13#10'%s'#13#10#13#10 +
    'Primeiro arquivo gerado:'#13#10'%s'#13#10#13#10 +
    'Ultimo arquivo gerado:'#13#10'%s'#13#10#13#10 +
    'Tempo decorrido: %s';
  GTextSpanish.Values['SplitEqualParts.SuccessFormat'] :=
    'La division se completo correctamente.'#13#10#13#10 +
    'Partes escritas: %d'#13#10#13#10 +
    'Carpeta de salida:'#13#10'%s'#13#10#13#10 +
    'Primer archivo generado:'#13#10'%s'#13#10#13#10 +
    'Ultimo archivo generado:'#13#10'%s'#13#10#13#10 +
    'Tiempo transcurrido: %s';
  GTextFrench.Values['SplitEqualParts.SuccessFormat'] :=
    'La division s''est terminee avec succes.'#13#10#13#10 +
    'Parties ecrites : %d'#13#10#13#10 +
    'Dossier de sortie :'#13#10'%s'#13#10#13#10 +
    'Premier fichier genere :'#13#10'%s'#13#10#13#10 +
    'Dernier fichier genere :'#13#10'%s'#13#10#13#10 +
    'Temps ecoule : %s';
  GTextGerman.Values['SplitEqualParts.SuccessFormat'] :=
    'Die Aufteilung wurde erfolgreich abgeschlossen.'#13#10#13#10 +
    'Geschriebene Teile: %d'#13#10#13#10 +
    'Ausgabeordner:'#13#10'%s'#13#10#13#10 +
    'Erste Ausgabedatei:'#13#10'%s'#13#10#13#10 +
    'Letzte Ausgabedatei:'#13#10'%s'#13#10#13#10 +
    'Verstrichene Zeit: %s';
  GTextItalian.Values['SplitEqualParts.SuccessFormat'] :=
    'La divisione e stata completata correttamente.'#13#10#13#10 +
    'Parti scritte: %d'#13#10#13#10 +
    'Cartella di output:'#13#10'%s'#13#10#13#10 +
    'Primo file generato:'#13#10'%s'#13#10#13#10 +
    'Ultimo file generato:'#13#10'%s'#13#10#13#10 +
    'Tempo trascorso: %s';
  GTextPolish.Values['SplitEqualParts.SuccessFormat'] :=
    'Operacja podzialu zakonczyla sie pomyslnie.'#13#10#13#10 +
    'Zapisane czesci: %d'#13#10#13#10 +
    'Folder docelowy:'#13#10'%s'#13#10#13#10 +
    'Pierwszy plik wyjsciowy:'#13#10'%s'#13#10#13#10 +
    'Ostatni plik wyjsciowy:'#13#10'%s'#13#10#13#10 +
    'Czas: %s';
  GTextPortuguesePT.Values['SplitEqualParts.SuccessFormat'] :=
    'A divisao foi concluida com sucesso.'#13#10#13#10 +
    'Partes gravadas: %d'#13#10#13#10 +
    'Pasta de destino:'#13#10'%s'#13#10#13#10 +
    'Primeiro ficheiro gerado:'#13#10'%s'#13#10#13#10 +
    'Ultimo ficheiro gerado:'#13#10'%s'#13#10#13#10 +
    'Tempo decorrido: %s';
  GTextRomanian.Values['SplitEqualParts.SuccessFormat'] :=
    'Operatiunea de impartire s-a finalizat cu succes.'#13#10#13#10 +
    'Parti scrise: %d'#13#10#13#10 +
    'Dosar de iesire:'#13#10'%s'#13#10#13#10 +
    'Primul fisier generat:'#13#10'%s'#13#10#13#10 +
    'Ultimul fisier generat:'#13#10'%s'#13#10#13#10 +
    'Timp scurs: %s';
  GTextHungarian.Values['SplitEqualParts.SuccessFormat'] :=
    'A felosztas sikeresen befejezodott.'#13#10#13#10 +
    'Irt reszek: %d'#13#10#13#10 +
    'Kimappa:'#13#10'%s'#13#10#13#10 +
    'Elso kimeneti fajl:'#13#10'%s'#13#10#13#10 +
    'Utolso kimeneti fajl:'#13#10'%s'#13#10#13#10 +
    'Eltelt ido: %s';
  GTextCzech.Values['SplitEqualParts.SuccessFormat'] :=
    'Rozdeleni bylo uspesne dokonceno.'#13#10#13#10 +
    'Zapsanych casti: %d'#13#10#13#10 +
    'Vystupni slozka:'#13#10'%s'#13#10#13#10 +
    'Prvni vystupni soubor:'#13#10'%s'#13#10#13#10 +
    'Posledni vystupni soubor:'#13#10'%s'#13#10#13#10 +
    'Straveny cas: %s';

  GTextEnglish.Values['SplitEqualParts.FailureFormat'] :=
    'The split operation could not be completed.'#13#10#13#10 +
    'Details:'#13#10'%s';
  GTextPortuguese.Values['SplitEqualParts.FailureFormat'] :=
    'Nao foi possivel concluir a divisao.'#13#10#13#10 +
    'Detalhes:'#13#10'%s';
  GTextSpanish.Values['SplitEqualParts.FailureFormat'] :=
    'No se pudo completar la division.'#13#10#13#10 +
    'Detalles:'#13#10'%s';
  GTextFrench.Values['SplitEqualParts.FailureFormat'] :=
    'La division n''a pas pu etre terminee.'#13#10#13#10 +
    'Details :'#13#10'%s';
  GTextGerman.Values['SplitEqualParts.FailureFormat'] :=
    'Die Aufteilung konnte nicht abgeschlossen werden.'#13#10#13#10 +
    'Details:'#13#10'%s';
  GTextItalian.Values['SplitEqualParts.FailureFormat'] :=
    'Impossibile completare la divisione.'#13#10#13#10 +
    'Dettagli:'#13#10'%s';
  GTextPolish.Values['SplitEqualParts.FailureFormat'] :=
    'Nie udalo sie zakonczyc podzialu.'#13#10#13#10 +
    'Szczegoly:'#13#10'%s';
  GTextPortuguesePT.Values['SplitEqualParts.FailureFormat'] :=
    'Nao foi possivel concluir a divisao.'#13#10#13#10 +
    'Detalhes:'#13#10'%s';
  GTextRomanian.Values['SplitEqualParts.FailureFormat'] :=
    'Impartirea nu a putut fi finalizata.'#13#10#13#10 +
    'Detalii:'#13#10'%s';
  GTextHungarian.Values['SplitEqualParts.FailureFormat'] :=
    'A felosztas nem fejezheto be.'#13#10#13#10 +
    'Reszletek:'#13#10'%s';
  GTextCzech.Values['SplitEqualParts.FailureFormat'] :=
    'Rozdeleni nebylo mozne dokoncit.'#13#10#13#10 +
    'Podrobnosti:'#13#10'%s';

  GTextEnglish.Values['SplitEqualParts.LogSummary'] := 'Split into equal parts: %d file(s) -> %s';
  GTextPortuguese.Values['SplitEqualParts.LogSummary'] := 'Divisao em partes iguais: %d arquivo(s) -> %s';
  GTextSpanish.Values['SplitEqualParts.LogSummary'] := 'Division en partes iguales: %d archivo(s) -> %s';
  GTextFrench.Values['SplitEqualParts.LogSummary'] := 'Division en parties egales : %d fichier(s) -> %s';
  GTextGerman.Values['SplitEqualParts.LogSummary'] := 'Aufteilung in gleiche Teile: %d Datei(en) -> %s';
  GTextItalian.Values['SplitEqualParts.LogSummary'] := 'Divisione in parti uguali: %d file -> %s';
  GTextPolish.Values['SplitEqualParts.LogSummary'] := 'Podzial na rowne czesci: %d plik(ow) -> %s';
  GTextPortuguesePT.Values['SplitEqualParts.LogSummary'] := 'Divisao em partes iguais: %d ficheiro(s) -> %s';
  GTextRomanian.Values['SplitEqualParts.LogSummary'] := 'Impartire in parti egale: %d fisier(e) -> %s';
  GTextHungarian.Values['SplitEqualParts.LogSummary'] := 'Egyenlo reszekre osztas: %d fajl -> %s';
  GTextCzech.Values['SplitEqualParts.LogSummary'] := 'Rozdeleni na stejne casti: %d soubor(u) -> %s';

  GTextEnglish.Values['SplitEqualParts.CancelledOrIncomplete'] :=
    'The split operation did not finish. No success confirmation is available (for example, the task was interrupted or stopped early).';
  GTextPortuguese.Values['SplitEqualParts.CancelledOrIncomplete'] :=
    'A divisao nao foi concluida. Nao ha confirmacao de sucesso (por exemplo, a tarefa foi interrompida ou parada antes do fim).';
  GTextSpanish.Values['SplitEqualParts.CancelledOrIncomplete'] :=
    'La division no finalizo. No hay confirmacion de exito (por ejemplo, la tarea se interrumpio o se detuvo antes de tiempo).';
  GTextFrench.Values['SplitEqualParts.CancelledOrIncomplete'] :=
    'La division n''est pas terminee. Aucune confirmation de reussite (par exemple, tache interrompue ou arretee trop tot).';
  GTextGerman.Values['SplitEqualParts.CancelledOrIncomplete'] :=
    'Die Aufteilung wurde nicht abgeschlossen. Keine Erfolgsbestaetigung (z. B. abgebrochen oder vorzeitig beendet).';
  GTextItalian.Values['SplitEqualParts.CancelledOrIncomplete'] :=
    'La divisione non e stata completata. Nessuna conferma di esito positivo (ad esempio operazione interrotta).';
  GTextPolish.Values['SplitEqualParts.CancelledOrIncomplete'] :=
    'Podzial nie zostal zakonczony. Brak potwierdzenia powodzenia (np. przerwane lub zatrzymane zbyt wczesnie).';
  GTextPortuguesePT.Values['SplitEqualParts.CancelledOrIncomplete'] :=
    'A divisao nao foi concluida. Nao ha confirmacao de sucesso (por exemplo, a tarefa foi interrompida).';
  GTextRomanian.Values['SplitEqualParts.CancelledOrIncomplete'] :=
    'Impartirea nu s-a finalizat. Nu exista confirmare de succes (de ex. operatiune intrerupta sau oprita devreme).';
  GTextHungarian.Values['SplitEqualParts.CancelledOrIncomplete'] :=
    'A felosztas nem fejezodott be. Nincs sikeres megerosites (pl. megszakitva vagy idoben leallitva).';
  GTextCzech.Values['SplitEqualParts.CancelledOrIncomplete'] :=
    'Rozdeleni nebylo dokonceno. Chybi potvrzeni uspechu (ukol napr. prerusen nebo zastaven drive).';

  GTextEnglish.Values['Split into equal parts completed in: %s (%d file(s) created).'] :=
    'Split into equal parts completed in: %s (%d file(s) created).';
  GTextPortuguese.Values['Split into equal parts completed in: %s (%d file(s) created).'] :=
    'Divisao em partes iguais concluida em: %s (%d arquivo(s) criado(s)).';
  GTextSpanish.Values['Split into equal parts completed in: %s (%d file(s) created).'] :=
    'Division en partes iguales finalizada en: %s (%d archivo(s) creado(s)).';
  GTextFrench.Values['Split into equal parts completed in: %s (%d file(s) created).'] :=
    'Division en parties egales terminee en : %s (%d fichier(s) cree(s)).';
  GTextGerman.Values['Split into equal parts completed in: %s (%d file(s) created).'] :=
    'Teilen in gleiche Teile abgeschlossen in: %s (%d Datei(en) erstellt).';
  GTextItalian.Values['Split into equal parts completed in: %s (%d file(s) created).'] :=
    'Divisione in parti uguali completata in: %s (%d file creati).';
  GTextPolish.Values['Split into equal parts completed in: %s (%d file(s) created).'] :=
    'Podzial na rowne czesci zakonczony w: %s (utworzono %d plik(ow)).';
  GTextPortuguesePT.Values['Split into equal parts completed in: %s (%d file(s) created).'] :=
    'Divisao em partes iguais concluida em: %s (%d ficheiro(s) criado(s)).';
  GTextRomanian.Values['Split into equal parts completed in: %s (%d file(s) created).'] :=
    'Impartirea in parti egale finalizata in: %s (%d fisier(e) create).';
  GTextHungarian.Values['Split into equal parts completed in: %s (%d file(s) created).'] :=
    'Egyenlo reszekre osztas befejezve: %s (%d fajl letrehozva).';
  GTextCzech.Values['Split into equal parts completed in: %s (%d file(s) created).'] :=
    'Rozdeleni na stejne casti dokonceno za: %s (vytvoreno %d souboru).';

  GTextEnglish.Values['Source file is empty.'] := 'Source file is empty.';
  GTextPortuguese.Values['Source file is empty.'] := 'O arquivo de origem esta vazio.';
  GTextSpanish.Values['Source file is empty.'] := 'El archivo de origen esta vacio.';
  GTextFrench.Values['Source file is empty.'] := 'Le fichier source est vide.';
  GTextGerman.Values['Source file is empty.'] := 'Die Quelldatei ist leer.';
  GTextItalian.Values['Source file is empty.'] := 'Il file sorgente e vuoto.';
  GTextPolish.Values['Source file is empty.'] := 'Plik zrodlowy jest pusty.';
  GTextPortuguesePT.Values['Source file is empty.'] := 'O ficheiro de origem esta vazio.';
  GTextRomanian.Values['Source file is empty.'] := 'Fisierul sursa este gol.';
  GTextHungarian.Values['Source file is empty.'] := 'A forrasfajl ures.';
  GTextCzech.Values['Source file is empty.'] := 'Zdrojovy soubor je prazdny.';

  GTextEnglish.Values['Could not compute split boundaries: file too small for the requested number of parts.'] :=
    'Could not compute split boundaries: file too small for the requested number of parts.';
  GTextPortuguese.Values['Could not compute split boundaries: file too small for the requested number of parts.'] :=
    'Nao foi possivel calcular os limites: arquivo pequeno demais para o numero de partes.';
  GTextSpanish.Values['Could not compute split boundaries: file too small for the requested number of parts.'] :=
    'No se pudieron calcular los limites: archivo demasiado pequeno para el numero de partes.';
  GTextFrench.Values['Could not compute split boundaries: file too small for the requested number of parts.'] :=
    'Impossible de calculer les limites : fichier trop petit pour ce nombre de parties.';
  GTextGerman.Values['Could not compute split boundaries: file too small for the requested number of parts.'] :=
    'Teilgrenzen konnten nicht berechnet werden: Datei zu klein fuer die gewuenschte Teileanzahl.';
  GTextItalian.Values['Could not compute split boundaries: file too small for the requested number of parts.'] :=
    'Impossibile calcolare i confini: file troppo piccolo per il numero di parti richiesto.';
  GTextPolish.Values['Could not compute split boundaries: file too small for the requested number of parts.'] :=
    'Nie mozna obliczyc granic: plik zbyt maly dla tej liczby czesci.';
  GTextPortuguesePT.Values['Could not compute split boundaries: file too small for the requested number of parts.'] :=
    'Nao foi possivel calcular os limites: ficheiro demasiado pequeno para o numero de partes.';
  GTextRomanian.Values['Could not compute split boundaries: file too small for the requested number of parts.'] :=
    'Nu s-au putut calcula limitele: fisier prea mic pentru numarul de parti.';
  GTextHungarian.Values['Could not compute split boundaries: file too small for the requested number of parts.'] :=
    'A hatarok nem szamolhatok: a fajl tul kicsi a reszek szamahoz.';
  GTextCzech.Values['Could not compute split boundaries: file too small for the requested number of parts.'] :=
    'Nelze vypocitat hranice: soubor je prilis maly pro pozadovany pocet casti.';

  GTextEnglish.Values['Could not compute split boundaries: not enough line breaks for the requested number of parts.'] :=
    'Could not compute split boundaries: not enough line breaks for the requested number of parts.';
  GTextPortuguese.Values['Could not compute split boundaries: not enough line breaks for the requested number of parts.'] :=
    'Nao foi possivel calcular os limites: quebras de linha insuficientes para o numero de partes.';
  GTextSpanish.Values['Could not compute split boundaries: not enough line breaks for the requested number of parts.'] :=
    'No se pudieron calcular los limites: no hay suficientes saltos de linea para el numero de partes.';
  GTextFrench.Values['Could not compute split boundaries: not enough line breaks for the requested number of parts.'] :=
    'Impossible de calculer les limites : pas assez de sauts de ligne pour ce nombre de parties.';
  GTextGerman.Values['Could not compute split boundaries: not enough line breaks for the requested number of parts.'] :=
    'Teilgrenzen konnten nicht berechnet werden: zu wenige Zeilenumbrueche fuer die Teileanzahl.';
  GTextItalian.Values['Could not compute split boundaries: not enough line breaks for the requested number of parts.'] :=
    'Impossibile calcolare i confini: interruzioni di riga insufficienti per il numero di parti.';
  GTextPolish.Values['Could not compute split boundaries: not enough line breaks for the requested number of parts.'] :=
    'Nie mozna obliczyc granic: za malo zlaman linii dla tej liczby czesci.';
  GTextPortuguesePT.Values['Could not compute split boundaries: not enough line breaks for the requested number of parts.'] :=
    'Nao foi possivel calcular os limites: quebras de linha insuficientes para o numero de partes.';
  GTextRomanian.Values['Could not compute split boundaries: not enough line breaks for the requested number of parts.'] :=
    'Nu s-au putut calcula limitele: prea putine sfarsituri de linie pentru numarul de parti.';
  GTextHungarian.Values['Could not compute split boundaries: not enough line breaks for the requested number of parts.'] :=
    'A hatarok nem szamolhatok: nincs eleg sorvege a reszek szamahoz.';
  GTextCzech.Values['Could not compute split boundaries: not enough line breaks for the requested number of parts.'] :=
    'Nelze vypocitat hranice: nedostatek koncu radku pro pozadovany pocet casti.';

  GTextEnglish.Values['Could not compute split boundaries: last part would be empty.'] :=
    'Could not compute split boundaries: last part would be empty.';
  GTextPortuguese.Values['Could not compute split boundaries: last part would be empty.'] :=
    'Nao foi possivel calcular os limites: a ultima parte ficaria vazia.';
  GTextSpanish.Values['Could not compute split boundaries: last part would be empty.'] :=
    'No se pudieron calcular los limites: la ultima parte quedaria vacia.';
  GTextFrench.Values['Could not compute split boundaries: last part would be empty.'] :=
    'Impossible de calculer les limites : la derniere partie serait vide.';
  GTextGerman.Values['Could not compute split boundaries: last part would be empty.'] :=
    'Teilgrenzen konnten nicht berechnet werden: das letzte Teil waere leer.';
  GTextItalian.Values['Could not compute split boundaries: last part would be empty.'] :=
    'Impossibile calcolare i confini: l''ultima parte sarebbe vuota.';
  GTextPolish.Values['Could not compute split boundaries: last part would be empty.'] :=
    'Nie mozna obliczyc granic: ostatnia czesc bylaby pusta.';
  GTextPortuguesePT.Values['Could not compute split boundaries: last part would be empty.'] :=
    'Nao foi possivel calcular os limites: a ultima parte ficaria vazia.';
  GTextRomanian.Values['Could not compute split boundaries: last part would be empty.'] :=
    'Nu s-au putut calcula limitele: ultima parte ar fi goala.';
  GTextHungarian.Values['Could not compute split boundaries: last part would be empty.'] :=
    'A hatarok nem szamolhatok: az utolso resz ures lenne.';
  GTextCzech.Values['Could not compute split boundaries: last part would be empty.'] :=
    'Nelze vypocitat hranice: posledni cast by byla prazdna.';

  { --- Merge files - Line Range feature (copy specific lines) --------------- }
  GTextEnglish.Values['Copy only a specific range of lines from source'] := 'Copy only a specific range of lines from source';
  GTextPortuguese.Values['Copy only a specific range of lines from source'] := 'Copiar apenas um intervalo especifico de linhas do arquivo de origem';
  GTextSpanish.Values['Copy only a specific range of lines from source'] := 'Copiar solo un rango especifico de lineas del archivo oricen';
  GTextFrench.Values['Copy only a specific range of lines from source'] := 'Copier seulement une plage specifique de lignes depuis la source';
  GTextGerman.Values['Copy only a specific range of lines from source'] := 'Nur einen bestimmten Zeilenbereich aus der Quelle kopieren';
  GTextItalian.Values['Copy only a specific range of lines from source'] := 'Copia solo un intervallo specifico di righe dal sorgente';
  GTextPolish.Values['Copy only a specific range of lines from source'] := 'Kopiuj tylko okreslony zakres linii ze zrodla';
  GTextRomanian.Values['Copy only a specific range of lines from source'] := 'Copiaza doar un interval specific de linii din sursă';
  GTextHungarian.Values['Copy only a specific range of lines from source'] := 'Csak egy meghatarozott sortartomany masolasa a forrasbol';
  GTextCzech.Values['Copy only a specific range of lines from source'] := 'Kopirovat pouze specificky rozsah radku zdroje';
  GTextPortuguesePT.Values['Copy only a specific range of lines from source'] := 'Copiar apenas um intervalo especifico de linhas do ficheiro de origem';

  GTextEnglish.Values['From line:'] := 'From line:';
  GTextPortuguese.Values['From line:'] := 'Da linha:';
  GTextSpanish.Values['From line:'] := 'Desde la linea:';
  GTextFrench.Values['From line:'] := 'A partir de la ligne:';
  GTextGerman.Values['From line:'] := 'Von Zeile:';
  GTextItalian.Values['From line:'] := 'Dalla riga:';
  GTextPolish.Values['From line:'] := 'Od linii:';
  GTextRomanian.Values['From line:'] := 'De la linia:';
  GTextHungarian.Values['From line:'] := 'Ettol a sortol:';
  GTextCzech.Values['From line:'] := 'Od radku:';
  GTextPortuguesePT.Values['From line:'] := 'Da linha:';

  GTextEnglish.Values['To line:'] := 'To line:';
  GTextPortuguese.Values['To line:'] := 'Ate a linha:';
  GTextSpanish.Values['To line:'] := 'Hasta la linea:';
  GTextFrench.Values['To line:'] := 'Jusqu''a la ligne:';
  GTextGerman.Values['To line:'] := 'Bis Zeile:';
  GTextItalian.Values['To line:'] := 'Alla riga:';
  GTextPolish.Values['To line:'] := 'Do linii:';
  GTextRomanian.Values['To line:'] := 'Pana la linia:';
  GTextHungarian.Values['To line:'] := 'Eddig a sorig:';
  GTextCzech.Values['To line:'] := 'Do radku:';
  GTextPortuguesePT.Values['To line:'] := 'Ate a linha:';

  GTextEnglish.Values['Error: "From line" cannot be empty.'] := 'Error: "From line" cannot be empty.';
  GTextPortuguese.Values['Error: "From line" cannot be empty.'] := 'Erro: "Da linha" nao pode estar vazia.';
  GTextSpanish.Values['Error: "From line" cannot be empty.'] := 'Error: "Desde la linea" no puede estar vacier.';
  GTextFrench.Values['Error: "From line" cannot be empty.'] := 'Erreur: "A partir de la ligne" ne peut pas etre vide.';
  GTextGerman.Values['Error: "From line" cannot be empty.'] := 'Fehler: "Von Zeile" darf nicht leer sein.';
  GTextItalian.Values['Error: "From line" cannot be empty.'] := 'Errore: "Dalla riga" non puo essere vuoto.';
  GTextPolish.Values['Error: "From line" cannot be empty.'] := 'Blad: "Od linii" nie moze byc pusty.';
  GTextRomanian.Values['Error: "From line" cannot be empty.'] := 'Eroare: "De la linia" nu poate fi gol.';
  GTextHungarian.Values['Error: "From line" cannot be empty.'] := 'Hiba: "Ettol a sortol" nem lehet ures.';
  GTextCzech.Values['Error: "From line" cannot be empty.'] := 'Chyba: "Od radku" nesmí být prázdný.';
  GTextPortuguesePT.Values['Error: "From line" cannot be empty.'] := 'Erro: "Da linha" nao pode estar vazia.';

  GTextEnglish.Values['Error: "To line" cannot be empty.'] := 'Error: "To line" cannot be empty.';
  GTextPortuguese.Values['Error: "To line" cannot be empty.'] := 'Erro: "Ate a linha" nao pode estar vazia.';
  GTextSpanish.Values['Error: "To line" cannot be empty.'] := 'Error: "Hasta la linea" no puede estar vacie.';
  GTextFrench.Values['Error: "To line" cannot be empty.'] := 'Erreur: "Jusqu''a la ligne" ne peut pas etre vide.';
  GTextGerman.Values['Error: "To line" cannot be empty.'] := 'Fehler: "Bis Zeile" darf nicht leer sein.';
  GTextItalian.Values['Error: "To line" cannot be empty.'] := 'Errore: "Alla riga" non puo essere vuoto.';
  GTextPolish.Values['Error: "To line" cannot be empty.'] := 'Blad: "Do linii" nie moze byc pusty.';
  GTextRomanian.Values['Error: "To line" cannot be empty.'] := 'Eroare: "Pana la linia" nu poate fi gol.';
  GTextHungarian.Values['Error: "To line" cannot be empty.'] := 'Hiba: "Eddig a sorig" nem lehet ures.';
  GTextCzech.Values['Error: "To line" cannot be empty.'] := 'Chyba: "Do radku" nesmí být prázdný.';
  GTextPortuguesePT.Values['Error: "To line" cannot be empty.'] := 'Erro: "Ate a linha" nao pode estar vazia.';

  GTextEnglish.Values['Error: "From line" must be a valid number.'] := 'Error: "From line" must be a valid number.';
  GTextPortuguese.Values['Error: "From line" must be a valid number.'] := 'Erro: "Da linha" deve ser um numero valido.';
  GTextSpanish.Values['Error: "From line" must be a valid number.'] := 'Error: "Desde la linea" debe ser un numero valido.';
  GTextFrench.Values['Error: "From line" must be a valid number.'] := 'Erreur: "A partir de la ligne" doit etre un nombre valide.';
  GTextGerman.Values['Error: "From line" must be a valid number.'] := 'Fehler: "Von Zeile" muss eine gueltige Nummer sein.';
  GTextItalian.Values['Error: "From line" must be a valid number.'] := 'Errore: "Dalla riga" deve essere un numero valido.';
  GTextPolish.Values['Error: "From line" must be a valid number.'] := 'Blad: "Od linii" musi byc liczba.';
  GTextRomanian.Values['Error: "From line" must be a valid number.'] := 'Eroare: "De la linia" trebuie sa fie un numar valid.';
  GTextHungarian.Values['Error: "From line" must be a valid number.'] := 'Hiba: "Ettol a sortol" ervenyes szamnak kell lennie.';
  GTextCzech.Values['Error: "From line" must be a valid number.'] := 'Chyba: "Od radku" musi byt platne cislo.';
  GTextPortuguesePT.Values['Error: "From line" must be a valid number.'] := 'Erro: "Da linha" deve ser um numero valido.';

  GTextEnglish.Values['Error: "To line" must be a valid number.'] := 'Error: "To line" must be a valid number.';
  GTextPortuguese.Values['Error: "To line" must be a valid number.'] := 'Erro: "Ate a linha" deve ser um numero valido.';
  GTextSpanish.Values['Error: "To line" must be a valid number.'] := 'Error: "Hasta la linea" debe ser un numero valido.';
  GTextFrench.Values['Error: "To line" must be a valid number.'] := 'Erreur: "Jusqu''a la ligne" doit etre un nombre valide.';
  GTextGerman.Values['Error: "To line" must be a valid number.'] := 'Fehler: "Bis Zeile" muss eine gueltige Nummer sein.';
  GTextItalian.Values['Error: "To line" must be a valid number.'] := 'Errore: "Alla riga" deve essere un numero valido.';
  GTextPolish.Values['Error: "To line" must be a valid number.'] := 'Blad: "Do linii" musi byc liczba.';
  GTextRomanian.Values['Error: "To line" must be a valid number.'] := 'Eroare: "Pana la linia" trebuie sa fie un numar valid.';
  GTextHungarian.Values['Error: "To line" must be a valid number.'] := 'Hiba: "Eddig a sorig" ervenyes szamnak kell lennie.';
  GTextCzech.Values['Error: "To line" must be a valid number.'] := 'Chyba: "Do radku" musi byt platne cislo.';
  GTextPortuguesePT.Values['Error: "To line" must be a valid number.'] := 'Erro: "Ate a linha" deve ser um numero valido.';

  GTextEnglish.Values['Error: "From line" must be at least 1.'] := 'Error: "From line" must be at least 1.';
  GTextPortuguese.Values['Error: "From line" must be at least 1.'] := 'Erro: "Da linha" deve ser pelo menos 1.';
  GTextSpanish.Values['Error: "From line" must be at least 1.'] := 'Error: "Desde la linea" debe ser al menos 1.';
  GTextFrench.Values['Error: "From line" must be at least 1.'] := 'Erreur: "A partir de la ligne" doit etre au moins 1.';
  GTextGerman.Values['Error: "From line" must be at least 1.'] := 'Fehler: "Von Zeile" muss mindestens 1 sein.';
  GTextItalian.Values['Error: "From line" must be at least 1.'] := 'Errore: "Dalla riga" deve essere almeno 1.';
  GTextPolish.Values['Error: "From line" must be at least 1.'] := 'Blad: "Od linii" musi miec co najmniej 1.';
  GTextRomanian.Values['Error: "From line" must be at least 1.'] := 'Eroare: "De la linia" trebuie sa fie cel putin 1.';
  GTextHungarian.Values['Error: "From line" must be at least 1.'] := 'Hiba: "Ettol a sortol" legalabb 1 kell lennie.';
  GTextCzech.Values['Error: "From line" must be at least 1.'] := 'Chyba: "Od radku" musi byt minimalne 1.';
  GTextPortuguesePT.Values['Error: "From line" must be at least 1.'] := 'Erro: "Da linha" deve ser pelo menos 1.';

  GTextEnglish.Values['Error: "To line" must be at least 1.'] := 'Error: "To line" must be at least 1.';
  GTextPortuguese.Values['Error: "To line" must be at least 1.'] := 'Erro: "Ate a linha" deve ser pelo menos 1.';
  GTextSpanish.Values['Error: "To line" must be at least 1.'] := 'Error: "Hasta la linea" debe ser al menos 1.';
  GTextFrench.Values['Error: "To line" must be at least 1.'] := 'Erreur: "Jusqu''a la ligne" doit etre au moins 1.';
  GTextGerman.Values['Error: "To line" must be at least 1.'] := 'Fehler: "Bis Zeile" muss mindestens 1 sein.';
  GTextItalian.Values['Error: "To line" must be at least 1.'] := 'Errore: "Alla riga" deve essere almeno 1.';
  GTextPolish.Values['Error: "To line" must be at least 1.'] := 'Blad: "Do linii" musi miec co najmniej 1.';
  GTextRomanian.Values['Error: "To line" must be at least 1.'] := 'Eroare: "Pana la linia" trebuie sa fie cel putin 1.';
  GTextHungarian.Values['Error: "To line" must be at least 1.'] := 'Hiba: "Eddig a sorig" legalabb 1 kell lennie.';
  GTextCzech.Values['Error: "To line" must be at least 1.'] := 'Chyba: "Do radku" musi byt minimalne 1.';
  GTextPortuguesePT.Values['Error: "To line" must be at least 1.'] := 'Erro: "Ate a linha" deve ser pelo menos 1.';

  GTextEnglish.Values['Error: "From line" (%d) cannot be greater than "To line" (%d).'] := 'Error: "From line" (%d) cannot be greater than "To line" (%d).';
  GTextPortuguese.Values['Error: "From line" (%d) cannot be greater than "To line" (%d).'] := 'Erro: "Da linha" (%d) nao pode ser maior que "Ate a linha" (%d).';
  GTextSpanish.Values['Error: "From line" (%d) cannot be greater than "To line" (%d).'] := 'Error: "Desde la linea" (%d) no puede ser mayor que "Hasta la linea" (%d).';
  GTextFrench.Values['Error: "From line" (%d) cannot be greater than "To line" (%d).'] := 'Erreur: "A partir de la ligne" (%d) ne peut pas etre superieure a "Jusqu''a la ligne" (%d).';
  GTextGerman.Values['Error: "From line" (%d) cannot be greater than "To line" (%d).'] := 'Fehler: "Von Zeile" (%d) kann nicht groesser als "Bis Zeile" (%d) sein.';
  GTextItalian.Values['Error: "From line" (%d) cannot be greater than "To line" (%d).'] := 'Errore: "Dalla riga" (%d) non puo essere maggiore di "Alla riga" (%d).';
  GTextPolish.Values['Error: "From line" (%d) cannot be greater than "To line" (%d).'] := 'Blad: "Od linii" (%d) nie moze byc wieksze niz "Do linii" (%d).';
  GTextRomanian.Values['Error: "From line" (%d) cannot be greater than "To line" (%d).'] := 'Eroare: "De la linia" (%d) nu poate fi mai mare decat "Pana la linia" (%d).';
  GTextHungarian.Values['Error: "From line" (%d) cannot be greater than "To line" (%d).'] := 'Hiba: "Ettol a sortol" (%d) nem lehet nagyobb mint "Eddig a sorig" (%d).';
  GTextCzech.Values['Error: "From line" (%d) cannot be greater than "To line" (%d).'] := 'Chyba: "Od radku" (%d) nesmí být vetsí nez "Do radku" (%d).';
  GTextPortuguesePT.Values['Error: "From line" (%d) cannot be greater than "To line" (%d).'] := 'Erro: "Da linha" (%d) nao pode ser maior que "Ate a linha" (%d).';

  GTextEnglish.Values['Error: Source file not found: %s'] := 'Error: Source file not found: %s';
  GTextPortuguese.Values['Error: Source file not found: %s'] := 'Erro: Arquivo de origem nao encontrado: %s';
  GTextSpanish.Values['Error: Source file not found: %s'] := 'Error: Archivo de origen no encontrado: %s';
  GTextFrench.Values['Error: Source file not found: %s'] := 'Erreur: Fichier source introuvable: %s';
  GTextGerman.Values['Error: Source file not found: %s'] := 'Fehler: Quelldatei nicht gefunden: %s';
  GTextItalian.Values['Error: Source file not found: %s'] := 'Errore: File sorgente non trovato: %s';
  GTextPolish.Values['Error: Source file not found: %s'] := 'Blad: Plik zrodlowy nie znaleziony: %s';
  GTextRomanian.Values['Error: Source file not found: %s'] := 'Eroare: Fisierul sursă nu a fost gasit: %s';
  GTextHungarian.Values['Error: Source file not found: %s'] := 'Hiba: Forrasfajl nem talalhato: %s';
  GTextCzech.Values['Error: Source file not found: %s'] := 'Chyba: Zdrojovy soubor nenalezan: %s';
  GTextPortuguesePT.Values['Error: Source file not found: %s'] := 'Erro: Ficheiro de origem nao encontrado: %s';

  GTextEnglish.Values['Error: Could not read source file to validate line count.'] := 'Error: Could not read source file to validate line count.';
  GTextPortuguese.Values['Error: Could not read source file to validate line count.'] := 'Erro: Nao foi possivel ler o arquivo de origem para validar o total de linhas.';
  GTextSpanish.Values['Error: Could not read source file to validate line count.'] := 'Error: No se pudo leer el archivo de origen para validar el recuento de lineas.';
  GTextFrench.Values['Error: Could not read source file to validate line count.'] := 'Erreur: Impossible de lire le fichier source pour valider le nombre de lignes.';
  GTextGerman.Values['Error: Could not read source file to validate line count.'] := 'Fehler: Quelldatei konnte nicht gelesen werden, um die Zeilenanzahl zu validieren.';
  GTextItalian.Values['Error: Could not read source file to validate line count.'] := 'Errore: Impossibile leggere il file sorgente per convalidare il conteggio delle righe.';
  GTextPolish.Values['Error: Could not read source file to validate line count.'] := 'Blad: Nie mozna bylo przeczytac pliku zrodlowego, aby sprawdzic liczbe linii.';
  GTextRomanian.Values['Error: Could not read source file to validate line count.'] := 'Eroare: Nu s-a putut citi fisierul sursă pentru a valida numarul de linii.';
  GTextHungarian.Values['Error: Could not read source file to validate line count.'] := 'Hiba: Az forrasfajlt nem lehetett olvasni a sorCount ellenorzesehez.';
  GTextCzech.Values['Error: Could not read source file to validate line count.'] := 'Chyba: Nelze ctenizdrojoveho souboru pro overeni poctu radku.';
  GTextPortuguesePT.Values['Error: Could not read source file to validate line count.'] := 'Erro: Nao foi possivel ler o ficheiro de origem para validar o total de linhas.';

  GTextEnglish.Values['Error: "From line" (%d) exceeds total lines in source file (%d).'] := 'Error: "From line" (%d) exceeds total lines in source file (%d).';
  GTextPortuguese.Values['Error: "From line" (%d) exceeds total lines in source file (%d).'] := 'Erro: "Da linha" (%d) excede o total de linhas no arquivo de origem (%d).';
  GTextSpanish.Values['Error: "From line" (%d) exceeds total lines in source file (%d).'] := 'Error: "Desde la linea" (%d) excede el numero total de lineas en el archivo de origen (%d).';
  GTextFrench.Values['Error: "From line" (%d) exceeds total lines in source file (%d).'] := 'Erreur: "A partir de la ligne" (%d) depasse le nombre total de lignes du fichier source (%d).';
  GTextGerman.Values['Error: "From line" (%d) exceeds total lines in source file (%d).'] := 'Fehler: "Von Zeile" (%d) uebersteigt die Gesamtzahl der Zeilen in der Quelldatei (%d).';
  GTextItalian.Values['Error: "From line" (%d) exceeds total lines in source file (%d).'] := 'Errore: "Dalla riga" (%d) supera il numero totale di righe nel file sorgente (%d).';
  GTextPolish.Values['Error: "From line" (%d) exceeds total lines in source file (%d).'] := 'Blad: "Od linii" (%d) przekracza calkowita liczbe linii w pliku zrodlowym (%d).';
  GTextRomanian.Values['Error: "From line" (%d) exceeds total lines in source file (%d).'] := 'Eroare: "De la linia" (%d) depaseste numarul total de linii din fisierul sursă (%d).';
  GTextHungarian.Values['Error: "From line" (%d) exceeds total lines in source file (%d).'] := 'Hiba: "Ettol a sortol" (%d) meghaladja a forrasfajlban levo soroksszamat (%d).';
  GTextCzech.Values['Error: "From line" (%d) exceeds total lines in source file (%d).'] := 'Chyba: "Od radku" (%d) prekracuje celkovy pocet radku ve zdrojovem souboru (%d).';
  GTextPortuguesePT.Values['Error: "From line" (%d) exceeds total lines in source file (%d).'] := 'Erro: "Da linha" (%d) excede o total de linhas no ficheiro de origem (%d).';

  GTextEnglish.Values['Error: "To line" (%d) exceeds total lines in source file (%d).'] := 'Error: "To line" (%d) exceeds total lines in source file (%d).';
  GTextPortuguese.Values['Error: "To line" (%d) exceeds total lines in source file (%d).'] := 'Erro: "Ate a linha" (%d) excede o total de linhas no arquivo de origem (%d).';
  GTextSpanish.Values['Error: "To line" (%d) exceeds total lines in source file (%d).'] := 'Error: "Hasta la linea" (%d) excede el numero total de lineas en el archivo de origen (%d).';
  GTextFrench.Values['Error: "To line" (%d) exceeds total lines in source file (%d).'] := 'Erreur: "Jusqu''a la ligne" (%d) depasse le nombre total de lignes du fichier source (%d).';
  GTextGerman.Values['Error: "To line" (%d) exceeds total lines in source file (%d).'] := 'Fehler: "Bis Zeile" (%d) uebersteigt die Gesamtzahl der Zeilen in der Quelldatei (%d).';
  GTextItalian.Values['Error: "To line" (%d) exceeds total lines in source file (%d).'] := 'Errore: "Alla riga" (%d) supera il numero totale di righe nel file sorgente (%d).';
  GTextPolish.Values['Error: "To line" (%d) exceeds total lines in source file (%d).'] := 'Blad: "Do linii" (%d) przekracza calkowita liczbe linii w pliku zrodlowym (%d).';
  GTextRomanian.Values['Error: "To line" (%d) exceeds total lines in source file (%d).'] := 'Eroare: "Pana la linia" (%d) depaseste numarul total de linii din fisierul sursă (%d).';
  GTextHungarian.Values['Error: "To line" (%d) exceeds total lines in source file (%d).'] := 'Hiba: "Eddig a sorig" (%d) meghaladja a forrasfajlban levo soroksszamat (%d).';
  GTextCzech.Values['Error: "To line" (%d) exceeds total lines in source file (%d).'] := 'Chyba: "Do radku" (%d) prekracuje celkovy pocet radku ve zdrojovem souboru (%d).';
  GTextPortuguesePT.Values['Error: "To line" (%d) exceeds total lines in source file (%d).'] := 'Erro: "Ate a linha" (%d) excede o total de linhas no ficheiro de origem (%d).';

  GTextEnglish.Values['Error validating line range: '] := 'Error validating line range: ';
  GTextPortuguese.Values['Error validating line range: '] := 'Erro ao validar o intervalo de linhas: ';
  GTextSpanish.Values['Error validating line range: '] := 'Error al validar el rango de lineas: ';
  GTextFrench.Values['Error validating line range: '] := 'Erreur lors de la validation de la plage de lignes : ';
  GTextGerman.Values['Error validating line range: '] := 'Fehler beim Validieren des Zeilenbereichs: ';
  GTextItalian.Values['Error validating line range: '] := 'Errore nella convalida dell''intervallo di righe: ';
  GTextPolish.Values['Error validating line range: '] := 'Blad podczas sprawdzania zakresu linii: ';
  GTextRomanian.Values['Error validating line range: '] := 'Eroare la validarea intervalului de linii: ';
  GTextHungarian.Values['Error validating line range: '] := 'Hiba a sorartomany ellenorzesekor: ';
  GTextCzech.Values['Error validating line range: '] := 'Chyba pri overovani rozsahu radku: ';
  GTextPortuguesePT.Values['Error validating line range: '] := 'Erro ao validar o intervalo de linhas: ';

  GTextEnglish.Values['Could not replace destination file.'] := 'Could not replace destination file.';
  GTextPortuguese.Values['Could not replace destination file.'] := 'Nao foi possivel substituir o arquivo de destino.';
  GTextSpanish.Values['Could not replace destination file.'] := 'No se pudo reemplazar el archivo de destino.';
  GTextFrench.Values['Could not replace destination file.'] := 'Impossible de remplacer le fichier de destination.';
  GTextGerman.Values['Could not replace destination file.'] := 'Zieldatei konnte nicht ersetzt werden.';
  GTextItalian.Values['Could not replace destination file.'] := 'Impossibile sostituire il file di destinazione.';
  GTextPolish.Values['Could not replace destination file.'] := 'Nie mozna bylo zastapic pliku docelowego.';
  GTextRomanian.Values['Could not replace destination file.'] := 'Fisierul de destinatie nu a putut fi inlocuit.';
  GTextHungarian.Values['Could not replace destination file.'] := 'Az celdatei nem helyettesitheto.';
  GTextCzech.Values['Could not replace destination file.'] := 'Neshlo vymeniti cilovy soubor.';
  GTextPortuguesePT.Values['Could not replace destination file.'] := 'Nao foi possivel substituir o ficheiro de destino.';

  GTextEnglish.Values['Could not finalize merge file rename operation.'] := 'Could not finalize merge file rename operation.';
  GTextPortuguese.Values['Could not finalize merge file rename operation.'] := 'Nao foi possivel finalizar a operacao de renomeacao do arquivo mesclado.';
  GTextSpanish.Values['Could not finalize merge file rename operation.'] := 'No se pudo finalizar la operacion de renombramiento del archivo combinado.';
  GTextFrench.Values['Could not finalize merge file rename operation.'] := 'Impossible de finaliser l''operation de renommage du fichier fusionne.';
  GTextGerman.Values['Could not finalize merge file rename operation.'] := 'Benennungsvorgang fuer zusammengefuehrte Datei konnte nicht abgeschlossen werden.';
  GTextItalian.Values['Could not finalize merge file rename operation.'] := 'Impossibile finalizzare l''operazione di rinomina del file unito.';
  GTextPolish.Values['Could not finalize merge file rename operation.'] := 'Nie mozna bylo zakonczyc operacji zmiany nazwy pliku polaczonego.';
  GTextRomanian.Values['Could not finalize merge file rename operation.'] := 'Operatia de redenumire a fisierului fuzionat nu a putut fi finalizata.';
  GTextHungarian.Values['Could not finalize merge file rename operation.'] := 'Az osszefuzott fajl atnevezesi muveletehez nem lehetett befezni.';
  GTextCzech.Values['Could not finalize merge file rename operation.'] := 'Nelze dokoncit operaci premenovani sloucenoho souboru.';
  GTextPortuguesePT.Values['Could not finalize merge file rename operation.'] := 'Nao foi possivel finalizar a operacao de renomeacao do ficheiro mesclado.';

  GTextEnglish.Values['Merging files...'] := 'Merging files...';
  GTextPortuguese.Values['Merging files...'] := 'Mesclando arquivos...';
  GTextSpanish.Values['Merging files...'] := 'Combinando archivos...';
  GTextFrench.Values['Merging files...'] := 'Fusion des fichiers...';
  GTextGerman.Values['Merging files...'] := 'Dateien werden zusammengefuehrt...';
  GTextItalian.Values['Merging files...'] := 'Unione file in corso...';
  GTextPolish.Values['Merging files...'] := 'Polaczanie plikow...';
  GTextRomanian.Values['Merging files...'] := 'Fuziunea fisierelor in curs...';
  GTextHungarian.Values['Merging files...'] := 'Fajlok osszefuzese folyamatban...';
  GTextCzech.Values['Merging files...'] := 'Slucovani souboru...';
  GTextPortuguesePT.Values['Merging files...'] := 'Mesclagem de ficheiros...';

  GTextEnglish.Values['Merge files error: '] := 'Merge files error: ';
  GTextPortuguese.Values['Merge files error: '] := 'Erro ao mesclar arquivos: ';
  GTextSpanish.Values['Merge files error: '] := 'Error al combinar archivos: ';
  GTextFrench.Values['Merge files error: '] := 'Erreur de fusion des fichiers : ';
  GTextGerman.Values['Merge files error: '] := 'Fehler beim Zusammenfuehren von Dateien: ';
  GTextItalian.Values['Merge files error: '] := 'Errore unione file: ';
  GTextPolish.Values['Merge files error: '] := 'Blad komunikacji plikow: ';
  GTextRomanian.Values['Merge files error: '] := 'Eroare fuziune fisiere: ';
  GTextHungarian.Values['Merge files error: '] := 'Hiba az fajl osszefuzese soran: ';
  GTextCzech.Values['Merge files error: '] := 'Chyba pri slucovani souboru: ';
  GTextPortuguesePT.Values['Merge files error: '] := 'Erro ao mesclar ficheiros: ';
end;

procedure AddFinalRomanianCzechOverrides;
begin
  { Final RO/CS stable overrides (last assignment wins in Delphi 7 ANSI) }
  GTextRomanian.Values['Read'] := 'Citire';
  GTextRomanian.Values['&File'] := '&Fisier';
  GTextCzech.Values['Read'] := 'Cteni';

  GTextRomanian.Values['&Options'] := '&Optiuni';
  GTextRomanian.Values['&Help'] := '&Ajutor';
  GTextRomanian.Values['&Help / Shortcuts'] := '&Ajutor / Comenzi rapide';
  GTextRomanian.Values['Find Files'] := 'Gaseste fisiere';
  GTextRomanian.Values['Name && Location'] := 'Nume && Locatie';

  GTextCzech.Values['&Options'] := '&Moznosti';
  GTextCzech.Values['&Help'] := '&Napoveda';
  GTextCzech.Values['&Help / Shortcuts'] := '&Napoveda / Zkratky';
  GTextCzech.Values['Find Files'] := 'Hledat soubory';
  GTextCzech.Values['Name && Location'] := 'Nazev && Umisteni';

  GTextRomanian.Values['File Name (Separate multiple names with semicolon):'] := 'Nume fisier (separati mai multe nume cu punct si virgula):';
  GTextRomanian.Values['Location (Separate multiple directories with semicolon):'] := 'Locatie (separati mai multe directoare cu punct si virgula):';
  GTextRomanian.Values['Content:'] := 'Continut:';
  GTextRomanian.Values['Include subfolders'] := 'Include subfoldere';
  GTextRomanian.Values['Case Sensitive'] := 'Diferentiaza majuscule';
  GTextRomanian.Values['Whole Word'] := 'Cuvant intreg';
  GTextRomanian.Values['Excluded'] := 'Exclus';
  GTextRomanian.Values['Threaded Search'] := 'Cautare pe thread';
  GTextRomanian.Values['Find'] := 'Cauta';
  GTextRomanian.Values['Stop'] := 'Stop';
  GTextRomanian.Values['Folders exclude'] := 'Exclude foldere';

  GTextCzech.Values['File Name (Separate multiple names with semicolon):'] := 'Nazev souboru (vice nazvu oddelte strednikem):';
  GTextCzech.Values['Location (Separate multiple directories with semicolon):'] := 'Umisteni (vice slozek oddelte strednikem):';
  GTextCzech.Values['Content:'] := 'Obsah:';
  GTextCzech.Values['Include subfolders'] := 'Vcetne podslozek';
  GTextCzech.Values['Case Sensitive'] := 'Rozlisovat velka/mala';
  GTextCzech.Values['Whole Word'] := 'Cele slovo';
  GTextCzech.Values['Excluded'] := 'Vylouceno';
  GTextCzech.Values['Threaded Search'] := 'Vlaknove hledani';
  GTextCzech.Values['Find'] := 'Hledat';
  GTextCzech.Values['Stop'] := 'Stop';
  GTextCzech.Values['Folders exclude'] := 'Vyloucit slozky';

  { Merge files feature for PL/PT-PT/RO/HU/CZ }
  GTextPolish.Values['Merge &files...'] := 'Scal &pliki...';
  GTextPortuguesePT.Values['Merge &files...'] := 'Juntar &ficheiros...';
  GTextRomanian.Values['Merge &files...'] := '&Uneste fisiere...';
  GTextHungarian.Values['Merge &files...'] := 'Fajlok &egyesitese...';
  GTextCzech.Values['Merge &files...'] := 'Sloucit &soubory...';

  GTextPolish.Values['Merge files'] := 'Scal pliki';
  GTextPortuguesePT.Values['Merge files'] := 'Juntar ficheiros';
  GTextRomanian.Values['Merge files'] := 'Uneste fisiere';
  GTextHungarian.Values['Merge files'] := 'Fajlok egyesitese';
  GTextCzech.Values['Merge files'] := 'Sloucit soubory';

  GTextPolish.Values['Confirm'] := 'Potwierdz';
  GTextPortuguesePT.Values['Confirm'] := 'Confirmar';
  GTextRomanian.Values['Confirm'] := 'Confirma';
  GTextHungarian.Values['Confirm'] := 'Megerosit';
  GTextCzech.Values['Confirm'] := 'Potvrdit';

  GTextPolish.Values['Merging files...'] := 'Scalanie plikow...';
  GTextPortuguesePT.Values['Merging files...'] := 'A juntar ficheiros...';
  GTextRomanian.Values['Merging files...'] := 'Se unesc fisierele...';
  GTextHungarian.Values['Merging files...'] := 'Fajlok egyesitese...';
  GTextCzech.Values['Merging files...'] := 'Slucovani souboru...';

  GTextPolish.Values['Merge files error: '] := 'Blad scalania plikow: ';
  GTextPortuguesePT.Values['Merge files error: '] := 'Erro ao juntar ficheiros: ';
  GTextRomanian.Values['Merge files error: '] := 'Eroare la unirea fisierelor: ';
  GTextHungarian.Values['Merge files error: '] := 'Fajlegyesitesi hiba: ';
  GTextCzech.Values['Merge files error: '] := 'Chyba slouceni souboru: ';

  GTextPolish.Values['You can drag and drop the source file into this window.'] := 'Mozesz przeciagnac i upuscic plik zrodlowy do tego okna.';
  GTextPortuguesePT.Values['You can drag and drop the source file into this window.'] := 'Pode arrastar e largar o ficheiro de origem nesta janela.';
  GTextRomanian.Values['You can drag and drop the source file into this window.'] := 'Puteti trage si plasa fisierul sursa in aceasta fereastra.';
  GTextHungarian.Values['You can drag and drop the source file into this window.'] := 'Behuzhatja a forrasfajlt ebbe az ablakba.';
  GTextCzech.Values['You can drag and drop the source file into this window.'] := 'Zdrojovy soubor muzete pretahnout do tohoto okna.';
end;

procedure AddCommonTranslationsGTextFromFiveNewLangsToBeforeSpanish;
begin
  { --- G* table entries for 5 new languages -------------------------------- }
  GPolish.Values['status.system_ready']            := 'System gotowy';
  GPortuguesePT.Values['status.system_ready']      := 'Sistema pronto';
  GRomanian.Values['status.system_ready']          := 'Sistem preg'#227'tit';
  GHungarian.Values['status.system_ready']         := 'Rendszer k'#233'sz';
  GCzech.Values['status.system_ready']             := 'Syst'#233'm p'#248'ipraven';

  GPolish.Values['popup.listview.read']            := 'Czytaj';
  GPortuguesePT.Values['popup.listview.read']      := 'Ler';
  GRomanian.Values['popup.listview.read']          := 'Cite'#186'te';
  GHungarian.Values['popup.listview.read']         := 'Olvas';
  GCzech.Values['popup.listview.read']             := #200'ti';

  GPolish.Values['popup.listview.separator']       := '-';
  GPortuguesePT.Values['popup.listview.separator'] := '-';
  GRomanian.Values['popup.listview.separator']     := '-';
  GHungarian.Values['popup.listview.separator']    := '-';
  GCzech.Values['popup.listview.separator']        := '-';

  GPolish.Values['popup.listview.write']           := 'Zapisz';
  GPortuguesePT.Values['popup.listview.write']     := 'Escrever';
  GRomanian.Values['popup.listview.write']         := 'Scrie';
  GHungarian.Values['popup.listview.write']        := #205'r';
  GCzech.Values['popup.listview.write']            := 'Zapsat';

  GPolish.Values['popup.listview.split_files']           := 'Podziel pliki';
  GPortuguesePT.Values['popup.listview.split_files']     := 'Dividir ficheiros';
  GRomanian.Values['popup.listview.split_files']         := #206'mparte fi'#186'ierele';
  GHungarian.Values['popup.listview.split_files']        := 'F'#225'jlok feloszt'#225'sa';
  GCzech.Values['popup.listview.split_files']            := 'Rozd'#236'lit soubory';

  GPolish.Values['popup.listview.show_checkboxes']       := 'Poka'#191' pola wyboru';
  GPortuguesePT.Values['popup.listview.show_checkboxes'] := 'Mostrar caixas de verifica'#231#227'o';
  GRomanian.Values['popup.listview.show_checkboxes']     := 'Arat'#227' casete';
  GHungarian.Values['popup.listview.show_checkboxes']    := 'Jel'#246'l'#245'n'#233'gyzetek mutat'#225'sa';
  GCzech.Values['popup.listview.show_checkboxes']        := 'Zobrazit za'#232'krt'#225'vac'#237' pol'#237'';

  GPolish.Values['popup.listview.delete_lines']          := 'Usu'#241' wiersze';
  GPortuguesePT.Values['popup.listview.delete_lines']    := 'Eliminar linhas';
  GRomanian.Values['popup.listview.delete_lines']        := #170'tergere linii';
  GHungarian.Values['popup.listview.delete_lines']       := 'Sorok t'#246'rl'#233'se';
  GCzech.Values['popup.listview.delete_lines']           := 'Smazat '#248#225'dky';

  GPolish.Values['popup.listview.clear']           := 'Wyczy'#156#230'';
  GPortuguesePT.Values['popup.listview.clear']     := 'Limpar';
  GRomanian.Values['popup.listview.clear']         := 'Golit';
  GHungarian.Values['popup.listview.clear']        := 'T'#246'rl'#233's';
  GCzech.Values['popup.listview.clear']            := 'Vymazat';

  GPolish.Values['popup.listview.export_clipboard']      := 'Eksportuj do schowka';
  GPortuguesePT.Values['popup.listview.export_clipboard']:= 'Exportar para a '#193'rea de Transfer'#234'ncia';
  GRomanian.Values['popup.listview.export_clipboard']    := 'Export'#227' '#238'n clipboard';
  GHungarian.Values['popup.listview.export_clipboard']   := 'Export'#225'l'#225's v'#225'g'#243'lapra';
  GCzech.Values['popup.listview.export_clipboard']       := 'Exportovat do schr'#225'nky';

  GPolish.Values['popup.listview.export_file']           := 'Eksportuj do pliku';
  GPortuguesePT.Values['popup.listview.export_file']     := 'Exportar para ficheiro';
  GRomanian.Values['popup.listview.export_file']         := 'Export'#227' '#238'n fi'#186'ier';
  GHungarian.Values['popup.listview.export_file']        := 'Export'#225'l'#225's f'#225'jlba';
  GCzech.Values['popup.listview.export_file']            := 'Exportovat do souboru';

  GPolish.Values['language.combo.hint']            := 'J'#234'zyk aplikacji';
  GPortuguesePT.Values['language.combo.hint']      := 'Idioma da aplica'#231#227'o';
  GRomanian.Values['language.combo.hint']          := 'Limba aplica'#254'iei';
  GHungarian.Values['language.combo.hint']         := 'Alkalmaz'#225's nyelve';
  GCzech.Values['language.combo.hint']             := 'Jazyk aplikace';

  GPolish.Values['toolbar.top_toolbar_tab']        := 'Pasek narz'#234'dzi';
  GPortuguesePT.Values['toolbar.top_toolbar_tab']  := 'Barra de ferramentas';
  GRomanian.Values['toolbar.top_toolbar_tab']      := 'Bara de instrumente';
  GHungarian.Values['toolbar.top_toolbar_tab']     := 'Eszk'#246'zt'#225'r';
  GCzech.Values['toolbar.top_toolbar_tab']         := 'Panel n'#225'stroj'#249'';

  GPolish.Values['toolbar.find_files']             := 'Znajd'#159' pliki';
  GPortuguesePT.Values['toolbar.find_files']       := 'Localizar ficheiros';
  GRomanian.Values['toolbar.find_files']           := 'Gaseste fisiere';
  GHungarian.Values['toolbar.find_files']          := 'F'#225'jlok keres'#233'se';
  GCzech.Values['toolbar.find_files']              := 'Hledat soubory';

  GPolish.Values['toolbar.close']                  := 'Zamknij';
  GPortuguesePT.Values['toolbar.close']            := 'Fechar';
  GRomanian.Values['toolbar.close']                := #206'nchide';
  GHungarian.Values['toolbar.close']               := 'Bez'#225'r'#225's';
  GCzech.Values['toolbar.close']                   := 'Zav'#237't';

  GPolish.Values['toolbar.word_wrap_on']           := 'Zawijanie wierszy (ON)';
  GPortuguesePT.Values['toolbar.word_wrap_on']     := 'Quebra de linha (ON)';
  GRomanian.Values['toolbar.word_wrap_on']         := #206'nf'#227#186'urare text (ON)';
  GHungarian.Values['toolbar.word_wrap_on']        := 'Sz'#243't'#246'r'#233's (BE)';
  GCzech.Values['toolbar.word_wrap_on']            := 'Zalamov'#225'n'#237' slov (ZAP)';

  GPolish.Values['toolbar.about_fastfile']         := 'O programie FastFile';
  GPortuguesePT.Values['toolbar.about_fastfile']   := 'Sobre o FastFile';
  GRomanian.Values['toolbar.about_fastfile']       := 'Despre FastFile';
  GHungarian.Values['toolbar.about_fastfile']      := 'A FastFile-r'#243'l';
  GCzech.Values['toolbar.about_fastfile']          := 'O aplikaci FastFile';

  GPolish.Values['toolbar.select_skin']            := 'Wybierz'#13#10'sk'#243'rk'#234'';
  GPortuguesePT.Values['toolbar.select_skin']      := 'Selecionar'#13#10'Tema';
  GRomanian.Values['toolbar.select_skin']          := 'Selecteaz'#227#13#10'tem'#227'';
  GHungarian.Values['toolbar.select_skin']         := 'T'#233'ma'#13#10'v'#225'laszt'#225's';
  GCzech.Values['toolbar.select_skin']             := 'Vybrat'#13#10't'#233'ma';

  GPolish.Values['toolbar.change_bidimode']        := 'Zmie'#241#13#10'BidiMode';
  GPortuguesePT.Values['toolbar.change_bidimode']  := 'Mudar'#13#10'BidiMode';
  GRomanian.Values['toolbar.change_bidimode']      := 'Schimb'#227#13#10'BidiMode';
  GHungarian.Values['toolbar.change_bidimode']     := 'V'#225'ltoz'#225's'#13#10'BidiMode';
  GCzech.Values['toolbar.change_bidimode']         := 'Zm'#236'nit'#13#10'BidiMode';

  GPolish.Values['titlebar.about']                 := 'O programie';
  GPortuguesePT.Values['titlebar.about']           := 'Sobre';
  GRomanian.Values['titlebar.about']               := 'Despre';
  GHungarian.Values['titlebar.about']              := 'N'#233'vjegy';
  GCzech.Values['titlebar.about']                  := 'O aplikaci';

  GPolish.Values['titlebar.tools']                 := 'Narz'#234'dzia';
  GPortuguesePT.Values['titlebar.tools']           := 'Ferramentas';
  GRomanian.Values['titlebar.tools']               := 'Instrumente';
  GHungarian.Values['titlebar.tools']              := 'Eszk'#246'z'#246'k';
  GCzech.Values['titlebar.tools']                  := 'N'#225'stroje';

  GPolish.Values['popup.select_skin']              := 'Wybierz sk'#243'rk'#234'';
  GPortuguesePT.Values['popup.select_skin']        := 'Selecionar tema';
  GRomanian.Values['popup.select_skin']            := 'Selecteaz'#227' tem'#227'';
  GHungarian.Values['popup.select_skin']           := 'T'#233'ma kiv'#225'laszt'#225'sa';
  GCzech.Values['popup.select_skin']               := 'Vybrat t'#233'ma';

  GPolish.Values['popup.random_skin']              := 'Losowa sk'#243'rka';
  GPortuguesePT.Values['popup.random_skin']        := 'Tema aleat'#243'rio';
  GRomanian.Values['popup.random_skin']            := 'Tem'#227' aleatorie';
  GHungarian.Values['popup.random_skin']           := 'V'#233'letlenszer'#251' t'#233'ma';
  GCzech.Values['popup.random_skin']               := 'N'#225'hodn'#233' t'#233'ma';

  GPolish.Values['popup.show_hints']               := 'Poka'#191' podpowiedzi';
  GPortuguesePT.Values['popup.show_hints']         := 'Mostrar dicas';
  GRomanian.Values['popup.show_hints']             := 'Arat'#227' indicii';
  GHungarian.Values['popup.show_hints']            := 'Tippek mutat'#225'sa';
  GCzech.Values['popup.show_hints']                := 'Zobrazit n'#225'pov'#236'dy';

  GPolish.Values['popup.change_bidimode']          := 'Zmie'#241' BidiMode';
  GPortuguesePT.Values['popup.change_bidimode']    := 'Mudar BidiMode';
  GRomanian.Values['popup.change_bidimode']        := 'Schimb'#227' BidiMode';
  GHungarian.Values['popup.change_bidimode']       := 'BidiMode v'#225'ltoz'#225'sa';
  GCzech.Values['popup.change_bidimode']           := 'Zm'#236'nit BidiMode';

  GPolish.Values['popup.selectskin_dialog']        := 'Okno wyboru sk'#243'rki';
  GPortuguesePT.Values['popup.selectskin_dialog']  := 'Di'#225'logo de tema';
  GRomanian.Values['popup.selectskin_dialog']      := 'Dialog alegere tem'#227'';
  GHungarian.Values['popup.selectskin_dialog']     := 'T'#233'mav'#225'laszt'#243' ablak';
  GCzech.Values['popup.selectskin_dialog']         := 'Dialog v'#253'b'#236'ru t'#233'matu';

  GPolish.Values['popup.magnifier']                := 'Lupa';
  GPortuguesePT.Values['popup.magnifier']          := 'Lupa';
  GRomanian.Values['popup.magnifier']              := 'Lup'#227'';
  GHungarian.Values['popup.magnifier']             := 'Nagy'#237't'#243'';
  GCzech.Values['popup.magnifier']                 := 'Lupa';

  GPolish.Values['popup.calculator']               := 'Kalkulator';
  GPortuguesePT.Values['popup.calculator']         := 'Calculadora';
  GRomanian.Values['popup.calculator']             := 'Calculator';
  GHungarian.Values['popup.calculator']            := 'Sz'#225'mol'#243'g'#233'p';
  GCzech.Values['popup.calculator']                := 'Kalkul'#225'torka';
  GPortuguese.Values['language.combo.hint'] := 'Idioma da aplica'#231#227'o';
  GSpanish.Values['language.combo.hint'] := 'Idioma de la aplicaci'#243'n';
  GFrench.Values['language.combo.hint'] := 'Langue de l''application';
  GGerman.Values['language.combo.hint'] := 'Anwendungssprache';
  GItalian.Values['language.combo.hint'] := 'Lingua dell''applicazione';

  GTextEnglish.Values['Line parameters are required.'] := 'Line parameters are required.';
  GTextPortuguese.Values['Line parameters are required.'] := 'Par'#226'metros de linha s'#227'o obrigat'#243'rios.';

  GTextEnglish.Values['Enter search text.'] := 'Enter text to find.';
  GTextPortuguese.Values['Enter search text.'] := 'Digite o texto para localizar.';

  GTextEnglish.Values['Line Number is required.'] := 'Line Number is required.';
  GTextPortuguese.Values['Line Number is required.'] := 'N'#250'mero da linha '#233' obrigat'#243'rio.';

  GTextEnglish.Values['Please enter a valid line number.'] := 'Please enter a valid line number.';
  GTextPortuguese.Values['Please enter a valid line number.'] := 'Informe um n'#250'mero de linha v'#225'lido.';

  GTextEnglish.Values['Line number must be greater than 0.'] := 'Line number must be greater than 0.';
  GTextPortuguese.Values['Line number must be greater than 0.'] := 'O n'#250'mero da linha deve ser maior que 0.';

  GTextEnglish.Values['Please select a line first.'] := 'Please select a line first.';
  GTextPortuguese.Values['Please select a line first.'] := 'Selecione uma linha primeiro.';

  GTextEnglish.Values['Please select a file.'] := 'Please select a file.';
  GTextPortuguese.Values['Please select a file.'] := 'Selecione um arquivo.';

  GTextEnglish.Values['Please select a file first.'] := 'Please select a file first.';
  GTextPortuguese.Values['Please select a file first.'] := 'Selecione um arquivo primeiro.';

  GTextEnglish.Values['Please read the file first.'] := 'Please read the file first.';
  GTextPortuguese.Values['Please read the file first.'] := 'Leia o arquivo primeiro.';

  GTextEnglish.Values['Please read a file first.'] := 'Please read a file first.';
  GTextPortuguese.Values['Please read a file first.'] := 'Leia um arquivo primeiro.';

  GTextEnglish.Values['File not found.'] := 'File not found.';
  GTextPortuguese.Values['File not found.'] := 'Arquivo n'#227'o encontrado.';

  GTextEnglish.Values['Text copied to clipboard!'] := 'Text copied to clipboard!';
  GTextPortuguese.Values['Text copied to clipboard!'] := 'Texto copiado para a '#225'rea de transfer'#234'ncia!';

  GTextEnglish.Values['No active filter. Press Ctrl+L first.'] := 'No active filter. Press Ctrl+L first.';
  GTextPortuguese.Values['No active filter. Press Ctrl+L first.'] := 'N'#227'o h'#225' filtro ativo. Pressione Ctrl+L primeiro.';

  GTextEnglish.Values['Filter has no results to export.'] := 'Filter has no results to export.';
  GTextPortuguese.Values['Filter has no results to export.'] := 'O filtro n'#227'o possui resultados para exportar.';

  GTextEnglish.Values['No lines entered. Operation cancelled.'] := 'No lines entered. Operation cancelled.';
  GTextPortuguese.Values['No lines entered. Operation cancelled.'] := 'Nenhuma linha informada. Opera'#231#227'o cancelada.';

  GTextEnglish.Values['Cannot sort the list while a search is in progress.'] := 'Cannot sort the list while a find operation is in progress.';
  GTextPortuguese.Values['Cannot sort the list while a search is in progress.'] := 'N'#227'o '#233' poss'#237'vel ordenar a lista enquanto uma pesquisa est'#225' em andamento.';

  GTextEnglish.Values['Hide the watermark?'] := 'Hide the watermark?';
  GTextPortuguese.Values['Hide the watermark?'] := 'Ocultar a marca d'''#225'gua?';

  GTextEnglish.Values['Operation'] := 'Operation';
  GTextPortuguese.Values['Operation'] := 'Opera'#231#227'o';

  GTextEnglish.Values['Insert Line'] := 'Insert Line';
  GTextPortuguese.Values['Insert Line'] := 'Inserir linha';

  GTextEnglish.Values['Edit Line'] := 'Edit Line';
  GTextPortuguese.Values['Edit Line'] := 'Editar linha';

  GTextEnglish.Values['Delete Line'] := 'Delete Line';
  GTextPortuguese.Values['Delete Line'] := 'Excluir linha';

  GTextEnglish.Values['Find and Replace'] := 'Find and Replace';
  GTextPortuguese.Values['Find and Replace'] := 'Localizar e substituir';

  GTextEnglish.Values['Find what:'] := 'Find what:';
  GTextPortuguese.Values['Find what:'] := 'Localizar:';

  GTextEnglish.Values['Replace with:'] := 'Replace with:';
  GTextPortuguese.Values['Replace with:'] := 'Substituir por:';

  GTextEnglish.Values['Case sensitive'] := 'Case sensitive';
  GTextPortuguese.Values['Case sensitive'] := 'Diferenciar mai'#250'sculas e min'#250'sculas';

  GTextEnglish.Values['Whole word'] := 'Whole word';
  GTextPortuguese.Values['Whole word'] := 'Palavra inteira';

  GTextEnglish.Values['Find Next'] := 'Find Next';
  GTextPortuguese.Values['Find Next'] := 'Localizar pr'#243'ximo';

  GTextEnglish.Values['Replace'] := 'Replace';
  GTextPortuguese.Values['Replace'] := 'Substituir';

  GTextEnglish.Values['Replace All'] := 'Replace All';
  GTextPortuguese.Values['Replace All'] := 'Substituir tudo';

  GTextEnglish.Values['Close'] := 'Close';
  GTextPortuguese.Values['Close'] := 'Fechar';

  { Find/Replace dialog buttons (mnemonics for Alt+letter) }
  GTextEnglish.Values['Find &Next'] := 'Find &Next';
  GTextPortuguese.Values['Find &Next'] := 'Locali&zar pr'#243'ximo';
  GTextSpanish.Values['Find &Next'] := 'Buscar &siguiente';
  GTextFrench.Values['Find &Next'] := 'S&uivant';
  GTextGerman.Values['Find &Next'] := '&N'#228'chstes';
  GTextItalian.Values['Find &Next'] := 'Tro&va successivo';
  GTextPolish.Values['Find &Next'] := 'Znajd'#378' &nast'#281'pne';
  GTextPortuguesePT.Values['Find &Next'] := 'Locali&zar pr'#243'ximo';
  GTextRomanian.Values['Find &Next'] := 'G'#259'se'#537'te &urm'#259'torul';
  GTextHungarian.Values['Find &Next'] := '&K'#246'vetkez'#337' keres'#233'se';
  GTextCzech.Values['Find &Next'] := 'Naj'#237't &dal'#185#237;

  GTextEnglish.Values['&Replace'] := '&Replace';
  GTextPortuguese.Values['&Replace'] := '&Substituir';
  GTextSpanish.Values['&Replace'] := '&Reemplazar';
  GTextFrench.Values['&Replace'] := '&Remplacer';
  GTextGerman.Values['&Replace'] := '&Ersetzen';
  GTextItalian.Values['&Replace'] := '&Sostituisci';
  GTextPolish.Values['&Replace'] := '&Zamie'#241'n';
  GTextPortuguesePT.Values['&Replace'] := '&Substituir';
  GTextRomanian.Values['&Replace'] := 'Î&nlocui'#539'e';
  GTextHungarian.Values['&Replace'] := '&Csere';
  GTextCzech.Values['&Replace'] := '&Nahradit';

  GTextEnglish.Values['Replace A&ll'] := 'Replace A&ll';
  GTextPortuguese.Values['Replace A&ll'] := 'Substituir t&udo';
  GTextSpanish.Values['Replace A&ll'] := 'Reemplazar t&odo';
  GTextFrench.Values['Replace A&ll'] := 'Remplacer t&out';
  GTextGerman.Values['Replace A&ll'] := 'Alle erse&tzen';
  GTextItalian.Values['Replace A&ll'] := 'Sostituisci t&utto';
  GTextPolish.Values['Replace A&ll'] := 'Zamie'#241'n &wszystko';
  GTextPortuguesePT.Values['Replace A&ll'] := 'Substituir t&udo';
  GTextRomanian.Values['Replace A&ll'] := 'Înlocuie'#537'te &tot';
  GTextHungarian.Values['Replace A&ll'] := 'Összes cse&re';
  GTextCzech.Values['Replace A&ll'] := 'Nahradit &v'#185'e';

  GTextEnglish.Values['&Close'] := '&Close';
  GTextPortuguese.Values['&Close'] := 'Fe&char';
  GTextSpanish.Values['&Close'] := '&Cerrar';
  GTextFrench.Values['&Close'] := '&Fermer';
  GTextGerman.Values['&Close'] := '&Schlie'#223'en';
  GTextItalian.Values['&Close'] := '&Chiudi';
  GTextPolish.Values['&Close'] := '&Zamknij';
  GTextPortuguesePT.Values['&Close'] := 'Fe&char';
  GTextRomanian.Values['&Close'] := 'Înch&ide';
  GTextHungarian.Values['&Close'] := '&Bez'#225'r'#225's';
  GTextCzech.Values['&Close'] := '&Zav'#248#237't';

  GTextEnglish.Values['D&uplicate line'] := 'D&uplicate line';
  GTextPortuguese.Values['D&uplicate line'] := 'D&uplicar linha';
  GTextSpanish.Values['D&uplicate line'] := 'D&uplicar l'#237'nea';
  GTextFrench.Values['D&uplicate line'] := 'D&upliquer la ligne';
  GTextGerman.Values['D&uplicate line'] := 'Zeile d&uplizieren';
  GTextItalian.Values['D&uplicate line'] := 'D&uplica riga';
  GTextPolish.Values['D&uplicate line'] := 'D&uplikuj lini'#281;
  GTextPortuguesePT.Values['D&uplicate line'] := 'D&uplicar linha';
  GTextRomanian.Values['D&uplicate line'] := 'D&uplicare linie';
  GTextHungarian.Values['D&uplicate line'] := 'Sor d&uplik'#225'l'#225'sa';
  GTextCzech.Values['D&uplicate line'] := 'D&uplikovat '#248#224'dkek';

  GTextEnglish.Values['File Line Editor'] := 'File Line Editor';
  GTextPortuguese.Values['File Line Editor'] := 'Editor de linha de arquivo';

  GTextEnglish.Values['Operation:'] := 'Operation:';
  GTextPortuguese.Values['Operation:'] := 'Opera'#231#227'o:';

  GTextEnglish.Values['Line Number:'] := 'Line Number:';
  GTextPortuguese.Values['Line Number:'] := 'N'#250'mero da linha:';

  GTextEnglish.Values['Content:'] := 'Content:';
  GTextPortuguese.Values['Content:'] := 'Conte'#250'do:';

  GTextEnglish.Values['Confirm'] := 'Confirm';
  GTextPortuguese.Values['Confirm'] := 'Confirmar';

  GTextEnglish.Values['Cancel'] := 'Cancel';
  GTextPortuguese.Values['Cancel'] := 'Cancelar';

  GTextEnglish.Values['Application language'] := 'Application language';
  GTextPortuguese.Values['Application language'] := 'Idioma da aplica'#231#227'o';

  GTextEnglish.Values['Export Lines'] := 'Export Lines';
  GTextPortuguese.Values['Export Lines'] := 'Exportar linhas';

  GTextEnglish.Values['Enter the lines to export (e.g. 1-4 or 1,4,10):'] := 'Enter the lines to export (e.g. 1-4 or 1,4,10):';
  GTextPortuguese.Values['Enter the lines to export (e.g. 1-4 or 1,4,10):'] := 'Informe as linhas para exportar (ex.: 1-4 ou 1,4,10):';

  GTextEnglish.Values['Delimiters: "-" for ranges, "," or ";" for specific lines.'#13'Spaces are ignored.'] := 'Delimiters: "-" for ranges, "," or ";" for specific lines.'#13'Spaces are ignored.';
  GTextPortuguese.Values['Delimiters: "-" for ranges, "," or ";" for specific lines.'#13'Spaces are ignored.'] := 'Delimitadores: "-" para intervalos, "," ou ";" para linhas espec'#237'ficas.'#13'Espa'#231'os s'#227'o ignorados.';

  GTextEnglish.Values['Save to text file instead of clipboard'] := 'Save to text file instead of clipboard';
  GTextPortuguese.Values['Save to text file instead of clipboard'] := 'Salvar em arquivo texto em vez da '#225'rea de transfer'#234'ncia';

  GTextEnglish.Values['Export'] := 'Export';
  GTextPortuguese.Values['Export'] := 'Exportar';

  GTextEnglish.Values['Delta File Editor'] := 'Delta File Editor';
  GTextPortuguese.Values['Delta File Editor'] := 'Editor de arquivo delta';

  GTextEnglish.Values['Add/Update'] := 'Add/Update';
  GTextPortuguese.Values['Add/Update'] := 'Adicionar/Atualizar';

  GTextEnglish.Values['Delete'] := 'Delete';
  GTextPortuguese.Values['Delete'] := 'Excluir';

  GTextEnglish.Values['Line '] := 'Line ';
  GTextPortuguese.Values['Line '] := 'Linha ';

  GTextEnglish.Values[' updated successfully.'] := ' updated successfully.';
  GTextPortuguese.Values[' updated successfully.'] := ' atualizada com sucesso.';

  GTextEnglish.Values[' line(s) copied to clipboard.'] := ' line(s) copied to clipboard.';
  GTextPortuguese.Values[' line(s) copied to clipboard.'] := ' linha(s) copiada(s) para a '#225'rea de transfer'#234'ncia.';

  GTextEnglish.Values['Search'] := 'Find';
  GTextPortuguese.Values['Search'] := 'Localizar';

  GTextEnglish.Values['Type the text to search:'] := 'Type the text to find:';
  GTextPortuguese.Values['Type the text to search:'] := 'Digite o texto para localizar:';

  GTextEnglish.Values['Case sensitive search?'] := 'Case sensitive search?';
  GTextPortuguese.Values['Case sensitive search?'] := 'Busca com diferen'#231'a entre mai'#250'sculas e min'#250'sculas?';

  GTextEnglish.Values['(Yes = Case Sensitive / No = Ignore case)'] := '(Yes = Case Sensitive / No = Ignore case)';
  GTextPortuguese.Values['(Yes = Case Sensitive / No = Ignore case)'] := '(Sim = Diferenciar / N'#227'o = Ignorar diferen'#231'a)';

  GTextEnglish.Values['Replaced on line '] := 'Replaced on line ';
  GTextPortuguese.Values['Replaced on line '] := 'Substitu'#237'do na linha ';

  GTextEnglish.Values['No match on current line.'] := 'No match on current line.';
  GTextPortuguese.Values['No match on current line.'] := 'Nenhuma ocorr'#234'ncia na linha atual.';

  GTextEnglish.Values['No match selected. Use Find Next first.'] := 'No match selected. Use Find Next first.';
  GTextPortuguese.Values['No match selected. Use Find Next first.'] := 'Nenhuma ocorr'#234'ncia selecionada. Use Localizar pr'#243'ximo primeiro.';

  GTextEnglish.Values['Replace all occurrences of "'] := 'Replace all occurrences of "';
  GTextPortuguese.Values['Replace all occurrences of "'] := 'Substituir todas as ocorr'#234'ncias de "';

  GTextEnglish.Values['This operation cannot be undone.'] := 'This operation cannot be undone.';
  GTextPortuguese.Values['This operation cannot be undone.'] := 'Esta opera'#231#227'o n'#227'o pode ser desfeita.';

  GTextEnglish.Values['Confirm the operation?'] := 'Confirm the operation?';
  GTextPortuguese.Values['Confirm the operation?'] := 'Confirmar a opera'#231#227'o?';

  GTextEnglish.Values['Line: '] := 'Line: ';
  GTextPortuguese.Values['Line: '] := 'Linha: ';

  GTextEnglish.Values['Do you want to continue?'] := 'Do you want to continue?';
  GTextPortuguese.Values['Do you want to continue?'] := 'Deseja continuar?';

  GTextEnglish.Values['Read'] := 'Read';
  GTextPortuguese.Values['Read'] := 'Ler';
  GTextEnglish.Values['Split Files'] := 'Split Files';
  GTextPortuguese.Values['Split Files'] := 'Dividir arquivos';
  GTextEnglish.Values['Merge lines'] := 'Merge lines';
  GTextPortuguese.Values['Merge lines'] := 'Mesclar linhas';
  GTextEnglish.Values['Select'] := 'Select';
  GTextPortuguese.Values['Select'] := 'Selecionar';
  GTextEnglish.Values['Clear'] := 'Clear';
  GTextPortuguese.Values['Clear'] := 'Limpar';
  GTextEnglish.Values['Edit'] := 'Edit';
  GTextPortuguese.Values['Edit'] := 'Editar';
  GTextEnglish.Values['Delete lines (batch)'] := 'Delete lines (batch)';
  GTextPortuguese.Values['Delete lines (batch)'] := 'Excluir linhas (lote)';
  GTextEnglish.Values['Export'] := 'Export';
  GTextPortuguese.Values['Export'] := 'Exportar';
  GTextEnglish.Values['Close'] := 'Close';
  GTextPortuguese.Values['Close'] := 'Fechar';
  GTextEnglish.Values['AI'] := 'AI';
  GTextPortuguese.Values['AI'] := 'IA';
  GTextEnglish.Values['Help'] := 'Help';
  GTextPortuguese.Values['Help'] := 'Ajuda';

  GTextEnglish.Values['Lines/Time:'] := 'Lines/Time:';
  GTextPortuguese.Values['Lines/Time:'] := 'Linhas/Tempo:';
  GTextEnglish.Values['All'] := 'All';
  GTextPortuguese.Values['All'] := 'Todas';
  GTextEnglish.Values['Line:'] := 'Line:';
  GTextPortuguese.Values['Line:'] := 'Linha:';

  GTextEnglish.Values['Search (Enter in search box)'] := 'Find (Enter in search box)';
  GTextPortuguese.Values['Search (Enter in search box)'] := 'Localizar (Enter na caixa de busca)';
  GTextEnglish.Values['Go to top (Ctrl+Home)'] := 'Go to top (Ctrl+Home)';
  GTextPortuguese.Values['Go to top (Ctrl+Home)'] := 'Ir para o in'#237'cio (Ctrl+Home)';
  GTextEnglish.Values['Go to bottom (Ctrl+End)'] := 'Go to bottom (Ctrl+End)';
  GTextPortuguese.Values['Go to bottom (Ctrl+End)'] := 'Ir para o fim (Ctrl+End)';
  GTextEnglish.Values['Enter a word to search in the file'] := 'Enter a word to find in the file';
  GTextPortuguese.Values['Enter a word to search in the file'] := 'Digite uma palavra para localizar no arquivo';
  GTextEnglish.Values['Empty input file'] := 'Empty input file';
  GTextPortuguese.Values['Empty input file'] := 'Esvaziar arquivo de entrada';
  GTextEnglish.Values['Select a file ...'] := 'Select a file ...';
  GTextPortuguese.Values['Select a file ...'] := 'Selecione um arquivo ...';

  GTextEnglish.Values['Open the Read File tab.'] := 'Open the Read File tab.';
  GTextPortuguese.Values['Open the Read File tab.'] := 'Abrir a aba de leitura.';
  GTextEnglish.Values['Open the Find Files tab.'] := 'Open the Find Files tab.';
  GTextPortuguese.Values['Open the Find Files tab.'] := 'Abrir a aba de busca de arquivos.';
  GTextEnglish.Values['Read the selected file and load its lines.'] := 'Read the selected file and load its lines.';
  GTextPortuguese.Values['Read the selected file and load its lines.'] := 'Ler o arquivo selecionado e carregar suas linhas.';
  GTextEnglish.Values['Show help and shortcuts.'] := 'Show help and shortcuts.';
  GTextPortuguese.Values['Show help and shortcuts.'] := 'Mostrar ajuda e atalhos.';
  GTextEnglish.Values['Clear the current input or results.'] := 'Clear the current input or results.';
  GTextPortuguese.Values['Clear the current input or results.'] := 'Limpar a entrada atual ou os resultados.';
  GTextEnglish.Values['Type or choose the file path.'] := 'Type or choose the file path.';
  GTextPortuguese.Values['Type or choose the file path.'] := 'Digite ou selecione o caminho do arquivo.';
  GTextEnglish.Values['Type a value here.'] := 'Type a value here.';
  GTextPortuguese.Values['Type a value here.'] := 'Digite um valor aqui.';
  GTextEnglish.Values['Choose an option from the list.'] := 'Choose an option from the list.';
  GTextPortuguese.Values['Choose an option from the list.'] := 'Escolha uma op'#231#227'o da lista.';
  GTextEnglish.Values['Check to enable this option.'] := 'Check to enable this option.';
  GTextPortuguese.Values['Check to enable this option.'] := 'Marque para habilitar esta op'#231#227'o.';
  GTextEnglish.Values['List of lines and results.'] := 'List of lines and results.';
  GTextPortuguese.Values['List of lines and results.'] := 'Lista de linhas e resultados.';
  GTextEnglish.Values['List of items.'] := 'List of items.';
  GTextPortuguese.Values['List of items.'] := 'Lista de itens.';
  GTextEnglish.Values['Table with results.'] := 'Table with results.';
  GTextPortuguese.Values['Table with results.'] := 'Tabela com resultados.';
  GTextEnglish.Values['Tab content.'] := 'Tab content.';
  GTextPortuguese.Values['Tab content.'] := 'Conte'#250'do da aba.';
  GTextEnglish.Values['Information label.'] := 'Information label.';
  GTextPortuguese.Values['Information label.'] := 'R'#243'tulo informativo.';
  GTextEnglish.Values['Click to execute this action.'] := 'Click to execute this action.';
  GTextPortuguese.Values['Click to execute this action.'] := 'Clique para executar esta a'#231#227'o.';
  GTextEnglish.Values['Information panel.'] := 'Information panel.';
  GTextPortuguese.Values['Information panel.'] := 'Painel de informa'#231#245'es.';

  GTextEnglish.Values['Select the source file to read.'] := 'Select the source file to read.';
  GTextPortuguese.Values['Select the source file to read.'] := 'Selecione o arquivo de origem para leitura.';
  GTextEnglish.Values['Type text to search within loaded lines.'] := 'Type text to find within loaded lines.';
  GTextPortuguese.Values['Type text to search within loaded lines.'] := 'Digite texto para localizar nas linhas carregadas.';
  GTextEnglish.Values['Search for the typed text in the loaded lines.'] := 'Find the typed text in the loaded lines.';
  GTextPortuguese.Values['Search for the typed text in the loaded lines.'] := 'Localizar o texto digitado nas linhas carregadas.';
  GTextEnglish.Values['Jump to a specific line number.'] := 'Jump to a specific line number.';
  GTextPortuguese.Values['Jump to a specific line number.'] := 'Ir para um n'#250'mero de linha espec'#237'fico.';
  GTextEnglish.Values['Navigate quickly through loaded lines.'] := 'Navigate quickly through loaded lines.';
  GTextPortuguese.Values['Navigate quickly through loaded lines.'] := 'Navegar rapidamente pelas linhas carregadas.';
  GTextEnglish.Values['Switch to checkbox selection mode.'] := 'Switch to checkbox selection mode.';
  GTextPortuguese.Values['Switch to checkbox selection mode.'] := 'Alternar para modo de sele'#231#227'o com checkbox.';
  GTextEnglish.Values['Edit selected lines in the file.'] := 'Edit selected lines in the file.';
  GTextPortuguese.Values['Edit selected lines in the file.'] := 'Editar linhas selecionadas no arquivo.';
  GTextEnglish.Values['Delete selected lines from the file.'] := 'Delete selected lines from the file.';
  GTextPortuguese.Values['Delete selected lines from the file.'] := 'Excluir linhas selecionadas do arquivo.';
  GTextEnglish.Values['Export selected lines or results.'] := 'Export selected lines or results.';
  GTextPortuguese.Values['Export selected lines or results.'] := 'Exportar linhas selecionadas ou resultados.';
  GTextEnglish.Values['Open split file tools.'] := 'Open split file tools.';
  GTextPortuguese.Values['Open split file tools.'] := 'Abrir ferramentas de divis'#227'o de arquivo.';
  GTextEnglish.Values['Merge multiple edited lines into the source file.'] := 'Merge multiple edited lines into the source file.';
  GTextPortuguese.Values['Merge multiple edited lines into the source file.'] := 'Mesclar v'#225'rias linhas editadas no arquivo de origem.';
  GTextEnglish.Values['Close the current tab and return to main view.'] := 'Close the current tab and return to main view.';
  GTextPortuguese.Values['Close the current tab and return to main view.'] := 'Fechar a aba atual e voltar para a vis'#227'o principal.';
  GTextEnglish.Values['Type file name patterns to search.'] := 'Type file name patterns to find.';
  GTextPortuguese.Values['Type file name patterns to search.'] := 'Digite padr'#245'es de nome de arquivo para localizar.';
  GTextEnglish.Values['Type folders where files should be searched.'] := 'Type folders where files should be searched.';
  GTextPortuguese.Values['Type folders where files should be searched.'] := 'Digite pastas onde os arquivos devem ser buscados.';
  GTextEnglish.Values['Type text content to find inside files.'] := 'Type text content to find inside files.';
  GTextPortuguese.Values['Type text content to find inside files.'] := 'Digite conte'#250'do de texto para localizar dentro dos arquivos.';
  GTextEnglish.Values['Start searching files with current filters.'] := 'Start finding files with current filters.';
  GTextPortuguese.Values['Start searching files with current filters.'] := 'Iniciar pesquisa de arquivos com os filtros atuais.';
  GTextEnglish.Values['Stop the current file search.'] := 'Stop the current file search.';
  GTextPortuguese.Values['Stop the current file search.'] := 'Parar a busca de arquivos em andamento.';
  GTextEnglish.Values['Include subfolders in file search.'] := 'Include subfolders in file search.';
  GTextPortuguese.Values['Include subfolders in file search.'] := 'Incluir subpastas na busca de arquivos.';
  GTextEnglish.Values['Match uppercase and lowercase exactly.'] := 'Match uppercase and lowercase exactly.';
  GTextPortuguese.Values['Match uppercase and lowercase exactly.'] := 'Diferenciar mai'#250'sculas e min'#250'sculas exatamente.';
  GTextEnglish.Values['Match only whole words.'] := 'Match only whole words.';
  GTextPortuguese.Values['Match only whole words.'] := 'Corresponder apenas palavras inteiras.';
  GTextEnglish.Values['Exclude files that match the entered text.'] := 'Exclude files that match the entered text.';
  GTextPortuguese.Values['Exclude files that match the entered text.'] := 'Excluir arquivos que correspondem ao texto informado.';
  GTextEnglish.Values['Run search in background threads.'] := 'Run search in background threads.';
  GTextPortuguese.Values['Run search in background threads.'] := 'Executar busca em threads de segundo plano.';
  GTextEnglish.Values['List of files found by the current search.'] := 'List of files found by the current search.';
  GTextPortuguese.Values['List of files found by the current search.'] := 'Lista de arquivos encontrados na busca atual.';
  GTextEnglish.Values['First line number to export.'] := 'First line number to export.';
  GTextPortuguese.Values['First line number to export.'] := 'Primeiro n'#250'mero de linha para exportar.';
  GTextEnglish.Values['Last line number to export.'] := 'Last line number to export.';
  GTextPortuguese.Values['Last line number to export.'] := #218'ltimo n'#250'mero de linha para exportar.';
  GTextEnglish.Values['Choose output file name for split by lines.'] := 'Choose output file name for split by lines.';
  GTextPortuguese.Values['Choose output file name for split by lines.'] := 'Escolher o nome do arquivo de sa'#237'da para divis'#227'o por linhas.';
  GTextEnglish.Values['Generate a file using the selected line range.'] := 'Generate a file using the selected line range.';
  GTextPortuguese.Values['Generate a file using the selected line range.'] := 'Gerar arquivo usando o intervalo de linhas selecionado.';
  GTextEnglish.Values['Set how many files should be generated.'] := 'Set how many files should be generated.';
  GTextPortuguese.Values['Set how many files should be generated.'] := 'Defina quantos arquivos devem ser gerados.';
  GTextEnglish.Values['Split source file into multiple files.'] := 'Split source file into multiple files.';
  GTextPortuguese.Values['Split source file into multiple files.'] := 'Dividir arquivo de origem em m'#250'ltiplos arquivos.';
  GTextEnglish.Values['List of generated files and ranges.'] := 'List of generated files and ranges.';
  GTextPortuguese.Values['List of generated files and ranges.'] := 'Lista de arquivos gerados e intervalos.';

  GTextEnglish.Values['Shortcut: '] := 'Shortcut: ';
  GTextPortuguese.Values['Shortcut: '] := 'Atalho: ';

  GTextEnglish.Values['Line: %d  Col: %d'] := 'Line: %d  Col: %d';
  GTextPortuguese.Values['Line: %d  Col: %d'] := 'Linha: %d  Col: %d';

  GTextEnglish.Values['Line: 0  Col: 0'] := 'Line: 0  Col: 0';
  GTextPortuguese.Values['Line: 0  Col: 0'] := 'Linha: 0  Col: 0';

  GTextEnglish.Values['Lines: %d'] := 'Lines: %d';
  GTextPortuguese.Values['Lines: %d'] := 'Linhas: %d';

  GTextEnglish.Values['View: DEFAULT (detected)'] := 'View: DEFAULT (detected)';
  GTextPortuguese.Values['View: DEFAULT (detected)'] := 'Exibi'#231#227'o: PADR'#195'O (detectado)';
  GTextEnglish.Values['View: UTF-8'] := 'View: UTF-8';
  GTextPortuguese.Values['View: UTF-8'] := 'Exibi'#231#227'o: UTF-8';
  GTextEnglish.Values['View: ANSI (raw / system)'] := 'View: ANSI (raw / system)';
  GTextPortuguese.Values['View: ANSI (raw / system)'] := 'Exibi'#231#227'o: ANSI (bruto / sistema)';
  GTextEnglish.Values['View: UTF-16 LE'] := 'View: UTF-16 LE';
  GTextPortuguese.Values['View: UTF-16 LE'] := 'Exibi'#231#227'o: UTF-16 LE';
  GTextEnglish.Values['View: UTF-16 BE'] := 'View: UTF-16 BE';
  GTextPortuguese.Values['View: UTF-16 BE'] := 'Exibi'#231#227'o: UTF-16 BE';

  GTextEnglish.Values['Detected on file: '] := 'Detected on file: ';
  GTextPortuguese.Values['Detected on file: '] := 'Detectado no arquivo: ';

  GTextEnglish.Values['List view uses: '] := 'List view uses: ';
  GTextPortuguese.Values['List view uses: '] := 'A lista usa: ';

  GTextEnglish.Values['Does not re-read file. DEFAULT = BOM/heuristics.'] := 'Does not re-read file. DEFAULT = BOM/heuristics.';
  GTextPortuguese.Values['Does not re-read file. DEFAULT = BOM/heuristics.'] := 'N'#227'o rel'#234' o arquivo. PADR'#195'O = BOM/heur'#237'sticas.';

  GTextEnglish.Values[' (DEFAULT view)'] := ' (DEFAULT view)';
  GTextPortuguese.Values[' (DEFAULT view)'] := ' (vis'#227'o PADR'#195'O)';

  GTextEnglish.Values['Does not re-read file. Pick UTF-8 / ANSI / UTF-16 to force.'] := 'Does not re-read file. Pick UTF-8 / ANSI / UTF-16 to force.';
  GTextPortuguese.Values['Does not re-read file. Pick UTF-8 / ANSI / UTF-16 to force.'] := 'N'#227'o rel'#234' o arquivo. Escolha UTF-8 / ANSI / UTF-16 para for'#231'ar.';

  GTextEnglish.Values['&File'] := '&File';
  GTextPortuguese.Values['&File'] := '&Arquivo';
  GTextEnglish.Values['&Open file...'] := '&Open file...';
  GTextPortuguese.Values['&Open file...'] := '&Abrir arquivo...';
  GTextEnglish.Values['&Recent files'] := '&Recent files';
  GTextPortuguese.Values['&Recent files'] := 'Arquivos &recentes';
  GTextEnglish.Values['Read &tab'] := 'Read &tab';
  GTextPortuguese.Values['Read &tab'] := '&Aba de leitura';
  GTextEnglish.Values['Read / &Load'] := 'Read / &Load';
  GTextPortuguese.Values['Read / &Load'] := 'Ler / &Carregar';
  GTextEnglish.Values['E&xit'] := 'E&xit';
  GTextPortuguese.Values['E&xit'] := '&Sair';

  GTextEnglish.Values['&Edit'] := '&Edit';
  GTextPortuguese.Values['&Edit'] := '&Editar';
  GTextEnglish.Values['&Find...'] := '&Find...';
  GTextPortuguese.Values['&Find...'] := '&Localizar...';
  GTextEnglish.Values['Find in &Files...'] := 'Find in &Files...';
  GTextPortuguese.Values['Find in &Files...'] := 'Localizar em &Arquivos...';
  GTextEnglish.Values['Find and &Replace...'] := 'Find and &Replace...';
  GTextPortuguese.Values['Find and &Replace...'] := 'Localizar e &Substituir...';
  GTextEnglish.Values['&Go to line...'] := '&Go to line...';
  GTextPortuguese.Values['&Go to line...'] := '&Ir para linha...';
  GTextEnglish.Values['Undo'] := 'Undo';
  GTextPortuguese.Values['Undo'] := 'Desfazer';
  GTextEnglish.Values['Redo'] := 'Redo';
  GTextPortuguese.Values['Redo'] := 'Refazer';
  GTextEnglish.Values['Copy selection'] := 'Copy selection';
  GTextPortuguese.Values['Copy selection'] := 'Copiar sele'#231#227'o';

  GTextEnglish.Values['&View'] := '&View';
  GTextPortuguese.Values['&View'] := '&Visualizar';

  GTextEnglish.Values['&Options'] := '&Options';
  GTextPortuguese.Values['&Options'] := '&Op'#231#245'es';
  GTextEnglish.Values['&Word wrap'] := '&Word wrap';
  GTextPortuguese.Values['&Word wrap'] := '&Quebra de linha';
  GTextEnglish.Values['Tail / &Follow mode'] := 'Tail / &Follow mode';
  GTextPortuguese.Values['Tail / &Follow mode'] := 'Tail / modo &Seguir';
  GTextEnglish.Values['Fil&ter / Grep'] := 'Fil&ter / Grep';
  GTextPortuguese.Values['Fil&ter / Grep'] := 'Fil&tro / Grep';
  GTextEnglish.Values['E&xport filtered results'] := 'E&xport filtered results';
  GTextPortuguese.Values['E&xport filtered results'] := 'E&xportar resultados filtrados';
  GTextEnglish.Values['&Toggle bookmark'] := '&Toggle bookmark';
  GTextPortuguese.Values['&Toggle bookmark'] := '&Alternar marcador';
  GTextEnglish.Values['&Next bookmark'] := '&Next bookmark';
  GTextPortuguese.Values['&Next bookmark'] := '&Pr'#243'ximo marcador';
  GTextEnglish.Values['Pr&evious bookmark'] := 'Pr&evious bookmark';
  GTextPortuguese.Values['Pr&evious bookmark'] := 'Marcador ant&erior';
  GTextEnglish.Values['Clear a&ll bookmarks'] := 'Clear a&ll bookmarks';
  GTextPortuguese.Values['Clear a&ll bookmarks'] := 'Limpar &todos os marcadores';
  GTextEnglish.Values['S&elect (checkbox list)'] := 'S&elect (checkbox list)';
  GTextPortuguese.Values['S&elect (checkbox list)'] := 'S&elecionar (lista de checkbox)';
  GTextEnglish.Values['Spl&it Files'] := 'Spl&it Files';
  GTextPortuguese.Values['Spl&it Files'] := 'D&ividir arquivos';
  GTextEnglish.Values['&Merge lines'] := '&Merge lines';
  GTextPortuguese.Values['&Merge lines'] := '&Mesclar linhas';
  GTextEnglish.Values['&Insert line'] := '&Insert line';
  GTextPortuguese.Values['&Insert line'] := '&Inserir linha';
  GTextEnglish.Values['&Edit line'] := '&Edit line';
  GTextPortuguese.Values['&Edit line'] := '&Editar linha';
  GTextEnglish.Values['&Delete line'] := '&Delete line';
  GTextPortuguese.Values['&Delete line'] := 'E&xcluir linha';
  GTextEnglish.Values['Exp&ort'] := 'Exp&ort';
  GTextPortuguese.Values['Exp&ort'] := 'Exp&ortar';
  GTextEnglish.Values['&Clear'] := '&Clear';
  GTextPortuguese.Values['&Clear'] := '&Limpar';
  GTextEnglish.Values['&AI (Consumer)'] := '&AI (Consumer)';
  GTextPortuguese.Values['&AI (Consumer)'] := '&IA (Consumer)';

  GTextEnglish.Values['&Help'] := '&Help';
  GTextPortuguese.Values['&Help'] := '&Ajuda';
  GTextEnglish.Values['&Help / Shortcuts'] := '&Help / Shortcuts';
  GTextPortuguese.Values['&Help / Shortcuts'] := '&Ajuda / Atalhos';
  GTextEnglish.Values['&About FastFile'] := '&About FastFile';
  GTextPortuguese.Values['&About FastFile'] := '&Sobre o FastFile';

  GTextEnglish.Values['Please check one or more lines first.'] := 'Please check one or more lines first.';
  GTextPortuguese.Values['Please check one or more lines first.'] := 'Marque uma ou mais linhas primeiro.';

  GTextEnglish.Values['From line must be >= 1.'] := 'From line must be >= 1.';
  GTextPortuguese.Values['From line must be >= 1.'] := 'A linha inicial deve ser >= 1.';

  GTextEnglish.Values['To line must be >= From line.'] := 'To line must be >= From line.';
  GTextPortuguese.Values['To line must be >= From line.'] := 'A linha final deve ser >= linha inicial.';

  GTextEnglish.Values['Please specify an output filename.'] := 'Please specify an output filename.';
  GTextPortuguese.Values['Please specify an output filename.'] := 'Informe um nome de arquivo de sa'#237'da.';

  GTextEnglish.Values['Please select a file first.'] := 'Please select a file first.';
  GTextPortuguese.Values['Please select a file first.'] := 'Selecione um arquivo primeiro.';

  GTextEnglish.Values['Process finished successfully!'] := 'Process finished successfully!';
  GTextPortuguese.Values['Process finished successfully!'] := 'Processo conclu'#237'do com sucesso!';

  GTextEnglish.Values['Operation failed or cancelled.'] := 'Operation failed or cancelled.';
  GTextPortuguese.Values['Operation failed or cancelled.'] := 'Opera'#231#227'o falhou ou foi cancelada.';

  GTextEnglish.Values['Error: '] := 'Error: ';
  GTextPortuguese.Values['Error: '] := 'Erro: ';

  GTextEnglish.Values['Merge Error: '] := 'Merge Error: ';
  GTextPortuguese.Values['Merge Error: '] := 'Erro de mesclagem: ';

  GTextEnglish.Values['Merge Delta Error: '] := 'Merge Delta Error: ';
  GTextPortuguese.Values['Merge Delta Error: '] := 'Erro de mesclagem delta: ';

  GTextEnglish.Values['Split Error: '] := 'Split Error: ';
  GTextPortuguese.Values['Split Error: '] := 'Erro de divis'#227'o: ';

  GTextEnglish.Values['Export finished! File saved to: '] := 'Export finished! File saved to: ';
  GTextPortuguese.Values['Export finished! File saved to: '] := 'Exporta'#231#227'o conclu'#237'da! Arquivo salvo em: ';

  GTextEnglish.Values['Export finished! Lines copied to clipboard.'] := 'Export finished! Lines copied to clipboard.';
  GTextPortuguese.Values['Export finished! Lines copied to clipboard.'] := 'Exporta'#231#227'o conclu'#237'da! Linhas copiadas para a '#225'rea de transfer'#234'ncia.';

  GTextEnglish.Values['Search'] := 'Find';
  GTextPortuguese.Values['Search'] := 'Localizar';

  GTextEnglish.Values['Filter / Grep'] := 'Filter / Grep';
  GTextPortuguese.Values['Filter / Grep'] := 'Filtro / Grep';

  GTextEnglish.Values['Show only lines containing:'] := 'Show only lines containing:';
  GTextPortuguese.Values['Show only lines containing:'] := 'Mostrar somente linhas contendo:';

  GTextEnglish.Values['Ir para linha'] := 'Go to line';
  GTextPortuguese.Values['Ir para linha'] := 'Ir para linha';

  GTextEnglish.Values['Numero da linha (1..'] := 'Line number (from 1 to ';
  GTextPortuguese.Values['Numero da linha (1..'] := 'N'#250'mero da linha (de 1 a ';

  GTextEnglish.Values['Extension files exclusion'] := 'Extension files exclusion';
  GTextPortuguese.Values['Extension files exclusion'] := 'Exclus'#227'o de extens'#245'es de arquivo';

  GTextEnglish.Values['Please enter with file extension to exclude in the files search'] := 'Please enter with file extension to exclude in the files search';
  GTextPortuguese.Values['Please enter with file extension to exclude in the files search'] := 'Informe a extens'#227'o de arquivo para excluir da busca de arquivos';

  GTextEnglish.Values['Folders exclusion'] := 'Folders exclusion';
  GTextPortuguese.Values['Folders exclusion'] := 'Exclus'#227'o de pastas';

  GTextEnglish.Values['Please enter with folder extension to exclude in the files search'] := 'Please enter with folder extension to exclude in the files search';
  GTextPortuguese.Values['Please enter with folder extension to exclude in the files search'] := 'Informe a extens'#227'o de pasta para excluir da busca de arquivos';

  GTextEnglish.Values['Executable not found: '] := 'Executable not found: ';
  GTextPortuguese.Values['Executable not found: '] := 'Execut'#225'vel n'#227'o encontrado: ';

  GTextEnglish.Values['Information'] := 'Information';
  GTextPortuguese.Values['Information'] := 'Informa'#231#227'o';

  GTextEnglish.Values['Error'] := 'Error';
  GTextPortuguese.Values['Error'] := 'Erro';

  GTextEnglish.Values['Folder saved with success.'] := 'Folder saved with success.';
  GTextPortuguese.Values['Folder saved with success.'] := 'Pasta salva com sucesso.';

  GTextEnglish.Values['Content exported to memo.'] := 'Content exported to memo.';
  GTextPortuguese.Values['Content exported to memo.'] := 'Conte'#250'do exportado para o memo.';

  GTextEnglish.Values['Please enter a search word.'] := 'Please enter a search word.';
  GTextPortuguese.Values['Please enter a search word.'] := 'Digite uma palavra para buscar.';

  GTextEnglish.Values['It is under development.'] := 'It is under development.';
  GTextPortuguese.Values['It is under development.'] := 'Est'#225' em desenvolvimento.';

  GTextEnglish.Values['Contents copied to the clipboard. Just paste (CTRL+V).'] := 'Contents copied to the clipboard. Just paste (CTRL+V).';
  GTextPortuguese.Values['Contents copied to the clipboard. Just paste (CTRL+V).'] := 'Conte'#250'dos copiados para a '#225'rea de transfer'#234'ncia. Basta colar (CTRL+V).';

  GTextEnglish.Values['File created:'] := 'File created:';
  GTextPortuguese.Values['File created:'] := 'Arquivo criado:';

  GTextEnglish.Values['files generated successfully.'] := 'files generated successfully.';
  GTextPortuguese.Values['files generated successfully.'] := 'arquivos gerados com sucesso.';

  GTextEnglish.Values['File saved with success.'] := 'File saved with success.';
  GTextPortuguese.Values['File saved with success.'] := 'Arquivo salvo com sucesso.';

  GTextEnglish.Values['Procurar'] := 'Search';
  GTextPortuguese.Values['Procurar'] := 'Procurar';

  GTextEnglish.Values['Digite o texto para procurar:'] := 'Type the text to search:';
  GTextPortuguese.Values['Digite o texto para procurar:'] := 'Digite o texto para procurar:';

  GTextEnglish.Values['Diferenciar maiúsculas/minúsculas?'] := 'Case sensitive search?';
  GTextPortuguese.Values['Diferenciar maiúsculas/minúsculas?'] := 'Diferenciar mai'#250'sculas/min'#250'sculas?';

  GTextEnglish.Values['(Yes = Case Sensitive / No = Ignorar)'] := '(Yes = Case Sensitive / No = Ignore case)';
  GTextPortuguese.Values['(Yes = Case Sensitive / No = Ignorar)'] := '(Sim = Diferenciar / N'#227'o = Ignorar diferen'#231'a)';

  GTextEnglish.Values['Número da linha (1..'] := 'Line number (1..';
  GTextPortuguese.Values['Número da linha (1..'] := 'N'#250'mero da linha (1..';

  GTextEnglish.Values['Arquivo de índice não encontrado (temp.txt). Releia o arquivo primeiro.'] := 'Index file not found (temp.txt). Please read the file again first.';
  GTextPortuguese.Values['Arquivo de índice não encontrado (temp.txt). Releia o arquivo primeiro.'] := 'Arquivo de '#237'ndice n'#227'o encontrado (temp.txt). Releia o arquivo primeiro.';

  GTextEnglish.Values['Texto não encontrado.'] := 'Text not found.';
  GTextPortuguese.Values['Texto não encontrado.'] := 'Texto n'#227'o encontrado.';

  { Top toolbar tab caption }
  GEnglish.Values['toolbar.top_toolbar_tab'] := 'Top toolbar';
  GPortuguese.Values['toolbar.top_toolbar_tab'] := 'Barra de ferramentas';
  GSpanish.Values['toolbar.top_toolbar_tab'] := 'Barra de herramientas';
  GFrench.Values['toolbar.top_toolbar_tab'] := 'Barre d''outils';
  GGerman.Values['toolbar.top_toolbar_tab'] := 'Symbolleiste';
  GItalian.Values['toolbar.top_toolbar_tab'] := 'Barra degli strumenti';

  { Top toolbar speed buttons }
  GEnglish.Values['toolbar.find_files'] := 'Find Files';
  GPortuguese.Values['toolbar.find_files'] := 'Localizar Arquivos';
  GSpanish.Values['toolbar.find_files'] := 'Buscar archivos';
  GFrench.Values['toolbar.find_files'] := 'Rechercher des fichiers';
  GGerman.Values['toolbar.find_files'] := 'Dateien suchen';
  GItalian.Values['toolbar.find_files'] := 'Trova file';

  GEnglish.Values['toolbar.close'] := 'Close';
  GPortuguese.Values['toolbar.close'] := 'Fechar';
  GSpanish.Values['toolbar.close'] := 'Cerrar';
  GFrench.Values['toolbar.close'] := 'Fermer';
  GGerman.Values['toolbar.close'] := 'Schlie'#223'en';
  GItalian.Values['toolbar.close'] := 'Chiudi';

  GEnglish.Values['toolbar.word_wrap_on'] := 'Word Wrap (ON)';
  GPortuguese.Values['toolbar.word_wrap_on'] := 'Quebra de linha (ON)';
  GSpanish.Values['toolbar.word_wrap_on'] := 'Ajuste de l'#237'nea (ON)';
  GFrench.Values['toolbar.word_wrap_on'] := 'Retour '#224' la ligne (ON)';
  GGerman.Values['toolbar.word_wrap_on'] := 'Zeilenumbruch (AN)';
  GItalian.Values['toolbar.word_wrap_on'] := 'A capo automatico (ON)';

  GEnglish.Values['toolbar.about_fastfile'] := 'About FastFile';
  GPortuguese.Values['toolbar.about_fastfile'] := 'Sobre o FastFile';
  GSpanish.Values['toolbar.about_fastfile'] := 'Acerca de FastFile';
  GFrench.Values['toolbar.about_fastfile'] := #192' propos de FastFile';
  GGerman.Values['toolbar.about_fastfile'] := #220'ber FastFile';
  GItalian.Values['toolbar.about_fastfile'] := 'Informazioni su FastFile';

  GEnglish.Values['consumer_ai.initializing'] := 'Initializing FastFile AI...';
  GPortuguese.Values['consumer_ai.initializing'] := 'Inicializando FastFile IA...';
  GSpanish.Values['consumer_ai.initializing'] := 'Inicializando FastFile IA...';
  GFrench.Values['consumer_ai.initializing'] := 'Initialisation de FastFile IA...';
  GGerman.Values['consumer_ai.initializing'] := 'FastFile KI wird initialisiert...';
  GItalian.Values['consumer_ai.initializing'] := 'Inizializzazione di FastFile IA...';

  GEnglish.Values['consumer_ai.program_version_prefix'] := 'FastFile AI - Version ';
  GPortuguese.Values['consumer_ai.program_version_prefix'] := 'FastFile IA - Vers'#227'o ';
  GSpanish.Values['consumer_ai.program_version_prefix'] := 'FastFile IA - Versi'#243'n ';
  GFrench.Values['consumer_ai.program_version_prefix'] := 'FastFile IA - Version ';
  GGerman.Values['consumer_ai.program_version_prefix'] := 'FastFile KI - Version ';
  GItalian.Values['consumer_ai.program_version_prefix'] := 'FastFile IA - Versione ';

  GEnglish.Values['consumer_ai.connected'] := 'FastFile AI connected';
  GPortuguese.Values['consumer_ai.connected'] := 'FastFile IA conectado';
  GSpanish.Values['consumer_ai.connected'] := 'FastFile IA conectado';
  GFrench.Values['consumer_ai.connected'] := 'FastFile IA connect'#233'';
  GGerman.Values['consumer_ai.connected'] := 'FastFile KI verbunden';
  GItalian.Values['consumer_ai.connected'] := 'FastFile IA connesso';

  GEnglish.Values['consumer_ai.starting_session'] := 'Starting FastFile AI inter-application session...';
  GPortuguese.Values['consumer_ai.starting_session'] := 'Iniciando sess'#227'o interaplica'#231#245'es do FastFile IA...';
  GSpanish.Values['consumer_ai.starting_session'] := 'Iniciando sesion entre aplicaciones de FastFile IA...';
  GFrench.Values['consumer_ai.starting_session'] := 'D'#233'marrage de la session inter-applications FastFile IA...';
  GGerman.Values['consumer_ai.starting_session'] := 'FastFile KI anwendungsuebergreifende Sitzung wird gestartet...';
  GItalian.Values['consumer_ai.starting_session'] := 'Avvio della sessione tra applicazioni di FastFile IA...';

  GEnglish.Values['toolbar.select_skin'] := 'Select'#13#10'skin';
  GPortuguese.Values['toolbar.select_skin'] := 'Selecionar'#13#10'Skin';
  GSpanish.Values['toolbar.select_skin'] := 'Seleccionar'#13#10'tema';
  GFrench.Values['toolbar.select_skin'] := 'S'#233'lectionner'#13#10'le th'#232'me';
  GGerman.Values['toolbar.select_skin'] := 'Design'#13#10'w'#228'hlen';
  GItalian.Values['toolbar.select_skin'] := 'Seleziona'#13#10'tema';

  GEnglish.Values['toolbar.change_bidimode'] := 'Change'#13#10'BidiMode';
  GPortuguese.Values['toolbar.change_bidimode'] := 'Mudar'#13#10'BidiMode';
  GSpanish.Values['toolbar.change_bidimode'] := 'Cambiar'#13#10'BidiMode';
  GFrench.Values['toolbar.change_bidimode'] := 'Changer'#13#10'BidiMode';
  GGerman.Values['toolbar.change_bidimode'] := #196'ndern'#13#10'BidiMode';
  GItalian.Values['toolbar.change_bidimode'] := 'Cambia'#13#10'BidiMode';

  { TsTitleBar items }
  GEnglish.Values['titlebar.about'] := 'About';
  GPortuguese.Values['titlebar.about'] := 'Sobre';
  GSpanish.Values['titlebar.about'] := 'Acerca';
  GFrench.Values['titlebar.about'] := #192' propos';
  GGerman.Values['titlebar.about'] := #220'ber';
  GItalian.Values['titlebar.about'] := 'Info';

  GEnglish.Values['titlebar.tools'] := 'Tools';
  GPortuguese.Values['titlebar.tools'] := 'Ferramentas';
  GSpanish.Values['titlebar.tools'] := 'Herramientas';
  GFrench.Values['titlebar.tools'] := 'Outils';
  GGerman.Values['titlebar.tools'] := 'Werkzeuge';
  GItalian.Values['titlebar.tools'] := 'Strumenti';

  { PopupMenu1 items (Tools dropdown) }
  GEnglish.Values['popup.select_skin'] := 'Select Skin';
  GPortuguese.Values['popup.select_skin'] := 'Selecionar Skin';
  GSpanish.Values['popup.select_skin'] := 'Seleccionar tema';
  GFrench.Values['popup.select_skin'] := 'S'#233'lectionner le th'#232'me';
  GGerman.Values['popup.select_skin'] := 'Design w'#228'hlen';
  GItalian.Values['popup.select_skin'] := 'Seleziona tema';

  GEnglish.Values['popup.random_skin'] := 'Random Skin';
  GPortuguese.Values['popup.random_skin'] := 'Skin aleat'#243'ria';
  GSpanish.Values['popup.random_skin'] := 'Tema aleatorio';
  GFrench.Values['popup.random_skin'] := 'Th'#232'me al'#233'atoire';
  GGerman.Values['popup.random_skin'] := 'Zuf'#228'lliges Design';
  GItalian.Values['popup.random_skin'] := 'Tema casuale';

  GEnglish.Values['popup.show_hints'] := 'Show Hints';
  GPortuguese.Values['popup.show_hints'] := 'Mostrar dicas';
  GSpanish.Values['popup.show_hints'] := 'Mostrar consejos';
  GFrench.Values['popup.show_hints'] := 'Afficher les info-bulles';
  GGerman.Values['popup.show_hints'] := 'Hinweise anzeigen';
  GItalian.Values['popup.show_hints'] := 'Mostra suggerimenti';

  GEnglish.Values['popup.change_bidimode'] := 'Change BidiMode';
  GPortuguese.Values['popup.change_bidimode'] := 'Mudar BidiMode';
  GSpanish.Values['popup.change_bidimode'] := 'Cambiar BidiMode';
  GFrench.Values['popup.change_bidimode'] := 'Changer BidiMode';
  GGerman.Values['popup.change_bidimode'] := 'BidiMode '#228'ndern';
  GItalian.Values['popup.change_bidimode'] := 'Cambia BidiMode';

  { PopupDialogs items }
  GEnglish.Values['popup.selectskin_dialog'] := 'SelectSkin dialog';
  GPortuguese.Values['popup.selectskin_dialog'] := 'Di'#225'logo de skin';
  GSpanish.Values['popup.selectskin_dialog'] := 'Di'#225'logo de tema';
  GFrench.Values['popup.selectskin_dialog'] := 'Bo'#238'te de s'#233'lection de th'#232'me';
  GGerman.Values['popup.selectskin_dialog'] := 'Design-Auswahl-Dialog';
  GItalian.Values['popup.selectskin_dialog'] := 'Finestra selezione tema';

  GEnglish.Values['popup.magnifier'] := 'Magnifier';
  GPortuguese.Values['popup.magnifier'] := 'Lupa';
  GSpanish.Values['popup.magnifier'] := 'Lupa';
  GFrench.Values['popup.magnifier'] := 'Loupe';
  GGerman.Values['popup.magnifier'] := 'Vergr'#246'sserung';
  GItalian.Values['popup.magnifier'] := 'Lente';

  GEnglish.Values['popup.calculator'] := 'Calculator';
  GPortuguese.Values['popup.calculator'] := 'Calculadora';
  GSpanish.Values['popup.calculator'] := 'Calculadora';
  GFrench.Values['popup.calculator'] := 'Calculatrice';
  GGerman.Values['popup.calculator'] := 'Rechner';
  GItalian.Values['popup.calculator'] := 'Calcolatrice';
end;

procedure AddCommonTranslationsGTextSpanishItalian;
begin
  { --- GText translations: Spanish ----------------------------------------- }
  GTextSpanish.Values['Line parameters are required.'] := 'Los par'#225'metros de l'#237'nea son obligatorios.';
  GTextSpanish.Values['Enter search text.'] := 'Ingrese el texto de b'#250'squeda.';
  GTextSpanish.Values['Line Number is required.'] := 'El n'#250'mero de l'#237'nea es obligatorio.';
  GTextSpanish.Values['Please enter a valid line number.'] := 'Ingrese un n'#250'mero de l'#237'nea v'#225'lido.';
  GTextSpanish.Values['Line number must be greater than 0.'] := 'El n'#250'mero de l'#237'nea debe ser mayor que 0.';
  GTextSpanish.Values['Please select a line first.'] := 'Seleccione una l'#237'nea primero.';
  GTextSpanish.Values['Please select a file.'] := 'Seleccione un archivo.';
  GTextSpanish.Values['Please select a file first.'] := 'Seleccione un archivo primero.';
  GTextSpanish.Values['Please read the file first.'] := 'Lea el archivo primero.';
  GTextSpanish.Values['Please read a file first.'] := 'Lea un archivo primero.';
  GTextSpanish.Values['File not found.'] := 'Archivo no encontrado.';
  GTextSpanish.Values['Text copied to clipboard!'] := 'Texto copiado al portapapeles.';
  GTextSpanish.Values['No active filter. Press Ctrl+L first.'] := 'Sin filtro activo. Presione Ctrl+L primero.';
  GTextSpanish.Values['Filter has no results to export.'] := 'El filtro no tiene resultados para exportar.';
  GTextSpanish.Values['No lines entered. Operation cancelled.'] := 'Sin l'#237'neas ingresadas. Operaci'#243'n cancelada.';
  GTextSpanish.Values['Cannot sort the list while a search is in progress.'] := 'No se puede ordenar la lista mientras hay una b'#250'squeda en curso.';
  GTextSpanish.Values['Hide the watermark?'] := 'Ocultar la marca de agua?';
  GTextSpanish.Values['Operation'] := 'Operaci'#243'n';
  GTextSpanish.Values['Insert Line'] := 'Insertar l'#237'nea';
  GTextSpanish.Values['Edit Line'] := 'Editar l'#237'nea';
  GTextSpanish.Values['Delete Line'] := 'Eliminar l'#237'nea';
  GTextSpanish.Values['Find and Replace'] := 'Buscar y Reemplazar';
  GTextSpanish.Values['Find what:'] := 'Buscar:';
  GTextSpanish.Values['Replace with:'] := 'Reemplazar con:';
  GTextSpanish.Values['Case sensitive'] := 'Distinguir may'#250'sculas';
  GTextSpanish.Values['Whole word'] := 'Palabra completa';
  GTextSpanish.Values['Find Next'] := 'Buscar siguiente';
  GTextSpanish.Values['Replace'] := 'Reemplazar';
  GTextSpanish.Values['Replace All'] := 'Reemplazar todo';
  GTextSpanish.Values['Close'] := 'Cerrar';
  GTextSpanish.Values['File Line Editor'] := 'Editor de l'#237'nea de archivo';
  GTextSpanish.Values['Operation:'] := 'Operaci'#243'n:';
  GTextSpanish.Values['Line Number:'] := 'N'#250'mero de l'#237'nea:';
  GTextSpanish.Values['Content:'] := 'Contenido:';
  GTextSpanish.Values['Confirm'] := 'Confirmar';
  GTextSpanish.Values['Cancel'] := 'Cancelar';
  GTextSpanish.Values['Application language'] := 'Idioma de la aplicaci'#243'n';
  GTextSpanish.Values['Export Lines'] := 'Exportar l'#237'neas';
  GTextSpanish.Values['Enter the lines to export (e.g. 1-4 or 1,4,10):'] := 'Ingrese las l'#237'neas a exportar (ej. 1-4 o 1,4,10):';
  GTextSpanish.Values['Delimiters: "-" for ranges, "," or ";" for specific lines.'#13'Spaces are ignored.'] := 'Delimitadores: "-" para rangos, "," o ";" para l'#237'neas espec'#237'ficas.'#13'Se ignoran los espacios.';
  GTextSpanish.Values['Save to text file instead of clipboard'] := 'Guardar en archivo en lugar del portapapeles';
  GTextSpanish.Values['Export'] := 'Exportar';
  GTextSpanish.Values['Delta File Editor'] := 'Editor de archivo delta';
  GTextSpanish.Values['Add/Update'] := 'Agregar/Actualizar';
  GTextSpanish.Values['Delete'] := 'Eliminar';
  GTextSpanish.Values['Line '] := 'L'#237'nea ';
  GTextSpanish.Values[' updated successfully.'] := ' actualizada correctamente.';
  GTextSpanish.Values[' line(s) copied to clipboard.'] := ' l'#237'nea(s) copiada(s) al portapapeles.';
  GTextSpanish.Values['Search'] := 'Buscar';
  GTextSpanish.Values['Type the text to search:'] := 'Escriba el texto a buscar:';
  GTextSpanish.Values['Case sensitive search?'] := 'B'#250'squeda con distinci'#243'n de may'#250'sculas?';
  GTextSpanish.Values['(Yes = Case Sensitive / No = Ignore case)'] := '(S'#237' = Distinguir / No = Ignorar diferencia)';
  GTextSpanish.Values['Replaced on line '] := 'Reemplazado en l'#237'nea ';
  GTextSpanish.Values['No match on current line.'] := 'Sin coincidencia en la l'#237'nea actual.';
  GTextSpanish.Values['No match selected. Use Find Next first.'] := 'Sin coincidencia seleccionada. Use Buscar siguiente primero.';
  GTextSpanish.Values['Replace all occurrences of "'] := 'Reemplazar todas las ocurrencias de "';
  GTextSpanish.Values['This operation cannot be undone.'] := 'Esta operaci'#243'n no se puede deshacer.';
  GTextSpanish.Values['Confirm the operation?'] := 'Confirmar la operaci'#243'n?';
  GTextSpanish.Values['Line: '] := 'L'#237'nea: ';
  GTextSpanish.Values['Do you want to continue?'] := 'Desea continuar?';
  GTextSpanish.Values['Read'] := 'Leer';
  GTextSpanish.Values['Split Files'] := 'Dividir archivos';
  GTextSpanish.Values['Merge lines'] := 'Combinar l'#237'neas';
  GTextSpanish.Values['Select'] := 'Seleccionar';
  GTextSpanish.Values['Clear'] := 'Limpiar';
  GTextSpanish.Values['Edit'] := 'Editar';
  GTextSpanish.Values['Delete lines (batch)'] := 'Eliminar l'#237'neas (lote)';
  GTextSpanish.Values['AI'] := 'IA';
  GTextSpanish.Values['Help'] := 'Ayuda';
  GTextSpanish.Values['Lines/Time:'] := 'L'#237'neas/Tiempo:';
  GTextSpanish.Values['All'] := 'Todo';
  GTextSpanish.Values['Line:'] := 'L'#237'nea:';
  GTextSpanish.Values['Search (Enter in search box)'] := 'Buscar (Enter en el campo de b'#250'squeda)';
  GTextSpanish.Values['Go to top (Ctrl+Home)'] := 'Ir al inicio (Ctrl+Home)';
  GTextSpanish.Values['Go to bottom (Ctrl+End)'] := 'Ir al final (Ctrl+End)';
  GTextSpanish.Values['Enter a word to search in the file'] := 'Ingrese una palabra a buscar en el archivo';
  GTextSpanish.Values['Empty input file'] := 'Vaciar archivo de entrada';
  GTextSpanish.Values['Select a file ...'] := 'Seleccione un archivo ...';
  GTextSpanish.Values['Shortcut: '] := 'Atajo: ';
  GTextSpanish.Values['Line: %d  Col: %d'] := 'L'#237'nea: %d  Col: %d';
  GTextSpanish.Values['Line: 0  Col: 0'] := 'L'#237'nea: 0  Col: 0';
  GTextSpanish.Values['Lines: %d'] := 'L'#237'neas: %d';
  GTextSpanish.Values['View: DEFAULT (detected)'] := 'Vista: PREDETERMINADO (detectado)';
  GTextSpanish.Values['View: UTF-8'] := 'Vista: UTF-8';
  GTextSpanish.Values['View: ANSI (raw / system)'] := 'Vista: ANSI (bruto / sistema)';
  GTextSpanish.Values['View: UTF-16 LE'] := 'Vista: UTF-16 LE';
  GTextSpanish.Values['View: UTF-16 BE'] := 'Vista: UTF-16 BE';
  GTextSpanish.Values['Detected on file: '] := 'Detectado en el archivo: ';
  GTextSpanish.Values['List view uses: '] := 'La lista usa: ';
  GTextSpanish.Values['Does not re-read file. DEFAULT = BOM/heuristics.'] := 'No relee el archivo. PRED = BOM/heur'#237'sticas.';
  GTextSpanish.Values[' (DEFAULT view)'] := ' (vista PREDETERMINADA)';
  GTextSpanish.Values['Does not re-read file. Pick UTF-8 / ANSI / UTF-16 to force.'] := 'No relee el archivo. Elija UTF-8 / ANSI / UTF-16 para forzar.';
  GTextSpanish.Values['&File'] := '&Archivo';
  GTextSpanish.Values['&Open file...'] := '&Abrir archivo...';
  GTextSpanish.Values['&Recent files'] := 'Archivos &recientes';
  GTextSpanish.Values['Read &tab'] := 'Pesta'#241'a de &lectura';
  GTextSpanish.Values['Read / &Load'] := 'Leer / &Cargar';
  GTextSpanish.Values['E&xit'] := '&Salir';
  GTextSpanish.Values['&Edit'] := '&Editar';
  GTextSpanish.Values['&Find...'] := '&Buscar...';
  GTextSpanish.Values['Find in &Files...'] := 'Buscar en &Archivos...';
  GTextSpanish.Values['Find and &Replace...'] := 'Buscar y &Reemplazar...';
  GTextSpanish.Values['&Go to line...'] := '&Ir a l'#237'nea...';
  GTextSpanish.Values['Undo'] := 'Deshacer';
  GTextSpanish.Values['Redo'] := 'Rehacer';
  GTextSpanish.Values['Copy selection'] := 'Copiar selecci'#243'n';
  GTextSpanish.Values['&View'] := '&Ver';
  GTextSpanish.Values['&Options'] := '&Opciones';
  GTextSpanish.Values['&Word wrap'] := '&Ajuste de l'#237'nea';
  GTextSpanish.Values['Tail / &Follow mode'] := 'Tail / modo &Seguir';
  GTextSpanish.Values['Fil&ter / Grep'] := 'Fil&tro / Grep';
  GTextSpanish.Values['E&xport filtered results'] := 'E&xportar resultados filtrados';
  GTextSpanish.Values['&Toggle bookmark'] := '&Activar marcador';
  GTextSpanish.Values['&Next bookmark'] := '&Siguiente marcador';
  GTextSpanish.Values['Pr&evious bookmark'] := 'Marcador an&terior';
  GTextSpanish.Values['Clear a&ll bookmarks'] := 'Limpiar &todos los marcadores';
  GTextSpanish.Values['S&elect (checkbox list)'] := 'S&eleccionar (lista de casillas)';
  GTextSpanish.Values['Spl&it Files'] := 'Div&idir archivos';
  GTextSpanish.Values['&Merge lines'] := '&Combinar l'#237'neas';
  GTextSpanish.Values['&Insert line'] := '&Insertar l'#237'nea';
  GTextSpanish.Values['&Edit line'] := '&Editar l'#237'nea';
  GTextSpanish.Values['&Delete line'] := '&Eliminar l'#237'nea';
  GTextSpanish.Values['Exp&ort'] := 'Exp&ortar';
  GTextSpanish.Values['&Clear'] := '&Limpiar';
  GTextSpanish.Values['&AI (Consumer)'] := '&IA (Consumer)';
  GTextSpanish.Values['&Help'] := '&Ayuda';
  GTextSpanish.Values['&Help / Shortcuts'] := '&Ayuda / Atajos';
  GTextSpanish.Values['&About FastFile'] := '&Acerca de FastFile';
  GTextSpanish.Values['&Version History'] := '&Historial de versiones';
  GTextSpanish.Values['Version History'] := 'Historial de versiones';
  GTextSpanish.Values['Please check one or more lines first.'] := 'Marque una o m'#225's l'#237'neas primero.';
  GTextSpanish.Values['From line must be >= 1.'] := 'La l'#237'nea inicial debe ser >= 1.';
  GTextSpanish.Values['To line must be >= From line.'] := 'La l'#237'nea final debe ser >= l'#237'nea inicial.';
  GTextSpanish.Values['Please specify an output filename.'] := 'Especifique un nombre de archivo de salida.';
  GTextSpanish.Values['Process finished successfully!'] := 'Proceso completado con '#233'xito!';
  GTextSpanish.Values['Operation failed or cancelled.'] := 'Operaci'#243'n fallida o cancelada.';
  GTextSpanish.Values['Error: '] := 'Error: ';
  GTextSpanish.Values['Merge Error: '] := 'Error de combinaci'#243'n: ';
  GTextSpanish.Values['Merge Delta Error: '] := 'Error de delta de combinaci'#243'n: ';
  GTextSpanish.Values['Split Error: '] := 'Error de divisi'#243'n: ';
  GTextSpanish.Values['Export finished! File saved to: '] := 'Exportaci'#243'n completada! Archivo guardado en: ';
  GTextSpanish.Values['Export finished! Lines copied to clipboard.'] := 'Exportaci'#243'n completada! L'#237'neas copiadas al portapapeles.';
  GTextSpanish.Values['Filter / Grep'] := 'Filtro / Grep';
  GTextSpanish.Values['Show only lines containing:'] := 'Mostrar solo l'#237'neas que contengan:';
  GTextSpanish.Values['Ir para linha'] := 'Ir a l'#237'nea';
  GTextSpanish.Values['Numero da linha (1..'] := 'N'#250'mero de l'#237'nea (de 1 a ';
  GTextSpanish.Values['Extension files exclusion'] := 'Exclusi'#243'n de extensiones de archivo';
  GTextSpanish.Values['Please enter with file extension to exclude in the files search'] := 'Ingrese la extensi'#243'n de archivo para excluir de la b'#250'squeda';
  GTextSpanish.Values['Folders exclusion'] := 'Exclusi'#243'n de carpetas';
  GTextSpanish.Values['Please enter with folder extension to exclude in the files search'] := 'Ingrese la extensi'#243'n de carpeta para excluir de la b'#250'squeda';
  GTextSpanish.Values['Executable not found: '] := 'Ejecutable no encontrado: ';
  GTextSpanish.Values['Information'] := 'Informaci'#243'n';
  GTextSpanish.Values['Error'] := 'Error';
  GTextSpanish.Values['Folder saved with success.'] := 'Carpeta guardada con '#233'xito.';
  GTextSpanish.Values['Content exported to memo.'] := 'Contenido exportado al memo.';
  GTextSpanish.Values['Please enter a search word.'] := 'Ingrese una palabra de b'#250'squeda.';
  GTextSpanish.Values['It is under development.'] := 'Est'#225' en desarrollo.';
  GTextSpanish.Values['Contents copied to the clipboard. Just paste (CTRL+V).'] := 'Contenido copiado al portapapeles. Solo pegue (CTRL+V).';
  GTextSpanish.Values['File created:'] := 'Archivo creado:';
  GTextSpanish.Values['files generated successfully.'] := 'archivos generados con '#233'xito.';
  GTextSpanish.Values['File saved with success.'] := 'Archivo guardado con '#233'xito.';
  GTextSpanish.Values['Procurar'] := 'Buscar';
  GTextSpanish.Values['Digite o texto para procurar:'] := 'Ingrese el texto a buscar:';
  GTextSpanish.Values['Diferenciar mai'#250'sculas/min'#250'sculas?'] := 'Distinguir may'#250'sculas/min'#250'sculas?';
  GTextSpanish.Values['(Yes = Case Sensitive / No = Ignorar)'] := '(S'#237' = Distinguir / No = Ignorar)';
  GTextSpanish.Values['N'#250'mero da linha (1..'] := 'N'#250'mero de l'#237'nea (1..';
  GTextSpanish.Values['Arquivo de '#237'ndice n'#227'o encontrado (temp.txt). Releia o arquivo primeiro.'] := '#205ndice no encontrado (temp.txt). Lea el archivo de nuevo primero.';
  GTextSpanish.Values['Texto n'#227'o encontrado.'] := 'Texto no encontrado.';
  GTextSpanish.Values['&More info / Splash...'] := '&M'#225's info / Presentaci'#243'n...';

  { --- GText translations: French ------------------------------------------ }
  GTextFrench.Values['Line parameters are required.'] := 'Les param'#232'tres de ligne sont obligatoires.';
  GTextFrench.Values['Enter search text.'] := 'Saisissez le texte de recherche.';
  GTextFrench.Values['Line Number is required.'] := 'Le num'#233'ro de ligne est obligatoire.';
  GTextFrench.Values['Please enter a valid line number.'] := 'Veuillez entrer un num'#233'ro de ligne valide.';
  GTextFrench.Values['Line number must be greater than 0.'] := 'Le num'#233'ro de ligne doit '#234'tre sup'#233'rieur '#224' 0.';
  GTextFrench.Values['Please select a line first.'] := 'Veuillez d''abord s'#233'lectionner une ligne.';
  GTextFrench.Values['Please select a file.'] := 'Veuillez s'#233'lectionner un fichier.';
  GTextFrench.Values['Please select a file first.'] := 'Veuillez d''abord s'#233'lectionner un fichier.';
  GTextFrench.Values['Please read the file first.'] := 'Veuillez d''abord lire le fichier.';
  GTextFrench.Values['Please read a file first.'] := 'Veuillez d''abord lire un fichier.';
  GTextFrench.Values['File not found.'] := 'Fichier introuvable.';
  GTextFrench.Values['Text copied to clipboard!'] := 'Texte copi'#233' dans le presse-papiers.';
  GTextFrench.Values['No active filter. Press Ctrl+L first.'] := 'Aucun filtre actif. Appuyez d''abord sur Ctrl+L.';
  GTextFrench.Values['Filter has no results to export.'] := 'Le filtre n''a aucun r'#233'sultat '#224' exporter.';
  GTextFrench.Values['No lines entered. Operation cancelled.'] := 'Aucune ligne saisie. Op'#233'ration annul'#233'e.';
  GTextFrench.Values['Cannot sort the list while a search is in progress.'] := 'Impossible de trier la liste pendant une recherche.';
  GTextFrench.Values['Hide the watermark?'] := 'Masquer le filigrane?';
  GTextFrench.Values['Operation'] := 'Op'#233'ration';
  GTextFrench.Values['Insert Line'] := 'Ins'#233'rer une ligne';
  GTextFrench.Values['Edit Line'] := #201'diter la ligne';
  GTextFrench.Values['Delete Line'] := 'Supprimer la ligne';
  GTextFrench.Values['Find and Replace'] := 'Rechercher et remplacer';
  GTextFrench.Values['Find what:'] := 'Rechercher:';
  GTextFrench.Values['Replace with:'] := 'Remplacer par:';
  GTextFrench.Values['Case sensitive'] := 'Respecter la casse';
  GTextFrench.Values['Whole word'] := 'Mot entier';
  GTextFrench.Values['Find Next'] := 'Suivant';
  GTextFrench.Values['Replace'] := 'Remplacer';
  GTextFrench.Values['Replace All'] := 'Tout remplacer';
  GTextFrench.Values['Close'] := 'Fermer';
  GTextFrench.Values['File Line Editor'] := #201'diteur de ligne de fichier';
  GTextFrench.Values['Operation:'] := 'Op'#233'ration:';
  GTextFrench.Values['Line Number:'] := 'Num'#233'ro de ligne:';
  GTextFrench.Values['Content:'] := 'Contenu:';
  GTextFrench.Values['Confirm'] := 'Confirmer';
  GTextFrench.Values['Cancel'] := 'Annuler';
  GTextFrench.Values['Application language'] := 'Langue de l''application';
  GTextFrench.Values['Export Lines'] := 'Exporter les lignes';
  GTextFrench.Values['Enter the lines to export (e.g. 1-4 or 1,4,10):'] := 'Saisissez les lignes '#224' exporter (ex. 1-4 ou 1,4,10):';
  GTextFrench.Values['Delimiters: "-" for ranges, "," or ";" for specific lines.'#13'Spaces are ignored.'] := 'D'#233'limiteurs: "-" pour plages, "," ou ";" pour lignes sp'#233'cifiques.'#13'Les espaces sont ignor'#233's.';
  GTextFrench.Values['Save to text file instead of clipboard'] := 'Enregistrer dans un fichier texte plut'#244't que dans le presse-papiers';
  GTextFrench.Values['Export'] := 'Exporter';
  GTextFrench.Values['Delta File Editor'] := #201'diteur de fichier delta';
  GTextFrench.Values['Add/Update'] := 'Ajouter/Mettre '#224' jour';
  GTextFrench.Values['Delete'] := 'Supprimer';
  GTextFrench.Values['Line '] := 'Ligne ';
  GTextFrench.Values[' updated successfully.'] := ' mise '#224' jour avec succ'#232's.';
  GTextFrench.Values[' line(s) copied to clipboard.'] := ' ligne(s) copi'#233'e(s) dans le presse-papiers.';
  GTextFrench.Values['Search'] := 'Rechercher';
  GTextFrench.Values['Type the text to search:'] := 'Saisissez le texte '#224' rechercher:';
  GTextFrench.Values['Case sensitive search?'] := 'Recherche sensible '#224' la casse?';
  GTextFrench.Values['(Yes = Case Sensitive / No = Ignore case)'] := '(Oui = Respecter la casse / Non = Ignorer)';
  GTextFrench.Values['Replaced on line '] := 'Remplac'#233' '#224' la ligne ';
  GTextFrench.Values['No match on current line.'] := 'Aucune correspondance sur la ligne actuelle.';
  GTextFrench.Values['No match selected. Use Find Next first.'] := 'Aucune correspondance s'#233'lectionn'#233'e. Utilisez Suivant d''abord.';
  GTextFrench.Values['Replace all occurrences of "'] := 'Remplacer toutes les occurrences de "';
  GTextFrench.Values['This operation cannot be undone.'] := 'Cette op'#233'ration est irr'#233'versible.';
  GTextFrench.Values['Confirm the operation?'] := 'Confirmer l''op'#233'ration?';
  GTextFrench.Values['Line: '] := 'Ligne: ';
  GTextFrench.Values['Do you want to continue?'] := 'Voulez-vous continuer?';
  GTextFrench.Values['Read'] := 'Lire';
  GTextFrench.Values['Split Files'] := 'Diviser les fichiers';
  GTextFrench.Values['Merge lines'] := 'Fusionner les lignes';
  GTextFrench.Values['Select'] := 'S'#233'lectionner';
  GTextFrench.Values['Clear'] := 'Effacer';
  GTextFrench.Values['Edit'] := #201'diter';
  GTextFrench.Values['Delete lines (batch)'] := 'Supprimer les lignes (lot)';
  GTextFrench.Values['AI'] := 'IA';
  GTextFrench.Values['Help'] := 'Aide';
  GTextFrench.Values['Lines/Time:'] := 'Lignes/Temps:';
  GTextFrench.Values['All'] := 'Toutes';
  GTextFrench.Values['Line:'] := 'Ligne:';
  GTextFrench.Values['Search (Enter in search box)'] := 'Rechercher (Entr'#233'e dans la zone de recherche)';
  GTextFrench.Values['Go to top (Ctrl+Home)'] := 'Aller au d'#233'but (Ctrl+Home)';
  GTextFrench.Values['Go to bottom (Ctrl+End)'] := 'Aller '#224' la fin (Ctrl+End)';
  GTextFrench.Values['Enter a word to search in the file'] := 'Entrez un mot '#224' rechercher dans le fichier';
  GTextFrench.Values['Empty input file'] := 'Vider le fichier d''entr'#233'e';
  GTextFrench.Values['Select a file ...'] := 'S'#233'lectionnez un fichier ...';
  GTextFrench.Values['Shortcut: '] := 'Raccourci: ';
  GTextFrench.Values['Line: %d  Col: %d'] := 'Ligne: %d  Col: %d';
  GTextFrench.Values['Line: 0  Col: 0'] := 'Ligne: 0  Col: 0';
  GTextFrench.Values['Lines: %d'] := 'Lignes: %d';
  GTextFrench.Values['View: DEFAULT (detected)'] := 'Vue: D'#201'FAUT (d'#233'tect'#233')';
  GTextFrench.Values['View: UTF-8'] := 'Vue: UTF-8';
  GTextFrench.Values['View: ANSI (raw / system)'] := 'Vue: ANSI (brut / syst'#232'me)';
  GTextFrench.Values['View: UTF-16 LE'] := 'Vue: UTF-16 LE';
  GTextFrench.Values['View: UTF-16 BE'] := 'Vue: UTF-16 BE';
  GTextFrench.Values['Detected on file: '] := 'D'#233'tect'#233' dans le fichier: ';
  GTextFrench.Values['List view uses: '] := 'La liste utilise: ';
  GTextFrench.Values['Does not re-read file. DEFAULT = BOM/heuristics.'] := 'Ne relit pas le fichier. D'#201'FAUT = BOM/heuristiques.';
  GTextFrench.Values[' (DEFAULT view)'] := ' (vue D'#201'FAUT)';
  GTextFrench.Values['Does not re-read file. Pick UTF-8 / ANSI / UTF-16 to force.'] := 'Ne relit pas le fichier. Choisissez UTF-8 / ANSI / UTF-16 pour forcer.';
  GTextFrench.Values['&File'] := '&Fichier';
  GTextFrench.Values['&Open file...'] := '&Ouvrir fichier...';
  GTextFrench.Values['&Recent files'] := 'Fichiers &r'#233'cents';
  GTextFrench.Values['Read &tab'] := 'Onglet de &lecture';
  GTextFrench.Values['Read / &Load'] := 'Lire / &Charger';
  GTextFrench.Values['E&xit'] := '&Quitter';
  GTextFrench.Values['&Edit'] := '&'#201'diter';
  GTextFrench.Values['&Find...'] := '&Rechercher...';
  GTextFrench.Values['Find in &Files...'] := 'Rechercher dans les &fichiers...';
  GTextFrench.Values['Find and &Replace...'] := 'Rechercher et &remplacer...';
  GTextFrench.Values['&Go to line...'] := '&Aller '#224' la ligne...';
  GTextFrench.Values['Undo'] := 'Annuler';
  GTextFrench.Values['Redo'] := 'R'#233'tablir';
  GTextFrench.Values['Copy selection'] := 'Copier la s'#233'lection';
  GTextFrench.Values['&View'] := '&Affichage';
  GTextFrench.Values['&Options'] := '&Options';
  GTextFrench.Values['&Word wrap'] := '&Retour '#224' la ligne';
  GTextFrench.Values['Tail / &Follow mode'] := 'Tail / mode &Suivre';
  GTextFrench.Values['Fil&ter / Grep'] := 'Fil&tre / Grep';
  GTextFrench.Values['E&xport filtered results'] := 'E&xporter les r'#233'sultats filtr'#233's';
  GTextFrench.Values['&Toggle bookmark'] := '&Basculer le signet';
  GTextFrench.Values['&Next bookmark'] := 'Signet &suivant';
  GTextFrench.Values['Pr&evious bookmark'] := 'Signet &pr'#233'c'#233'dent';
  GTextFrench.Values['Clear a&ll bookmarks'] := 'Effacer &tous les signets';
  GTextFrench.Values['S&elect (checkbox list)'] := 'S'#233'l&ectionner (liste de cases)';
  GTextFrench.Values['Spl&it Files'] := 'D'#233'couper &les fichiers';
  GTextFrench.Values['&Merge lines'] := '&Fusionner les lignes';
  GTextFrench.Values['&Insert line'] := '&Ins'#233'rer une ligne';
  GTextFrench.Values['&Edit line'] := '&'#201'diter la ligne';
  GTextFrench.Values['&Delete line'] := '&Supprimer la ligne';
  GTextFrench.Values['Exp&ort'] := 'Exp&orter';
  GTextFrench.Values['&Clear'] := '&Effacer';
  GTextFrench.Values['&AI (Consumer)'] := '&IA (Consumer)';
  GTextFrench.Values['&Help'] := '&Aide';
  GTextFrench.Values['&Help / Shortcuts'] := '&Aide / Raccourcis';
  GTextFrench.Values['&About FastFile'] := '&'#192' propos de FastFile';
  GTextFrench.Values['&Version History'] := '&Historique des versions';
  GTextFrench.Values['Version History'] := 'Historique des versions';
  GTextFrench.Values['Please check one or more lines first.'] := 'Cochez une ou plusieurs lignes d''abord.';
  GTextFrench.Values['From line must be >= 1.'] := 'La ligne de d'#233'part doit '#234'tre >= 1.';
  GTextFrench.Values['To line must be >= From line.'] := 'La ligne d''arriv'#233'e doit '#234'tre >= ligne de d'#233'part.';
  GTextFrench.Values['Please specify an output filename.'] := 'Veuillez sp'#233'cifier un nom de fichier de sortie.';
  GTextFrench.Values['Process finished successfully!'] := 'Processus termin'#233' avec succ'#232's!';
  GTextFrench.Values['Operation failed or cancelled.'] := 'Op'#233'ration '#233'chou'#233'e ou annul'#233'e.';
  GTextFrench.Values['Error: '] := 'Erreur: ';
  GTextFrench.Values['Merge Error: '] := 'Erreur de fusion: ';
  GTextFrench.Values['Merge Delta Error: '] := 'Erreur delta de fusion: ';
  GTextFrench.Values['Split Error: '] := 'Erreur de d'#233'coupage: ';
  GTextFrench.Values['Export finished! File saved to: '] := 'Exportation termin'#233'e! Fichier enregistr'#233' dans: ';
  GTextFrench.Values['Export finished! Lines copied to clipboard.'] := 'Exportation termin'#233'e! Lignes copi'#233'es dans le presse-papiers.';
  GTextFrench.Values['Filter / Grep'] := 'Filtre / Grep';
  GTextFrench.Values['Show only lines containing:'] := 'Afficher uniquement les lignes contenant:';
  GTextFrench.Values['Ir para linha'] := 'Aller '#224' la ligne';
  GTextFrench.Values['Numero da linha (1..'] := 'Num'#233'ro de ligne (de 1 '#224' ';
  GTextFrench.Values['Extension files exclusion'] := 'Exclusion d''extensions de fichier';
  GTextFrench.Values['Please enter with file extension to exclude in the files search'] := 'Entrez l''extension de fichier '#224' exclure de la recherche';
  GTextFrench.Values['Folders exclusion'] := 'Exclusion de dossiers';
  GTextFrench.Values['Please enter with folder extension to exclude in the files search'] := 'Entrez l''extension de dossier '#224' exclure de la recherche';
  GTextFrench.Values['Executable not found: '] := 'Ex'#233'cutable introuvable: ';
  GTextFrench.Values['Information'] := 'Information';
  GTextFrench.Values['Error'] := 'Erreur';
  GTextFrench.Values['Folder saved with success.'] := 'Dossier enregistr'#233' avec succ'#232's.';
  GTextFrench.Values['Content exported to memo.'] := 'Contenu export'#233' dans le m'#233'mo.';
  GTextFrench.Values['Please enter a search word.'] := 'Veuillez entrer un mot de recherche.';
  GTextFrench.Values['It is under development.'] := 'En cours de d'#233'veloppement.';
  GTextFrench.Values['Contents copied to the clipboard. Just paste (CTRL+V).'] := 'Contenu copi'#233' dans le presse-papiers. Collez simplement (CTRL+V).';
  GTextFrench.Values['File created:'] := 'Fichier cr'#233#233':';
  GTextFrench.Values['files generated successfully.'] := 'fichiers g'#233'n'#233'r'#233's avec succ'#232's.';
  GTextFrench.Values['File saved with success.'] := 'Fichier enregistr'#233' avec succ'#232's.';
  GTextFrench.Values['Procurar'] := 'Rechercher';
  GTextFrench.Values['Digite o texto para procurar:'] := 'Saisissez le texte '#224' rechercher:';
  GTextFrench.Values['Diferenciar mai'#250'sculas/min'#250'sculas?'] := 'Respecter la casse?';
  GTextFrench.Values['(Yes = Case Sensitive / No = Ignorar)'] := '(Oui = Respecter la casse / Non = Ignorer)';
  GTextFrench.Values['N'#250'mero da linha (1..'] := 'Num'#233'ro de ligne (1..';
  GTextFrench.Values['Arquivo de '#237'ndice n'#227'o encontrado (temp.txt). Releia o arquivo primeiro.'] := 'Fichier d''index introuvable (temp.txt). Veuillez relire le fichier.';
  GTextFrench.Values['Texto n'#227'o encontrado.'] := 'Texte introuvable.';
  GTextFrench.Values['&More info / Splash...'] := '&Plus d''infos / Intro...';

  { --- GText translations: German ------------------------------------------ }
  GTextGerman.Values['Line parameters are required.'] := 'Zeilenparameter sind erforderlich.';
  GTextGerman.Values['Enter search text.'] := 'Suchtext eingeben.';
  GTextGerman.Values['Line Number is required.'] := 'Zeilennummer ist erforderlich.';
  GTextGerman.Values['Please enter a valid line number.'] := 'Bitte eine g'#252'ltige Zeilennummer eingeben.';
  GTextGerman.Values['Line number must be greater than 0.'] := 'Die Zeilennummer muss gr'#246'sser als 0 sein.';
  GTextGerman.Values['Please select a line first.'] := 'Bitte zuerst eine Zeile ausw'#228'hlen.';
  GTextGerman.Values['Please select a file.'] := 'Bitte eine Datei ausw'#228'hlen.';
  GTextGerman.Values['Please select a file first.'] := 'Bitte zuerst eine Datei ausw'#228'hlen.';
  GTextGerman.Values['Please read the file first.'] := 'Bitte die Datei zuerst lesen.';
  GTextGerman.Values['Please read a file first.'] := 'Bitte zuerst eine Datei lesen.';
  GTextGerman.Values['File not found.'] := 'Datei nicht gefunden.';
  GTextGerman.Values['Text copied to clipboard!'] := 'Text in die Zwischenablage kopiert.';
  GTextGerman.Values['No active filter. Press Ctrl+L first.'] := 'Kein aktiver Filter. Zuerst Ctrl+L dr'#252'cken.';
  GTextGerman.Values['Filter has no results to export.'] := 'Der Filter hat keine Ergebnisse zum Exportieren.';
  GTextGerman.Values['No lines entered. Operation cancelled.'] := 'Keine Zeilen eingegeben. Vorgang abgebrochen.';
  GTextGerman.Values['Cannot sort the list while a search is in progress.'] := 'Die Liste kann w'#228'hrend einer Suche nicht sortiert werden.';
  GTextGerman.Values['Hide the watermark?'] := 'Wasserzeichen ausblenden?';
  GTextGerman.Values['Operation'] := 'Vorgang';
  GTextGerman.Values['Insert Line'] := 'Zeile einf'#252'gen';
  GTextGerman.Values['Edit Line'] := 'Zeile bearbeiten';
  GTextGerman.Values['Delete Line'] := 'Zeile l'#246'schen';
  GTextGerman.Values['Find and Replace'] := 'Suchen und Ersetzen';
  GTextGerman.Values['Find what:'] := 'Suchen nach:';
  GTextGerman.Values['Replace with:'] := 'Ersetzen durch:';
  GTextGerman.Values['Case sensitive'] := 'Gro'#223'-/Kleinschreibung beachten';
  GTextGerman.Values['Whole word'] := 'Ganzes Wort';
  GTextGerman.Values['Find Next'] := 'N'#228'chstes';
  GTextGerman.Values['Replace'] := 'Ersetzen';
  GTextGerman.Values['Replace All'] := 'Alle ersetzen';
  GTextGerman.Values['Close'] := 'Schlie'#223'en';
  GTextGerman.Values['File Line Editor'] := 'Dateizeilen-Editor';
  GTextGerman.Values['Operation:'] := 'Vorgang:';
  GTextGerman.Values['Line Number:'] := 'Zeilennummer:';
  GTextGerman.Values['Content:'] := 'Inhalt:';
  GTextGerman.Values['Confirm'] := 'Best'#228'tigen';
  GTextGerman.Values['Cancel'] := 'Abbrechen';
  GTextGerman.Values['Application language'] := 'Anwendungssprache';
  GTextGerman.Values['Export Lines'] := 'Zeilen exportieren';
  GTextGerman.Values['Enter the lines to export (e.g. 1-4 or 1,4,10):'] := 'Zeilen zum Exportieren eingeben (z.B. 1-4 oder 1,4,10):';
  GTextGerman.Values['Delimiters: "-" for ranges, "," or ";" for specific lines.'#13'Spaces are ignored.'] := 'Trennzeichen: "-" f'#252'r Bereiche, "," oder ";" f'#252'r Zeilen.'#13'Leerzeichen werden ignoriert.';
  GTextGerman.Values['Save to text file instead of clipboard'] := 'In Textdatei statt Zwischenablage speichern';
  GTextGerman.Values['Export'] := 'Exportieren';
  GTextGerman.Values['Delta File Editor'] := 'Delta-Datei-Editor';
  GTextGerman.Values['Add/Update'] := 'Hinzuf'#252'gen/Aktualisieren';
  GTextGerman.Values['Delete'] := 'L'#246'schen';
  GTextGerman.Values['Line '] := 'Zeile ';
  GTextGerman.Values[' updated successfully.'] := ' erfolgreich aktualisiert.';
  GTextGerman.Values[' line(s) copied to clipboard.'] := ' Zeile(n) in die Zwischenablage kopiert.';
  GTextGerman.Values['Search'] := 'Suchen';
  GTextGerman.Values['Type the text to search:'] := 'Suchtext eingeben:';
  GTextGerman.Values['Case sensitive search?'] := 'Gro'#223'-/Kleinschreibung beachten?';
  GTextGerman.Values['(Yes = Case Sensitive / No = Ignore case)'] := '(Ja = Beachten / Nein = Ignorieren)';
  GTextGerman.Values['Replaced on line '] := 'Ersetzt in Zeile ';
  GTextGerman.Values['No match on current line.'] := 'Keine '#220'bereinstimmung in der aktuellen Zeile.';
  GTextGerman.Values['No match selected. Use Find Next first.'] := 'Keine '#220'bereinstimmung ausgew'#228'hlt. Zuerst N'#228'chstes suchen.';
  GTextGerman.Values['Replace all occurrences of "'] := 'Alle Vorkommen von " ersetzen';
  GTextGerman.Values['This operation cannot be undone.'] := 'Dieser Vorgang kann nicht r'#252'ckg'#228'ngig gemacht werden.';
  GTextGerman.Values['Confirm the operation?'] := 'Vorgang best'#228'tigen?';
  GTextGerman.Values['Line: '] := 'Zeile: ';
  GTextGerman.Values['Do you want to continue?'] := 'M'#246'chten Sie fortfahren?';
  GTextGerman.Values['Read'] := 'Lesen';
  GTextGerman.Values['Split Files'] := 'Dateien aufteilen';
  GTextGerman.Values['Merge lines'] := 'Zeilen zusammenf'#252'hren';
  GTextGerman.Values['Select'] := 'Ausw'#228'hlen';
  GTextGerman.Values['Clear'] := 'Leeren';
  GTextGerman.Values['Edit'] := 'Bearbeiten';
  GTextGerman.Values['Delete lines (batch)'] := 'Zeilen l'#246'schen (Stapel)';
  GTextGerman.Values['AI'] := 'KI';
  GTextGerman.Values['Help'] := 'Hilfe';
  GTextGerman.Values['Lines/Time:'] := 'Zeilen/Zeit:';
  GTextGerman.Values['All'] := 'Alle';
  GTextGerman.Values['Line:'] := 'Zeile:';
  GTextGerman.Values['Search (Enter in search box)'] := 'Suchen (Eingabe im Suchfeld)';
  GTextGerman.Values['Go to top (Ctrl+Home)'] := 'Zum Anfang (Ctrl+Pos1)';
  GTextGerman.Values['Go to bottom (Ctrl+End)'] := 'Zum Ende (Ctrl+Ende)';
  GTextGerman.Values['Enter a word to search in the file'] := 'Ein Suchwort in der Datei eingeben';
  GTextGerman.Values['Empty input file'] := 'Eingabedatei leeren';
  GTextGerman.Values['Select a file ...'] := 'Datei ausw'#228'hlen ...';
  GTextGerman.Values['Shortcut: '] := 'Tastenkombination: ';
  GTextGerman.Values['Line: %d  Col: %d'] := 'Zeile: %d  Sp.: %d';
  GTextGerman.Values['Line: 0  Col: 0'] := 'Zeile: 0  Sp.: 0';
  GTextGerman.Values['Lines: %d'] := 'Zeilen: %d';
  GTextGerman.Values['View: DEFAULT (detected)'] := 'Ansicht: STANDARD (erkannt)';
  GTextGerman.Values['View: UTF-8'] := 'Ansicht: UTF-8';
  GTextGerman.Values['View: ANSI (raw / system)'] := 'Ansicht: ANSI (roh / System)';
  GTextGerman.Values['View: UTF-16 LE'] := 'Ansicht: UTF-16 LE';
  GTextGerman.Values['View: UTF-16 BE'] := 'Ansicht: UTF-16 BE';
  GTextGerman.Values['Detected on file: '] := 'In Datei erkannt: ';
  GTextGerman.Values['List view uses: '] := 'Listenansicht verwendet: ';
  GTextGerman.Values['Does not re-read file. DEFAULT = BOM/heuristics.'] := 'Datei wird nicht neu gelesen. STANDARD = BOM/Heuristik.';
  GTextGerman.Values[' (DEFAULT view)'] := ' (STANDARD-Ansicht)';
  GTextGerman.Values['Does not re-read file. Pick UTF-8 / ANSI / UTF-16 to force.'] := 'Datei wird nicht neu gelesen. UTF-8 / ANSI / UTF-16 ausw'#228'hlen.';
  GTextGerman.Values['&File'] := '&Datei';
  GTextGerman.Values['&Open file...'] := 'Datei &'#246'ffnen...';
  GTextGerman.Values['&Recent files'] := '&Zuletzt verwendet';
  GTextGerman.Values['Read &tab'] := '&Lese-Registerkarte';
  GTextGerman.Values['Read / &Load'] := 'Lesen / &Laden';
  GTextGerman.Values['E&xit'] := '&Beenden';
  GTextGerman.Values['&Edit'] := '&Bearbeiten';
  GTextGerman.Values['&Find...'] := '&Suchen...';
  GTextGerman.Values['Find in &Files...'] := 'In &Dateien suchen...';
  GTextGerman.Values['Find and &Replace...'] := 'Suchen und &Ersetzen...';
  GTextGerman.Values['&Go to line...'] := '&Gehe zu Zeile...';
  GTextGerman.Values['Undo'] := 'R'#252'ckg'#228'ngig';
  GTextGerman.Values['Redo'] := 'Wiederholen';
  GTextGerman.Values['Copy selection'] := 'Auswahl kopieren';
  GTextGerman.Values['&View'] := '&Ansicht';
  GTextGerman.Values['&Options'] := '&Optionen';
  GTextGerman.Values['&Word wrap'] := '&Zeilenumbruch';
  GTextGerman.Values['Tail / &Follow mode'] := 'Tail / &Folgemodus';
  GTextGerman.Values['Fil&ter / Grep'] := 'Fil&ter / Grep';
  GTextGerman.Values['E&xport filtered results'] := 'Gefilterte Ergebnisse e&xportieren';
  GTextGerman.Values['&Toggle bookmark'] := 'Lesezeichen &umschalten';
  GTextGerman.Values['&Next bookmark'] := '&N'#228'chstes Lesezeichen';
  GTextGerman.Values['Pr&evious bookmark'] := '&Vorheriges Lesezeichen';
  GTextGerman.Values['Clear a&ll bookmarks'] := '&Alle Lesezeichen l'#246'schen';
  GTextGerman.Values['S&elect (checkbox list)'] := 'A&usw'#228'hlen (Kontrollk'#228'stchen)';
  GTextGerman.Values['Spl&it Files'] := 'Dateien auf&teilen';
  GTextGerman.Values['&Merge lines'] := 'Zeilen &zusammenf'#252'hren';
  GTextGerman.Values['&Insert line'] := 'Zeile &einf'#252'gen';
  GTextGerman.Values['&Edit line'] := 'Zeile &bearbeiten';
  GTextGerman.Values['&Delete line'] := 'Zeile &l'#246'schen';
  GTextGerman.Values['Exp&ort'] := 'Ex&portieren';
  GTextGerman.Values['&Clear'] := '&Leeren';
  GTextGerman.Values['&AI (Consumer)'] := '&KI (Consumer)';
  GTextGerman.Values['&Help'] := '&Hilfe';
  GTextGerman.Values['&Help / Shortcuts'] := '&Hilfe / Tastenkombinationen';
  GTextGerman.Values['&About FastFile'] := #220'ber &FastFile';
  GTextGerman.Values['&Version History'] := '&Versionshistorie';
  GTextGerman.Values['Version History'] := 'Versionshistorie';
  GTextGerman.Values['Please check one or more lines first.'] := 'Bitte zuerst eine oder mehrere Zeilen markieren.';
  GTextGerman.Values['From line must be >= 1.'] := 'Die Startzeile muss >= 1 sein.';
  GTextGerman.Values['To line must be >= From line.'] := 'Die Endzeile muss >= Startzeile sein.';
  GTextGerman.Values['Please specify an output filename.'] := 'Bitte einen Ausgabedateinamen angeben.';
  GTextGerman.Values['Process finished successfully!'] := 'Vorgang erfolgreich abgeschlossen!';
  GTextGerman.Values['Operation failed or cancelled.'] := 'Vorgang fehlgeschlagen oder abgebrochen.';
  GTextGerman.Values['Error: '] := 'Fehler: ';
  GTextGerman.Values['Merge Error: '] := 'Zusammenf'#252'hrungsfehler: ';
  GTextGerman.Values['Merge Delta Error: '] := 'Delta-Zusammenf'#252'hrungsfehler: ';
  GTextGerman.Values['Split Error: '] := 'Aufteilungsfehler: ';
  GTextGerman.Values['Export finished! File saved to: '] := 'Export abgeschlossen! Datei gespeichert in: ';
  GTextGerman.Values['Export finished! Lines copied to clipboard.'] := 'Export abgeschlossen! Zeilen in die Zwischenablage kopiert.';
  GTextGerman.Values['Filter / Grep'] := 'Filter / Grep';
  GTextGerman.Values['Show only lines containing:'] := 'Nur Zeilen mit folgendem Inhalt anzeigen:';
  GTextGerman.Values['Ir para linha'] := 'Gehe zu Zeile';
  GTextGerman.Values['Numero da linha (1..'] := 'Zeilennummer (von 1 bis ';
  GTextGerman.Values['Extension files exclusion'] := 'Dateiendungen ausschlie'#223'en';
  GTextGerman.Values['Please enter with file extension to exclude in the files search'] := 'Dateiendung f'#252'r den Ausschluss aus Suche eingeben';
  GTextGerman.Values['Folders exclusion'] := 'Ordner ausschlie'#223'en';
  GTextGerman.Values['Please enter with folder extension to exclude in the files search'] := 'Ordner f'#252'r den Ausschluss aus Suche eingeben';
  GTextGerman.Values['Executable not found: '] := 'Ausf'#252'hrbare Datei nicht gefunden: ';
  GTextGerman.Values['Information'] := 'Information';
  GTextGerman.Values['Error'] := 'Fehler';
  GTextGerman.Values['Folder saved with success.'] := 'Ordner erfolgreich gespeichert.';
  GTextGerman.Values['Content exported to memo.'] := 'Inhalt in Memo exportiert.';
  GTextGerman.Values['Please enter a search word.'] := 'Bitte ein Suchwort eingeben.';
  GTextGerman.Values['It is under development.'] := 'In Entwicklung.';
  GTextGerman.Values['Contents copied to the clipboard. Just paste (CTRL+V).'] := 'Inhalt in die Zwischenablage kopiert. Einf'#252'gen mit (CTRL+V).';
  GTextGerman.Values['File created:'] := 'Datei erstellt:';
  GTextGerman.Values['files generated successfully.'] := 'Dateien erfolgreich generiert.';
  GTextGerman.Values['File saved with success.'] := 'Datei erfolgreich gespeichert.';
  GTextGerman.Values['Procurar'] := 'Suchen';
  GTextGerman.Values['Digite o texto para procurar:'] := 'Suchtext eingeben:';
  GTextGerman.Values['Diferenciar mai'#250'sculas/min'#250'sculas?'] := 'Gro'#223'-/Kleinschreibung beachten?';
  GTextGerman.Values['(Yes = Case Sensitive / No = Ignorar)'] := '(Ja = Beachten / Nein = Ignorieren)';
  GTextGerman.Values['N'#250'mero da linha (1..'] := 'Zeilennummer (1..';
  GTextGerman.Values['Arquivo de '#237'ndice n'#227'o encontrado (temp.txt). Releia o arquivo primeiro.'] := 'Indexdatei nicht gefunden (temp.txt). Bitte Datei erneut lesen.';
  GTextGerman.Values['Texto n'#227'o encontrado.'] := 'Text nicht gefunden.';
  GTextGerman.Values['&More info / Splash...'] := '&Weitere Infos / Intro...';

  { --- GText translations: Italian ----------------------------------------- }
  GTextItalian.Values['Line parameters are required.'] := 'I parametri di riga sono obbligatori.';
  GTextItalian.Values['Enter search text.'] := 'Inserire il testo di ricerca.';
  GTextItalian.Values['Line Number is required.'] := 'Il numero di riga '#232' obbligatorio.';
  GTextItalian.Values['Please enter a valid line number.'] := 'Inserire un numero di riga valido.';
  GTextItalian.Values['Line number must be greater than 0.'] := 'Il numero di riga deve essere maggiore di 0.';
  GTextItalian.Values['Please select a line first.'] := 'Selezionare prima una riga.';
  GTextItalian.Values['Please select a file.'] := 'Selezionare un file.';
  GTextItalian.Values['Please select a file first.'] := 'Selezionare prima un file.';
  GTextItalian.Values['Please read the file first.'] := 'Leggere prima il file.';
  GTextItalian.Values['Please read a file first.'] := 'Leggere prima un file.';
  GTextItalian.Values['File not found.'] := 'File non trovato.';
  GTextItalian.Values['Text copied to clipboard!'] := 'Testo copiato negli appunti.';
  GTextItalian.Values['No active filter. Press Ctrl+L first.'] := 'Nessun filtro attivo. Premere prima Ctrl+L.';
  GTextItalian.Values['Filter has no results to export.'] := 'Il filtro non ha risultati da esportare.';
  GTextItalian.Values['No lines entered. Operation cancelled.'] := 'Nessuna riga inserita. Operazione annullata.';
  GTextItalian.Values['Cannot sort the list while a search is in progress.'] := 'Impossibile ordinare la lista durante una ricerca.';
  GTextItalian.Values['Hide the watermark?'] := 'Nascondere la filigrana?';
  GTextItalian.Values['Operation'] := 'Operazione';
  GTextItalian.Values['Insert Line'] := 'Inserisci riga';
  GTextItalian.Values['Edit Line'] := 'Modifica riga';
  GTextItalian.Values['Delete Line'] := 'Elimina riga';
  GTextItalian.Values['Find and Replace'] := 'Trova e sostituisci';
  GTextItalian.Values['Find what:'] := 'Trova:';
  GTextItalian.Values['Replace with:'] := 'Sostituisci con:';
  GTextItalian.Values['Case sensitive'] := 'Distingui maiuscole/minuscole';
  GTextItalian.Values['Whole word'] := 'Parola intera';
  GTextItalian.Values['Find Next'] := 'Trova successivo';
  GTextItalian.Values['Replace'] := 'Sostituisci';
  GTextItalian.Values['Replace All'] := 'Sostituisci tutto';
  GTextItalian.Values['Close'] := 'Chiudi';
  GTextItalian.Values['File Line Editor'] := 'Editor di riga del file';
  GTextItalian.Values['Operation:'] := 'Operazione:';
  GTextItalian.Values['Line Number:'] := 'Numero di riga:';
  GTextItalian.Values['Content:'] := 'Contenuto:';
  GTextItalian.Values['Confirm'] := 'Conferma';
  GTextItalian.Values['Cancel'] := 'Annulla';
  GTextItalian.Values['Application language'] := 'Lingua dell''applicazione';
  GTextItalian.Values['Export Lines'] := 'Esporta righe';
  GTextItalian.Values['Enter the lines to export (e.g. 1-4 or 1,4,10):'] := 'Inserire le righe da esportare (es. 1-4 o 1,4,10):';
  GTextItalian.Values['Delimiters: "-" for ranges, "," or ";" for specific lines.'#13'Spaces are ignored.'] := 'Delimitatori: "-" per intervalli, "," o ";" per righe specifiche.'#13'Gli spazi vengono ignorati.';
  GTextItalian.Values['Save to text file instead of clipboard'] := 'Salva in file di testo invece degli appunti';
  GTextItalian.Values['Export'] := 'Esporta';
  GTextItalian.Values['Delta File Editor'] := 'Editor di file delta';
  GTextItalian.Values['Add/Update'] := 'Aggiungi/Aggiorna';
  GTextItalian.Values['Delete'] := 'Elimina';
  GTextItalian.Values['Line '] := 'Riga ';
  GTextItalian.Values[' updated successfully.'] := ' aggiornata con successo.';
  GTextItalian.Values[' line(s) copied to clipboard.'] := ' riga/righe copiata/e negli appunti.';
  GTextItalian.Values['Search'] := 'Cerca';
  GTextItalian.Values['Type the text to search:'] := 'Digitare il testo da cercare:';
  GTextItalian.Values['Case sensitive search?'] := 'Ricerca con distinzione maiuscole/minuscole?';
  GTextItalian.Values['(Yes = Case Sensitive / No = Ignore case)'] := '(S'#236' = Distingui / No = Ignora)';
  GTextItalian.Values['Replaced on line '] := 'Sostituito nella riga ';
  GTextItalian.Values['No match on current line.'] := 'Nessuna corrispondenza nella riga corrente.';
  GTextItalian.Values['No match selected. Use Find Next first.'] := 'Nessuna corrispondenza selezionata. Usare Trova successivo prima.';
  GTextItalian.Values['Replace all occurrences of "'] := 'Sostituire tutte le occorrenze di "';
  GTextItalian.Values['This operation cannot be undone.'] := 'Questa operazione non pu'#242' essere annullata.';
  GTextItalian.Values['Confirm the operation?'] := 'Confermare l''operazione?';
  GTextItalian.Values['Line: '] := 'Riga: ';
  GTextItalian.Values['Do you want to continue?'] := 'Vuoi continuare?';
  GTextItalian.Values['Read'] := 'Leggi';
  GTextItalian.Values['Split Files'] := 'Dividi file';
  GTextItalian.Values['Merge lines'] := 'Unisci righe';
  GTextItalian.Values['Select'] := 'Seleziona';
  GTextItalian.Values['Clear'] := 'Svuota';
  GTextItalian.Values['Edit'] := 'Modifica';
  GTextItalian.Values['Delete lines (batch)'] := 'Elimina righe (batch)';
  GTextItalian.Values['AI'] := 'IA';
  GTextItalian.Values['Help'] := 'Guida';
  GTextItalian.Values['Lines/Time:'] := 'Righe/Tempo:';
  GTextItalian.Values['All'] := 'Tutte';
  GTextItalian.Values['Line:'] := 'Riga:';
  GTextItalian.Values['Search (Enter in search box)'] := 'Cerca (Invio nella casella di ricerca)';
  GTextItalian.Values['Go to top (Ctrl+Home)'] := 'Vai all''inizio (Ctrl+Home)';
  GTextItalian.Values['Go to bottom (Ctrl+End)'] := 'Vai alla fine (Ctrl+End)';
  GTextItalian.Values['Enter a word to search in the file'] := 'Inserire una parola da cercare nel file';
  GTextItalian.Values['Empty input file'] := 'Svuotare il file di input';
  GTextItalian.Values['Select a file ...'] := 'Selezionare un file ...';
  GTextItalian.Values['Shortcut: '] := 'Scorciatoia: ';
  GTextItalian.Values['Line: %d  Col: %d'] := 'Riga: %d  Col: %d';
  GTextItalian.Values['Line: 0  Col: 0'] := 'Riga: 0  Col: 0';
  GTextItalian.Values['Lines: %d'] := 'Righe: %d';
  GTextItalian.Values['View: DEFAULT (detected)'] := 'Vista: PREDEFINITO (rilevato)';
  GTextItalian.Values['View: UTF-8'] := 'Vista: UTF-8';
  GTextItalian.Values['View: ANSI (raw / system)'] := 'Vista: ANSI (grezzo / sistema)';
  GTextItalian.Values['View: UTF-16 LE'] := 'Vista: UTF-16 LE';
  GTextItalian.Values['View: UTF-16 BE'] := 'Vista: UTF-16 BE';
  GTextItalian.Values['Detected on file: '] := 'Rilevato nel file: ';
  GTextItalian.Values['List view uses: '] := 'La lista usa: ';
  GTextItalian.Values['Does not re-read file. DEFAULT = BOM/heuristics.'] := 'Non rilegge il file. PRED = BOM/euristiche.';
  GTextItalian.Values[' (DEFAULT view)'] := ' (vista PREDEFINITA)';
  GTextItalian.Values['Does not re-read file. Pick UTF-8 / ANSI / UTF-16 to force.'] := 'Non rilegge il file. Scegliere UTF-8 / ANSI / UTF-16 per forzare.';
  GTextItalian.Values['&File'] := '&File';
  GTextItalian.Values['&Open file...'] := '&Apri file...';
  GTextItalian.Values['&Recent files'] := 'File &recenti';
  GTextItalian.Values['Read &tab'] := 'Scheda di &lettura';
  GTextItalian.Values['Read / &Load'] := 'Leggi / &Carica';
  GTextItalian.Values['E&xit'] := '&Esci';
  GTextItalian.Values['&Edit'] := '&Modifica';
  GTextItalian.Values['&Find...'] := '&Trova...';
  GTextItalian.Values['Find in &Files...'] := 'Trova nei &file...';
  GTextItalian.Values['Find and &Replace...'] := 'Trova e &sostituisci...';
  GTextItalian.Values['&Go to line...'] := '&Vai alla riga...';
  GTextItalian.Values['Undo'] := 'Annulla';
  GTextItalian.Values['Redo'] := 'Ripeti';
  GTextItalian.Values['Copy selection'] := 'Copia selezione';
  GTextItalian.Values['&View'] := '&Visualizza';
  GTextItalian.Values['&Options'] := '&Opzioni';
  GTextItalian.Values['&Word wrap'] := '&A capo automatico';
  GTextItalian.Values['Tail / &Follow mode'] := 'Tail / modalit'#224' &Segui';
  GTextItalian.Values['Fil&ter / Grep'] := 'Fil&tro / Grep';
  GTextItalian.Values['E&xport filtered results'] := 'E&sporta risultati filtrati';
  GTextItalian.Values['&Toggle bookmark'] := '&Attiva/disattiva segnalibro';
  GTextItalian.Values['&Next bookmark'] := 'Segnalibro &successivo';
  GTextItalian.Values['Pr&evious bookmark'] := 'Segnalibro &precedente';
  GTextItalian.Values['Clear a&ll bookmarks'] := 'Cancella &tutti i segnalibri';
  GTextItalian.Values['S&elect (checkbox list)'] := 'S&eleziona (elenco caselle)';
  GTextItalian.Values['Spl&it Files'] := 'Div&idi file';
  GTextItalian.Values['&Merge lines'] := '&Unisci righe';
  GTextItalian.Values['&Insert line'] := '&Inserisci riga';
  GTextItalian.Values['&Edit line'] := '&Modifica riga';
  GTextItalian.Values['&Delete line'] := '&Elimina riga';
  GTextItalian.Values['Exp&ort'] := 'Es&porta';
  GTextItalian.Values['&Clear'] := '&Svuota';
  GTextItalian.Values['&AI (Consumer)'] := '&IA (Consumer)';
  GTextItalian.Values['&Help'] := '&Guida';
  GTextItalian.Values['&Help / Shortcuts'] := '&Guida / Scorciatoie';
  GTextItalian.Values['&About FastFile'] := '&Informazioni su FastFile';
  GTextItalian.Values['&Version History'] := '&Cronologia versioni';
  GTextItalian.Values['Version History'] := 'Cronologia versioni';
  GTextItalian.Values['Please check one or more lines first.'] := 'Selezionare prima una o pi'#249' righe.';
  GTextItalian.Values['From line must be >= 1.'] := 'La riga iniziale deve essere >= 1.';
  GTextItalian.Values['To line must be >= From line.'] := 'La riga finale deve essere >= riga iniziale.';
  GTextItalian.Values['Please specify an output filename.'] := 'Specificare un nome di file di output.';
  GTextItalian.Values['Process finished successfully!'] := 'Processo completato con successo!';
  GTextItalian.Values['Operation failed or cancelled.'] := 'Operazione fallita o annullata.';
  GTextItalian.Values['Error: '] := 'Errore: ';
  GTextItalian.Values['Merge Error: '] := 'Errore di unione: ';
  GTextItalian.Values['Merge Delta Error: '] := 'Errore delta di unione: ';
  GTextItalian.Values['Split Error: '] := 'Errore di divisione: ';
  GTextItalian.Values['Export finished! File saved to: '] := 'Esportazione completata! File salvato in: ';
  GTextItalian.Values['Export finished! Lines copied to clipboard.'] := 'Esportazione completata! Righe copiate negli appunti.';
  GTextItalian.Values['Filter / Grep'] := 'Filtro / Grep';
  GTextItalian.Values['Show only lines containing:'] := 'Mostra solo le righe contenenti:';
  GTextItalian.Values['Ir para linha'] := 'Vai alla riga';
  GTextItalian.Values['Numero da linha (1..'] := 'Numero di riga (da 1 a ';
  GTextItalian.Values['Extension files exclusion'] := 'Esclusione di estensioni file';
  GTextItalian.Values['Please enter with file extension to exclude in the files search'] := 'Inserire l''estensione file da escludere dalla ricerca';
  GTextItalian.Values['Folders exclusion'] := 'Esclusione di cartelle';
  GTextItalian.Values['Please enter with folder extension to exclude in the files search'] := 'Inserire la cartella da escludere dalla ricerca';
  GTextItalian.Values['Executable not found: '] := 'Eseguibile non trovato: ';
  GTextItalian.Values['Information'] := 'Informazioni';
  GTextItalian.Values['Error'] := 'Errore';
  GTextItalian.Values['Folder saved with success.'] := 'Cartella salvata con successo.';
  GTextItalian.Values['Content exported to memo.'] := 'Contenuto esportato nel memo.';
  GTextItalian.Values['Please enter a search word.'] := 'Inserire una parola di ricerca.';
  GTextItalian.Values['It is under development.'] := 'In sviluppo.';
  GTextItalian.Values['Contents copied to the clipboard. Just paste (CTRL+V).'] := 'Contenuto copiato negli appunti. Incollare con (CTRL+V).';
  GTextItalian.Values['File created:'] := 'File creato:';
  GTextItalian.Values['files generated successfully.'] := 'file generati con successo.';
  GTextItalian.Values['File saved with success.'] := 'File salvato con successo.';
  GTextItalian.Values['Procurar'] := 'Cerca';
  GTextItalian.Values['Digite o texto para procurar:'] := 'Digitare il testo da cercare:';
  GTextItalian.Values['Diferenciar mai'#250'sculas/min'#250'sculas?'] := 'Distinguere maiuscole/minuscole?';
  GTextItalian.Values['(Yes = Case Sensitive / No = Ignorar)'] := '(S'#236' = Distingui / No = Ignora)';
  GTextItalian.Values['N'#250'mero da linha (1..'] := 'Numero di riga (1..';
  GTextItalian.Values['Arquivo de '#237'ndice n'#227'o encontrado (temp.txt). Releia o arquivo primeiro.'] := 'File indice non trovato (temp.txt). Rileggere prima il file.';
  GTextItalian.Values['Texto n'#227'o encontrado.'] := 'Testo non trovato.';
  GTextItalian.Values['&More info / Splash...'] := '&Ulteriori info / Intro...';
end;

procedure AddCommonTranslationsGTextEnglishThroughVirtual;
begin
  { --- Portuguese GText: Version History key (add alongside existing EN/PT) }
  GTextPortuguese.Values['&Version History'] := '&Hist'#243'rico de vers'#245'es';
  GTextPortuguese.Values['Version History'] := 'Hist'#243'rico de vers'#245'es';

  { --- English GText: Version History key ---------------------------------- }
  GTextEnglish.Values['&Version History'] := '&Version History';
  GTextEnglish.Values['Version History'] := 'Version History';

  { --- Dialog action buttons -------------------------------------------- }
  GTextEnglish.Values['&Copy']    := '&Copy';
  GTextPortuguese.Values['&Copy'] := '&Copiar';
  GTextSpanish.Values['&Copy']    := '&Copiar';
  GTextFrench.Values['&Copy']     := '&Copier';
  GTextGerman.Values['&Copy']     := '&Kopieren';
  GTextItalian.Values['&Copy']    := '&Copia';

  GTextEnglish.Values['&Export...']    := '&Export...';
  GTextPortuguese.Values['&Export...'] := '&Exportar...';
  GTextSpanish.Values['&Export...']    := '&Exportar...';
  GTextFrench.Values['&Export...']     := '&Exporter...';
  GTextGerman.Values['&Export...']     := '&Exportieren...';
  GTextItalian.Values['&Export...']    := '&Esporta...';

  GTextEnglish.Values['Content copied to clipboard.']    := 'Content copied to clipboard.';
  GTextPortuguese.Values['Content copied to clipboard.'] := 'Conte'#250'do copiado para a '#225'rea de transfer'#234'ncia.';
  GTextSpanish.Values['Content copied to clipboard.']    := 'Contenido copiado al portapapeles.';
  GTextFrench.Values['Content copied to clipboard.']     := 'Contenu copi'#233' dans le presse-papiers.';
  GTextGerman.Values['Content copied to clipboard.']     := 'Inhalt in die Zwischenablage kopiert.';
  GTextItalian.Values['Content copied to clipboard.']    := 'Contenuto copiato negli appunti.';
  GTextPortuguesePT.Values['Content copied to clipboard.'] := 'Conte'#250'do copiado para a '#225'rea de transfer'#234'ncia.';

  { --- Help menu: More info / Splash (EN + PT; 5 new langs already present) }
  GTextEnglish.Values['&More info / Splash...']    := '&More info / Splash...';
  GTextPortuguese.Values['&More info / Splash...'] := '&Mais info / Apresenta'#231#227'o...';

  { --- Skin selector bound label ------------------------------------------ }
  GTextEnglish.Values['Skin name:']    := 'Skin name:';
  GTextPortuguese.Values['Skin name:'] := 'Nome do tema:';
  GTextSpanish.Values['Skin name:']    := 'Nombre del tema:';
  GTextFrench.Values['Skin name:']     := 'Nom du th'#232'me:';
  GTextGerman.Values['Skin name:']     := 'Skin-Name:';
  GTextItalian.Values['Skin name:']    := 'Nome tema:';

  { --- Scaling popup button captions -------------------------------------- }
  GTextEnglish.Values['Change scaling']    := 'Change scaling';
  GTextPortuguese.Values['Change scaling'] := 'Alterar escala';
  GTextSpanish.Values['Change scaling']    := 'Cambiar escala';
  GTextFrench.Values['Change scaling']     := #201'chelle...';
  GTextGerman.Values['Change scaling']     := 'Skalierung...';
  GTextItalian.Values['Change scaling']    := 'Scala...';

  GTextEnglish.Values['Auto scaling']    := 'Auto scaling';
  GTextPortuguese.Values['Auto scaling'] := 'Escala autom'#225'tica';
  GTextSpanish.Values['Auto scaling']    := 'Escala autom'#225'tica';
  GTextFrench.Values['Auto scaling']     := 'Mise '#224' l'''#233'chelle auto';
  GTextGerman.Values['Auto scaling']     := 'Autom. Skalierung';
  GTextItalian.Values['Auto scaling']    := 'Scala automatica';

  GTextEnglish.Values['Custom PixelsPerInch value']    := 'Custom PixelsPerInch value';
  GTextPortuguese.Values['Custom PixelsPerInch value'] := 'Valor PPP personalizado';
  GTextSpanish.Values['Custom PixelsPerInch value']    := 'Valor PPP personalizado';
  GTextFrench.Values['Custom PixelsPerInch value']     := 'Valeur PPP personnalis'#233'e';
  GTextGerman.Values['Custom PixelsPerInch value']     := 'Benutzerdef. PPP-Wert';
  GTextItalian.Values['Custom PixelsPerInch value']    := 'Valore PPP personalizzato';

  { --- Tab captions (main page control) ------------------------------------ }
  GTextPortuguese.Values['Read File']      := 'Ler arquivo';
  GTextSpanish.Values['Read File']         := 'Leer archivo';
  GTextFrench.Values['Read File']          := 'Lire le fichier';
  GTextGerman.Values['Read File']          := 'Datei lesen';
  GTextItalian.Values['Read File']         := 'Leggi file';

  GTextPortuguese.Values['Split File']     := 'Dividir arquivo';
  GTextSpanish.Values['Split File']        := 'Dividir archivo';
  GTextFrench.Values['Split File']         := 'Diviser le fichier';
  GTextGerman.Values['Split File']         := 'Datei aufteilen';
  GTextItalian.Values['Split File']        := 'Dividi file';

  GTextPortuguese.Values['Exported Lines'] := 'Linhas exportadas';
  GTextSpanish.Values['Exported Lines']    := 'L'#237'neas exportadas';
  GTextFrench.Values['Exported Lines']     := 'Lignes export'#233'es';
  GTextGerman.Values['Exported Lines']     := 'Exportierte Zeilen';
  GTextItalian.Values['Exported Lines']    := 'Righe esportate';

  GTextPortuguese.Values['Find Files']     := 'Localizar arquivos';
  GTextSpanish.Values['Find Files']        := 'Buscar archivos';
  GTextFrench.Values['Find Files']         := 'Rechercher des fichiers';
  GTextGerman.Values['Find Files']         := 'Dateien suchen';
  GTextItalian.Values['Find Files']        := 'Trova file';

  { --- Ribbon/ribbon-style tab captions ----------------------------------- }
  GTextPortuguese.Values['Add-ons']        := 'Complementos';
  GTextSpanish.Values['Add-ons']           := 'Complementos';
  GTextFrench.Values['Add-ons']            := 'Modules';
  GTextGerman.Values['Add-ons']            := 'Erweiterungen';
  GTextItalian.Values['Add-ons']           := 'Componenti aggiuntivi';

  GTextPortuguese.Values['File toolbar']   := 'Barra de ferramentas';
  GTextSpanish.Values['File toolbar']      := 'Barra de herramientas';
  GTextFrench.Values['File toolbar']       := 'Barre d''outils';
  GTextGerman.Values['File toolbar']       := 'Datei-Symbolleiste';
  GTextItalian.Values['File toolbar']      := 'Barra degli strumenti';

  { --- Sub-tab captions --------------------------------------------------- }
  GTextPortuguese.Values['Split By Lines']   := 'Dividir por linhas';
  GTextSpanish.Values['Split By Lines']      := 'Dividir por l'#237'neas';
  GTextFrench.Values['Split By Lines']       := 'Diviser par lignes';
  GTextGerman.Values['Split By Lines']       := 'Nach Zeilen aufteilen';
  GTextItalian.Values['Split By Lines']      := 'Dividi per righe';

  GTextPortuguese.Values['Split By Files']   := 'Dividir por arquivos';
  GTextSpanish.Values['Split By Files']      := 'Dividir por archivos';
  GTextFrench.Values['Split By Files']       := 'Diviser par fichiers';
  GTextGerman.Values['Split By Files']       := 'Nach Dateien aufteilen';
  GTextItalian.Values['Split By Files']      := 'Dividi per file';

  GTextPortuguese.Values['Name && Location'] := 'Nome && Local';
  GTextSpanish.Values['Name && Location']    := 'Nombre && Ubicaci'#243'n';
  GTextFrench.Values['Name && Location']     := 'Nom && Emplacement';
  GTextGerman.Values['Name && Location']     := 'Name && Ort';
  GTextItalian.Values['Name && Location']    := 'Nome && Percorso';

  GTextPortuguese.Values['Folders exclude']  := 'Excluir pastas';
  GTextSpanish.Values['Folders exclude']     := 'Excluir carpetas';
  GTextFrench.Values['Folders exclude']      := 'Exclure dossiers';
  GTextGerman.Values['Folders exclude']      := 'Ordner ausschlie'#223'en';
  GTextItalian.Values['Folders exclude']     := 'Escludi cartelle';

  { --- ListView column headers -------------------------------------------- }
  GTextPortuguese.Values['Line #']           := 'Linha #';
  GTextSpanish.Values['Line #']              := 'L'#237'nea #';
  GTextFrench.Values['Line #']              := 'Ligne n'#176;
  GTextGerman.Values['Line #']              := 'Zeile #';
  GTextItalian.Values['Line #']             := 'Riga #';

  GTextPortuguese.Values['Content']          := 'Conte'#250'do';
  GTextSpanish.Values['Content']             := 'Contenido';
  GTextFrench.Values['Content']              := 'Contenu';
  GTextGerman.Values['Content']              := 'Inhalt';
  GTextItalian.Values['Content']             := 'Contenuto';

  { --- Tools popup (PopupMenu1) missing items ----------------------------- }
  GTextPortuguese.Values['Active']           := 'Ativo';
  GTextSpanish.Values['Active']              := 'Activo';
  GTextFrench.Values['Active']               := 'Actif';
  GTextGerman.Values['Active']               := 'Aktiv';
  GTextItalian.Values['Active']              := 'Attivo';

  GTextPortuguese.Values['Allow animation']  := 'Permitir anima'#231#227'o';
  GTextSpanish.Values['Allow animation']     := 'Permitir animaci'#243'n';
  GTextFrench.Values['Allow animation']      := 'Autoriser l''animation';
  GTextGerman.Values['Allow animation']      := 'Animation erlauben';
  GTextItalian.Values['Allow animation']     := 'Consenti animazione';

  GTextPortuguese.Values['Exit']             := 'Sair';
  GTextSpanish.Values['Exit']                := 'Salir';
  GTextFrench.Values['Exit']                 := 'Quitter';
  GTextGerman.Values['Exit']                 := 'Beenden';
  GTextItalian.Values['Exit']                := 'Esci';

  { --- Find Files tab: search fields and options -------------------------- }
  GTextPortuguese.Values['File Name (Separate multiple names with semicolon):'] :=
    'Nome do arquivo (Separe m'#250'ltiplos nomes com ponto e v'#237'rgula):';
  GTextSpanish.Values['File Name (Separate multiple names with semicolon):'] :=
    'Nombre de archivo (Separe varios nombres con punto y coma):';
  GTextFrench.Values['File Name (Separate multiple names with semicolon):'] :=
    'Nom de fichier (S'#233'parez plusieurs noms par des points-virgules):';
  GTextGerman.Values['File Name (Separate multiple names with semicolon):'] :=
    'Dateiname (Mehrere Namen durch Semikolon trennen):';
  GTextItalian.Values['File Name (Separate multiple names with semicolon):'] :=
    'Nome file (Separare pi'#249' nomi con punto e virgola):';

  GTextPortuguese.Values['Location (Separate multiple directories with semicolon):'] :=
    'Local (Separe m'#250'ltiplos diret'#243'rios com ponto e v'#237'rgula):';
  GTextSpanish.Values['Location (Separate multiple directories with semicolon):'] :=
    'Ubicaci'#243'n (Separe varios directorios con punto y coma):';
  GTextFrench.Values['Location (Separate multiple directories with semicolon):'] :=
    'Emplacement (S'#233'parez plusieurs r'#233'pertoires par des points-virgules):';
  GTextGerman.Values['Location (Separate multiple directories with semicolon):'] :=
    'Verzeichnis (Mehrere Verzeichnisse durch Semikolon trennen):';
  GTextItalian.Values['Location (Separate multiple directories with semicolon):'] :=
    'Percorso (Separare pi'#249' directory con punto e virgola):';

  GTextPortuguese.Values['Include subfolders'] := 'Incluir subpastas';
  GTextSpanish.Values['Include subfolders']    := 'Incluir subcarpetas';
  GTextFrench.Values['Include subfolders']     := 'Inclure les sous-dossiers';
  GTextGerman.Values['Include subfolders']     := 'Unterordner einschlie'#223'en';
  GTextItalian.Values['Include subfolders']    := 'Includi sottocartelle';

  GTextPortuguese.Values['Threaded Search']    := 'Busca com thread';
  GTextSpanish.Values['Threaded Search']       := 'B'#250'squeda en paralelo';
  GTextFrench.Values['Threaded Search']        := 'Recherche asynchrone';
  GTextGerman.Values['Threaded Search']        := 'Parallelsuche';
  GTextItalian.Values['Threaded Search']       := 'Ricerca parallela';

  GTextPortuguese.Values['Case Sensitive']     := 'Diferenciar mai'#250'sc./min'#250'sc.';
  GTextSpanish.Values['Case Sensitive']        := 'Distinguir may'#250'sculas';
  GTextFrench.Values['Case Sensitive']         := 'Respecter la casse';
  GTextGerman.Values['Case Sensitive']         := 'Gro'#223'/Kleinschreibung';
  GTextItalian.Values['Case Sensitive']        := 'Maiuscole/minuscole';

  GTextPortuguese.Values['Whole Word']         := 'Palavra inteira';
  GTextSpanish.Values['Whole Word']            := 'Palabra completa';
  GTextFrench.Values['Whole Word']             := 'Mot entier';
  GTextGerman.Values['Whole Word']             := 'Ganzes Wort';
  GTextItalian.Values['Whole Word']            := 'Parola intera';

  GTextPortuguese.Values['Excluded']           := 'Excluir';
  GTextSpanish.Values['Excluded']              := 'Excluido';
  GTextFrench.Values['Excluded']               := 'Exclu';
  GTextGerman.Values['Excluded']               := 'Ausgeschlossen';
  GTextItalian.Values['Excluded']              := 'Escluso';

  GTextPortuguese.Values['Find']               := 'Localizar';
  GTextSpanish.Values['Find']                  := 'Buscar';
  GTextFrench.Values['Find']                   := 'Rechercher';
  GTextGerman.Values['Find']                   := 'Suchen';
  GTextItalian.Values['Find']                  := 'Trova';

  GTextPortuguese.Values['Stop']               := 'Parar';
  GTextSpanish.Values['Stop']                  := 'Detener';
  GTextFrench.Values['Stop']                   := 'Arr'#234'ter';
  GTextGerman.Values['Stop']                   := 'Anhalten';
  GTextItalian.Values['Stop']                  := 'Ferma';

  { --- Found files ListView column headers -------------------------------- }
  GTextPortuguese.Values['Name']               := 'Nome';
  GTextSpanish.Values['Name']                  := 'Nombre';
  GTextFrench.Values['Name']                   := 'Nom';
  GTextGerman.Values['Name']                   := 'Name';
  GTextItalian.Values['Name']                  := 'Nome';

  GTextPortuguese.Values['Location']           := 'Local';
  GTextSpanish.Values['Location']              := 'Ubicaci'#243'n';
  GTextFrench.Values['Location']               := 'Emplacement';
  GTextGerman.Values['Location']               := 'Ort';
  GTextItalian.Values['Location']              := 'Percorso';

  GTextPortuguese.Values['Size']               := 'Tamanho';
  GTextSpanish.Values['Size']                  := 'Tama'#241'o';
  GTextFrench.Values['Size']                   := 'Taille';
  GTextGerman.Values['Size']                   := 'Gr'#246'sse';
  GTextItalian.Values['Size']                  := 'Dimensione';

  GTextPortuguese.Values['Modified']           := 'Modificado';
  GTextSpanish.Values['Modified']              := 'Modificado';
  GTextFrench.Values['Modified']               := 'Modifi'#233;
  GTextGerman.Values['Modified']               := 'Ge'#228'ndert';
  GTextItalian.Values['Modified']              := 'Modificato';

  { --- Split By Lines components ------------------------------------------ }
  GTextPortuguese.Values['Generating new file by source and target lines'] :=
    'Gerando novo arquivo por linhas de origem e destino';
  GTextSpanish.Values['Generating new file by source and target lines'] :=
    'Generando nuevo archivo por l'#237'neas de origen y destino';
  GTextFrench.Values['Generating new file by source and target lines'] :=
    'G'#233'n'#233'ration d''un fichier par lignes source et cible';
  GTextGerman.Values['Generating new file by source and target lines'] :=
    'Neue Datei nach Quell- und Zielzeilen erstellen';
  GTextItalian.Values['Generating new file by source and target lines'] :=
    'Generazione file per righe sorgente e destinazione';

  GTextPortuguese.Values['From:']              := 'De:';
  GTextSpanish.Values['From:']                 := 'Desde:';
  GTextFrench.Values['From:']                  := 'De:';
  GTextGerman.Values['From:']                  := 'Von:';
  GTextItalian.Values['From:']                 := 'Da:';

  GTextPortuguese.Values['To:']                := 'At'#233':';
  GTextSpanish.Values['To:']                   := 'Hasta:';
  GTextFrench.Values['To:']                    := #192':';
  GTextGerman.Values['To:']                    := 'Bis:';
  GTextItalian.Values['To:']                   := 'A:';

  GTextPortuguese.Values['Output FileName:']   := 'Arquivo de sa'#237'da:';
  GTextSpanish.Values['Output FileName:']      := 'Archivo de salida:';
  GTextFrench.Values['Output FileName:']       := 'Fichier de sortie:';
  GTextGerman.Values['Output FileName:']       := 'Ausgabedatei:';
  GTextItalian.Values['Output FileName:']      := 'File di output:';

  GTextPortuguese.Values['Execute']            := 'Executar';
  GTextSpanish.Values['Execute']               := 'Ejecutar';
  GTextFrench.Values['Execute']                := 'Ex'#233'cuter';
  GTextGerman.Values['Execute']                := 'Ausf'#252'hren';
  GTextItalian.Values['Execute']               := 'Esegui';

  { --- Split By Files components ------------------------------------------ }
  GTextPortuguese.Values['Generating splitted files - max 100'] :=
    'Gerando arquivos divididos - m'#225'x 100';
  GTextSpanish.Values['Generating splitted files - max 100'] :=
    'Generando archivos divididos - m'#225'x 100';
  GTextFrench.Values['Generating splitted files - max 100'] :=
    'G'#233'n'#233'ration de fichiers divis'#233's - max 100';
  GTextGerman.Values['Generating splitted files - max 100'] :=
    'Geteilte Dateien erstellen - max 100';
  GTextItalian.Values['Generating splitted files - max 100'] :=
    'Generazione file divisi - max 100';

  GTextPortuguese.Values['Files:']             := 'Arquivos:';
  GTextSpanish.Values['Files:']                := 'Archivos:';
  GTextFrench.Values['Files:']                 := 'Fichiers:';
  GTextGerman.Values['Files:']                 := 'Dateien:';
  GTextItalian.Values['Files:']                := 'File:';

  { --- Split File header (File Info group box) ----------------------------- }
  GTextPortuguese.Values['File Info']          := 'Informa'#231#245'es do arquivo';
  GTextSpanish.Values['File Info']             := 'Informaci'#243'n del archivo';
  GTextFrench.Values['File Info']              := 'Informations fichier';
  GTextGerman.Values['File Info']              := 'Dateiinformationen';
  GTextItalian.Values['File Info']             := 'Informazioni file';

  GTextPortuguese.Values['File name:']         := 'Nome do arquivo:';
  GTextSpanish.Values['File name:']            := 'Nombre de archivo:';
  GTextFrench.Values['File name:']             := 'Nom du fichier:';
  GTextGerman.Values['File name:']             := 'Dateiname:';
  GTextItalian.Values['File name:']            := 'Nome file:';

  GTextPortuguese.Values['Creation Date:']     := 'Data de cria'#231#227'o:';
  GTextSpanish.Values['Creation Date:']        := 'Fecha de creaci'#243'n:';
  GTextFrench.Values['Creation Date:']         := 'Date de cr'#233'ation:';
  GTextGerman.Values['Creation Date:']         := 'Erstellungsdatum:';
  GTextItalian.Values['Creation Date:']        := 'Data di creazione:';

  GTextPortuguese.Values['Total characters:']  := 'Total de caracteres:';
  GTextSpanish.Values['Total characters:']     := 'Total de caracteres:';
  GTextFrench.Values['Total characters:']      := 'Total de caract'#232'res:';
  GTextGerman.Values['Total characters:']      := 'Zeichen gesamt:';
  GTextItalian.Values['Total characters:']     := 'Totale caratteri:';

  GTextPortuguese.Values['Total lines:']       := 'Total de linhas:';
  GTextSpanish.Values['Total lines:']          := 'Total de l'#237'neas:';
  GTextFrench.Values['Total lines:']           := 'Total de lignes:';
  GTextGerman.Values['Total lines:']           := 'Zeilen gesamt:';
  GTextItalian.Values['Total lines:']          := 'Totale righe:';

  { --- Exported Lines tab buttons ----------------------------------------- }
  GTextPortuguese.Values['Return']             := 'Retornar';
  GTextSpanish.Values['Return']                := 'Volver';
  GTextFrench.Values['Return']                 := 'Retour';
  GTextGerman.Values['Return']                 := 'Zur'#252'ck';
  GTextItalian.Values['Return']                := 'Indietro';

  GTextPortuguese.Values['Copy']               := 'Copiar';
  GTextSpanish.Values['Copy']                  := 'Copiar';
  GTextFrench.Values['Copy']                   := 'Copier';
  GTextGerman.Values['Copy']                   := 'Kopieren';
  GTextItalian.Values['Copy']                  := 'Copia';

  { --- tabFindFiles: Date && Time sub-tab captions -------------------------}
  GTextPortuguese.Values['Date && Time']     := 'Data && Hora';
  GTextSpanish.Values['Date && Time']        := 'Fecha && Hora';
  GTextFrench.Values['Date && Time']         := 'Date && Heure';
  GTextGerman.Values['Date && Time']         := 'Datum && Zeit';
  GTextItalian.Values['Date && Time']        := 'Data && Ora';

  GTextPortuguese.Values['Created']          := 'Criado';
  GTextSpanish.Values['Created']             := 'Creado';
  GTextFrench.Values['Created']              := 'Cr'#233#233;
  GTextGerman.Values['Created']              := 'Erstellt';
  GTextItalian.Values['Created']             := 'Creato';

  GTextPortuguese.Values['Accessed']         := 'Acessado';
  GTextSpanish.Values['Accessed']            := 'Accedido';
  GTextFrench.Values['Accessed']             := 'Acc'#233'd'#233;
  GTextGerman.Values['Accessed']             := 'Zugegriffen';
  GTextItalian.Values['Accessed']            := 'Accesso';

  GTextPortuguese.Values['Size && Attributes'] := 'Tamanho && Atributos';
  GTextSpanish.Values['Size && Attributes']    := 'Tama'#241'o && Atributos';
  GTextFrench.Values['Size && Attributes']     := 'Taille && Attributs';
  GTextGerman.Values['Size && Attributes']     := 'Gr'#246'sse && Attribute';
  GTextItalian.Values['Size && Attributes']    := 'Dimensione && Attributi';

  { --- Date/time checkboxes (shared by Created/Modified/Accessed) ---------}
  GTextPortuguese.Values['Before Date:']     := 'Antes da data:';
  GTextSpanish.Values['Before Date:']        := 'Antes de (fecha):';
  GTextFrench.Values['Before Date:']         := 'Avant la date:';
  GTextGerman.Values['Before Date:']         := 'Vor Datum:';
  GTextItalian.Values['Before Date:']        := 'Prima della data:';

  GTextPortuguese.Values['Before Time:']     := 'Antes da hora:';
  GTextSpanish.Values['Before Time:']        := 'Antes de (hora):';
  GTextFrench.Values['Before Time:']         := 'Avant l''heure:';
  GTextGerman.Values['Before Time:']         := 'Vor Uhrzeit:';
  GTextItalian.Values['Before Time:']        := 'Prima dell''ora:';

  GTextPortuguese.Values['After Date:']      := 'Depois da data:';
  GTextSpanish.Values['After Date:']         := 'Despu'#233's de (fecha):';
  GTextFrench.Values['After Date:']          := 'Apr'#232's la date:';
  GTextGerman.Values['After Date:']          := 'Nach Datum:';
  GTextItalian.Values['After Date:']         := 'Dopo la data:';

  GTextPortuguese.Values['After Time:']      := 'Depois da hora:';
  GTextSpanish.Values['After Time:']         := 'Despu'#233's de (hora):';
  GTextFrench.Values['After Time:']          := 'Apr'#232's l''heure:';
  GTextGerman.Values['After Time:']          := 'Nach Uhrzeit:';
  GTextItalian.Values['After Time:']         := 'Dopo l''ora:';

  { --- Size && Attributes: FileSize group box labels ----------------------}
  GTextPortuguese.Values['At Most:']         := 'No m'#225'ximo:';
  GTextSpanish.Values['At Most:']            := 'Como m'#225'ximo:';
  GTextFrench.Values['At Most:']             := 'Au maximum:';
  GTextGerman.Values['At Most:']             := 'H'#246'chstens:';
  GTextItalian.Values['At Most:']            := 'Al massimo:';

  GTextPortuguese.Values['At Least:']        := 'No m'#237'nimo:';
  GTextSpanish.Values['At Least:']           := 'Como m'#237'nimo:';
  GTextFrench.Values['At Least:']            := 'Au minimum:';
  GTextGerman.Values['At Least:']            := 'Mindestens:';
  GTextItalian.Values['At Least:']           := 'Almeno:';

  { --- Size && Attributes: Attributes group box and checkboxes ------------}
  GTextPortuguese.Values['Attributes']       := 'Atributos';
  GTextSpanish.Values['Attributes']          := 'Atributos';
  GTextFrench.Values['Attributes']           := 'Attributs';
  GTextGerman.Values['Attributes']           := 'Attribute';
  GTextItalian.Values['Attributes']          := 'Attributi';

  GTextPortuguese.Values['System']           := 'Sistema';
  GTextSpanish.Values['System']              := 'Sistema';
  GTextFrench.Values['System']               := 'Syst'#232'me';
  GTextGerman.Values['System']               := 'System';
  GTextItalian.Values['System']              := 'Sistema';

  GTextPortuguese.Values['Hidden']           := 'Oculto';
  GTextSpanish.Values['Hidden']              := 'Oculto';
  GTextFrench.Values['Hidden']               := 'Cach'#233;
  GTextGerman.Values['Hidden']               := 'Versteckt';
  GTextItalian.Values['Hidden']              := 'Nascosto';

  GTextPortuguese.Values['Readonly']         := 'Somente leitura';
  GTextSpanish.Values['Readonly']            := 'Solo lectura';
  GTextFrench.Values['Readonly']             := 'Lecture seule';
  GTextGerman.Values['Readonly']             := 'Nur lesen';
  GTextItalian.Values['Readonly']            := 'Sola lettura';

  GTextPortuguese.Values['Archive']          := 'Arquivo';
  GTextSpanish.Values['Archive']             := 'Archivo';
  GTextFrench.Values['Archive']              := 'Archive';
  GTextGerman.Values['Archive']              := 'Archiv';
  GTextItalian.Values['Archive']             := 'Archivio';

  GTextPortuguese.Values['Directory']        := 'Diret'#243'rio';
  GTextSpanish.Values['Directory']           := 'Directorio';
  GTextFrench.Values['Directory']            := 'R'#233'pertoire';
  GTextGerman.Values['Directory']            := 'Verzeichnis';
  GTextItalian.Values['Directory']           := 'Directory';

  GTextPortuguese.Values['Compressed']       := 'Comprimido';
  GTextSpanish.Values['Compressed']          := 'Comprimido';
  GTextFrench.Values['Compressed']           := 'Compress'#233;
  GTextGerman.Values['Compressed']           := 'Komprimiert';
  GTextItalian.Values['Compressed']          := 'Compresso';

  GTextPortuguese.Values['Encrypted']        := 'Criptografado';
  GTextSpanish.Values['Encrypted']           := 'Cifrado';
  GTextFrench.Values['Encrypted']            := 'Chiffr'#233;
  GTextGerman.Values['Encrypted']            := 'Verschl'#252'sselt';
  GTextItalian.Values['Encrypted']           := 'Cifrato';

  GTextPortuguese.Values['Offline']          := 'Offline';
  GTextSpanish.Values['Offline']             := 'Fuera de l'#237'nea';
  GTextFrench.Values['Offline']              := 'Hors ligne';
  GTextGerman.Values['Offline']              := 'Offline';
  GTextItalian.Values['Offline']             := 'Non in linea';

  GTextPortuguese.Values['Sparse File']      := 'Arquivo esparso';
  GTextSpanish.Values['Sparse File']         := 'Archivo disperso';
  GTextFrench.Values['Sparse File']          := 'Fichier clairsem'#233;
  GTextGerman.Values['Sparse File']          := 'Sparse-Datei';
  GTextItalian.Values['Sparse File']         := 'File sparse';

  GTextPortuguese.Values['Reparse Point']    := 'Ponto de reparse';
  GTextSpanish.Values['Reparse Point']       := 'Punto de rean'#225'lisis';
  GTextFrench.Values['Reparse Point']        := 'Point d''analyse';
  GTextGerman.Values['Reparse Point']        := 'Analysepunkt';
  GTextItalian.Values['Reparse Point']       := 'Reparse Point';

  GTextPortuguese.Values['Temporary']        := 'Tempor'#225'rio';
  GTextSpanish.Values['Temporary']           := 'Temporal';
  GTextFrench.Values['Temporary']            := 'Temporaire';
  GTextGerman.Values['Temporary']            := 'Tempor'#228'r';
  GTextItalian.Values['Temporary']           := 'Temporaneo';

  GTextPortuguese.Values['Device']           := 'Dispositivo';
  GTextSpanish.Values['Device']              := 'Dispositivo';
  GTextFrench.Values['Device']               := 'P'#233'riph'#233'rique';
  GTextGerman.Values['Device']               := 'Ger'#228't';
  GTextItalian.Values['Device']              := 'Dispositivo';

  GTextPortuguese.Values['Normal']           := 'Normal';
  GTextSpanish.Values['Normal']              := 'Normal';
  GTextFrench.Values['Normal']               := 'Normal';
  GTextGerman.Values['Normal']               := 'Normal';
  GTextItalian.Values['Normal']              := 'Normale';

  GTextPortuguese.Values['Not Content Indexed'] := 'N'#227'o indexado';
  GTextSpanish.Values['Not Content Indexed']    := 'No indexado';
  GTextFrench.Values['Not Content Indexed']     := 'Non index'#233;
  GTextGerman.Values['Not Content Indexed']     := 'Nicht indiziert';
  GTextItalian.Values['Not Content Indexed']    := 'Non indicizzato';

  GTextPortuguese.Values['Virtual']          := 'Virtual';
  GTextSpanish.Values['Virtual']             := 'Virtual';
  GTextFrench.Values['Virtual']              := 'Virtuel';
  GTextGerman.Values['Virtual']              := 'Virtuell';
  GTextItalian.Values['Virtual']             := 'Virtuale';

end;

procedure AddCommonTranslationsStaleFilePreAssign;
begin
  { --- Stale file / find progress / atomic save (11 languages) ------------ }
  GTextEnglish.Values['Searching'] := 'Searching';
  GTextPortuguese.Values['Searching'] := 'Buscando';
  GTextSpanish.Values['Searching'] := 'Buscando';
  GTextFrench.Values['Searching'] := 'Recherche';
  GTextGerman.Values['Searching'] := 'Suche';
  GTextItalian.Values['Searching'] := 'Ricerca';

  GTextEnglish.Values['Searching...'] := 'Searching...';
  GTextPortuguese.Values['Searching...'] := 'Buscando...';
  GTextSpanish.Values['Searching...'] := 'Buscando...';
  GTextFrench.Values['Searching...'] := 'Recherche...';
  GTextGerman.Values['Searching...'] := 'Suche...';
  GTextItalian.Values['Searching...'] := 'Ricerca...';

  GTextEnglish.Values['File changed on disk'] := 'File changed on disk';
  GTextPortuguese.Values['File changed on disk'] := 'Arquivo alterado no disco';
  GTextSpanish.Values['File changed on disk'] := 'Archivo modificado en disco';
  GTextFrench.Values['File changed on disk'] := 'Fichier modifie sur le disque';
  GTextGerman.Values['File changed on disk'] := 'Datei auf dem Datentrager geaendert';
  GTextItalian.Values['File changed on disk'] := 'File modificato su disco';

  GTextEnglish.Values['File changed on disk since load'] :=
    'The file was modified on disk since it was loaded here.'#13#10#13#10 +
    'Yes = Reload from disk and cancel this action.'#13#10 +
    'No = Ignore and continue (overwrite the file on disk).'#13#10 +
    'Cancel = Abort.';
  GTextPortuguese.Values['File changed on disk since load'] :=
    'O arquivo foi modificado no disco desde que foi carregado aqui.'#13#10#13#10 +
    'Sim = Recarregar do disco e cancelar esta acao.'#13#10 +
    'Nao = Ignorar e continuar (sobrescrever o arquivo no disco).'#13#10 +
    'Cancelar = Abortar.';
  GTextSpanish.Values['File changed on disk since load'] :=
    'El archivo se modifico en el disco desde que se cargo aqui.'#13#10#13#10 +
    'Si = Volver a cargar desde el disco y cancelar esta accion.'#13#10 +
    'No = Ignorar y continuar (sobrescribir el archivo en el disco).'#13#10 +
    'Cancelar = Abortar.';
  GTextFrench.Values['File changed on disk since load'] :=
    'Le fichier a ete modifie sur le disque depuis son chargement ici.'#13#10#13#10 +
    'Oui = Recharger depuis le disque et annuler cette action.'#13#10 +
    'Non = Ignorer et continuer (ecraser le fichier sur le disque).'#13#10 +
    'Annuler = Abandonner.';
  GTextGerman.Values['File changed on disk since load'] :=
    'Die Datei wurde auf dem Datentrager geaendert, seit sie hier geladen wurde.'#13#10#13#10 +
    'Ja = Von Datentrager neu laden und diese Aktion abbrechen.'#13#10 +
    'Nein = Ignorieren und fortfahren (Datei auf dem Datentrager ueberschreiben).'#13#10 +
    'Abbrechen = Abbrechen.';
  GTextItalian.Values['File changed on disk since load'] :=
    'Il file e stato modificato su disco da quando e stato caricato qui.'#13#10#13#10 +
    'Si = Ricarica da disco e annulla questa azione.'#13#10 +
    'No = Ignora e continua (sovrascrivi il file su disco).'#13#10 +
    'Annulla = Interrompi.';

  GTextEnglish.Values['Not enough free disk space to complete this operation safely.'] :=
    'Not enough free disk space to complete this operation safely.';
  GTextPortuguese.Values['Not enough free disk space to complete this operation safely.'] :=
    'Espaco livre em disco insuficiente para concluir esta operacao com seguranca.';
  GTextSpanish.Values['Not enough free disk space to complete this operation safely.'] :=
    'No hay espacio libre suficiente en el disco para completar esta operacion con seguridad.';
  GTextFrench.Values['Not enough free disk space to complete this operation safely.'] :=
    'Espace disque libre insuffisant pour terminer cette operation en toute securite.';
  GTextGerman.Values['Not enough free disk space to complete this operation safely.'] :=
    'Nicht genug freier Speicherplatz, um diesen Vorgang sicher abzuschliessen.';
  GTextItalian.Values['Not enough free disk space to complete this operation safely.'] :=
    'Spazio su disco insufficiente per completare questa operazione in modo sicuro.';

  GTextEnglish.Values['Temporary output file was not created.'] := 'Temporary output file was not created.';
  GTextPortuguese.Values['Temporary output file was not created.'] := 'Arquivo temporario de saida nao foi criado.';
  GTextSpanish.Values['Temporary output file was not created.'] := 'No se creo el archivo temporal de salida.';
  GTextFrench.Values['Temporary output file was not created.'] := 'Le fichier temporaire de sortie na pas ete cree.';
  GTextGerman.Values['Temporary output file was not created.'] := 'Temporaere Ausgabedatei wurde nicht erstellt.';
  GTextItalian.Values['Temporary output file was not created.'] := 'Il file temporaneo di output non e stato creato.';

  GTextEnglish.Values['Could not remove or rename the target file (in use or access denied).'] :=
    'Could not remove or rename the target file (in use or access denied).';
  GTextPortuguese.Values['Could not remove or rename the target file (in use or access denied).'] :=
    'Nao foi possivel remover ou renomear o arquivo de destino (em uso ou acesso negado).';
  GTextSpanish.Values['Could not remove or rename the target file (in use or access denied).'] :=
    'No se pudo eliminar ni renombrar el archivo de destino (en uso o acceso denegado).';
  GTextFrench.Values['Could not remove or rename the target file (in use or access denied).'] :=
    'Impossible de supprimer ou renommer le fichier cible (utilise ou acces refuse).';
  GTextGerman.Values['Could not remove or rename the target file (in use or access denied).'] :=
    'Zieldatei konnte nicht geloescht oder umbenannt werden (in Benutzung oder Zugriff verweigert).';
  GTextItalian.Values['Could not remove or rename the target file (in use or access denied).'] :=
    'Impossibile rimuovere o rinominare il file di destinazione (in uso o accesso negato).';

  GTextEnglish.Values['Rename reported success but target file is missing.'] :=
    'Rename reported success but target file is missing.';
  GTextPortuguese.Values['Rename reported success but target file is missing.'] :=
    'Renomear indicou sucesso, mas o arquivo de destino esta ausente.';
  GTextSpanish.Values['Rename reported success but target file is missing.'] :=
    'El renombrado indico exito, pero falta el archivo de destino.';
  GTextFrench.Values['Rename reported success but target file is missing.'] :=
    'Le renommage a reussi, mais le fichier cible est introuvable.';
  GTextGerman.Values['Rename reported success but target file is missing.'] :=
    'Umbenennung meldete Erfolg, aber die Zieldatei fehlt.';
  GTextItalian.Values['Rename reported success but target file is missing.'] :=
    'La rinomina ha avuto esito positivo, ma il file di destinazione manca.';

  GTextEnglish.Values['Could not finalize save (rename). Error %d: %s'] :=
    'Could not finalize save (rename). Error %d: %s';
  GTextPortuguese.Values['Could not finalize save (rename). Error %d: %s'] :=
    'Nao foi possivel finalizar a gravacao (renomear). Erro %d: %s';
  GTextSpanish.Values['Could not finalize save (rename). Error %d: %s'] :=
    'No se pudo finalizar el guardado (renombrar). Error %d: %s';
  GTextFrench.Values['Could not finalize save (rename). Error %d: %s'] :=
    'Impossible de finaliser l''enregistrement (renommage). Erreur %d: %s';
  GTextGerman.Values['Could not finalize save (rename). Error %d: %s'] :=
    'Speichern konnte nicht abgeschlossen werden (Umbenennen). Fehler %d: %s';
  GTextItalian.Values['Could not finalize save (rename). Error %d: %s'] :=
    'Impossibile completare il salvataggio (rinomina). Errore %d: %s';

  GTextEnglish.Values['Replace-all stopped at the safety limit of %d matches. The file was not modified.'] :=
    'Replace-all stopped at the safety limit of %d matches. The file was not modified.';
  GTextPortuguese.Values['Replace-all stopped at the safety limit of %d matches. The file was not modified.'] :=
    'Substituir tudo parou no limite de seguranca de %d ocorrencias. O arquivo nao foi modificado.';
  GTextSpanish.Values['Replace-all stopped at the safety limit of %d matches. The file was not modified.'] :=
    'Reemplazar todo se detuvo en el limite de seguridad de %d coincidencias. El archivo no se modifico.';
  GTextFrench.Values['Replace-all stopped at the safety limit of %d matches. The file was not modified.'] :=
    'Remplacer tout s''est arrete a la limite de securite de %d correspondances. Le fichier na pas ete modifie.';
  GTextGerman.Values['Replace-all stopped at the safety limit of %d matches. The file was not modified.'] :=
    'Ersetzen-alle stoppte am Sicherheitslimit von %d Treffern. Die Datei wurde nicht geaendert.';
  GTextItalian.Values['Replace-all stopped at the safety limit of %d matches. The file was not modified.'] :=
    'Sostituisci tutto si e fermato al limite di sicurezza di %d occorrenze. Il file non e stato modificato.';

end;

procedure AddCommonTranslationsStaleFilePostSeed;
begin
  { --- Stale file / atomic save: PL / PT-PT / RO / HU / CZ (post-seed) ----- }
  GTextPolish.Values['Searching'] := 'Wyszukiwanie';
  GTextPolish.Values['Searching...'] := 'Wyszukiwanie...';
  GTextPolish.Values['File changed on disk'] := 'Plik zmieniony na dysku';
  GTextPolish.Values['File changed on disk since load'] :=
    'Plik zostal zmodyfikowany na dysku od momentu wczytania tutaj.'#13#10#13#10 +
    'Tak = Wczytaj ponownie z dysku i anuluj te akcje.'#13#10 +
    'Nie = Ignoruj i kontynuuj (nadpisz plik na dysku).'#13#10 +
    'Anuluj = Przerwij.';
  GTextPolish.Values['Not enough free disk space to complete this operation safely.'] :=
    'Za malo wolnego miejsca na dysku, aby bezpiecznie zakonczyc te operacje.';
  GTextPolish.Values['Temporary output file was not created.'] := 'Tymczasowy plik wyjsciowy nie zostal utworzony.';
  GTextPolish.Values['Could not remove or rename the target file (in use or access denied).'] :=
    'Nie mozna usunac ani zmienic nazwy pliku docelowego (w uzyciu lub odmowa dostepu).';
  GTextPolish.Values['Rename reported success but target file is missing.'] :=
    'Zmiana nazwy zakonczyla sie powodzeniem, ale brakuje pliku docelowego.';
  GTextPolish.Values['Could not finalize save (rename). Error %d: %s'] :=
    'Nie mozna zakonczyc zapisu (zmiana nazwy). Blad %d: %s';
  GTextPolish.Values['Replace-all stopped at the safety limit of %d matches. The file was not modified.'] :=
    'Zamien wszystko zatrzymalo sie na limicie bezpieczenstwa %d dopasowan. Plik nie zostal zmodyfikowany.';

  GTextPortuguesePT.Values['Searching'] := 'A pesquisar';
  GTextPortuguesePT.Values['Searching...'] := 'A pesquisar...';
  GTextPortuguesePT.Values['File changed on disk'] := 'Ficheiro alterado no disco';
  GTextPortuguesePT.Values['File changed on disk since load'] :=
    'O ficheiro foi modificado no disco desde que foi carregado aqui.'#13#10#13#10 +
    'Sim = Recarregar do disco e cancelar esta acao.'#13#10 +
    'Nao = Ignorar e continuar (substituir o ficheiro no disco).'#13#10 +
    'Cancelar = Abortar.';
  GTextPortuguesePT.Values['Temporary output file was not created.'] := 'O ficheiro temporario de saida nao foi criado.';
  GTextPortuguesePT.Values['Could not remove or rename the target file (in use or access denied).'] :=
    'Nao foi possivel remover ou renomear o ficheiro de destino (em uso ou acesso negado).';
  GTextPortuguesePT.Values['Rename reported success but target file is missing.'] :=
    'Renomear indicou sucesso, mas o ficheiro de destino esta ausente.';
  GTextPortuguesePT.Values['Replace-all stopped at the safety limit of %d matches. The file was not modified.'] :=
    'Substituir tudo parou no limite de seguranca de %d ocorrencias. O ficheiro nao foi modificado.';

  GTextRomanian.Values['Searching'] := 'Cautare';
  GTextRomanian.Values['Searching...'] := 'Cautare...';
  GTextRomanian.Values['File changed on disk'] := 'Fisier modificat pe disc';
  GTextRomanian.Values['File changed on disk since load'] :=
    'Fisierul a fost modificat pe disc de la incarcarea aici.'#13#10#13#10 +
    'Da = Reincarca de pe disc si anuleaza aceasta actiune.'#13#10 +
    'Nu = Ignora si continua (suprascrie fisierul pe disc).'#13#10 +
    'Anulare = Intrerupe.';
  GTextRomanian.Values['Not enough free disk space to complete this operation safely.'] :=
    'Spatiu liber insuficient pe disc pentru a finaliza in siguranta aceasta operatiune.';
  GTextRomanian.Values['Temporary output file was not created.'] := 'Fisierul temporar de iesire nu a fost creat.';
  GTextRomanian.Values['Could not remove or rename the target file (in use or access denied).'] :=
    'Nu s-a putut sterge sau redenumi fisierul tinta (in folosire sau acces refuzat).';
  GTextRomanian.Values['Rename reported success but target file is missing.'] :=
    'Redenumirea a raportat succes, dar fisierul tinta lipseste.';
  GTextRomanian.Values['Could not finalize save (rename). Error %d: %s'] :=
    'Nu s-a putut finaliza salvarea (redenumire). Eroare %d: %s';
  GTextRomanian.Values['Replace-all stopped at the safety limit of %d matches. The file was not modified.'] :=
    'Inlocuirea tuturor s-a oprit la limita de siguranta de %d potriviri. Fisierul nu a fost modificat.';

  GTextHungarian.Values['Searching'] := 'Kereses';
  GTextHungarian.Values['Searching...'] := 'Kereses...';
  GTextHungarian.Values['File changed on disk'] := 'A fajl megvaltozott a lemezen';
  GTextHungarian.Values['File changed on disk since load'] :=
    'A fajl megvaltozott a lemezen azota, hogy ide betoltottuk.'#13#10#13#10 +
    'Igen = Ujratoltes a lemezrol es a muvelet megszakitasa.'#13#10 +
    'Nem = Figyelmen kivul hagyas es folytatas (a fajl felulirasa).'#13#10 +
    'Megse = Megszakitas.';
  GTextHungarian.Values['Not enough free disk space to complete this operation safely.'] :=
    'Nincs eleg szabad lemezterulet a muvelet biztonsagos befejezesehez.';
  GTextHungarian.Values['Temporary output file was not created.'] := 'Az ideiglenes kimeneti fajl nem jott letre.';
  GTextHungarian.Values['Could not remove or rename the target file (in use or access denied).'] :=
    'A cel fajl nem torolheto es nem nevezheto at (hasznalatban van vagy hozzaferes megtagadva).';
  GTextHungarian.Values['Rename reported success but target file is missing.'] :=
    'Az atnevezes sikeresnek jelentkezett, de a cel fajl hianyzik.';
  GTextHungarian.Values['Could not finalize save (rename). Error %d: %s'] :=
    'A mentes veglegesitese sikertelen (atnevezes). Hiba %d: %s';
  GTextHungarian.Values['Replace-all stopped at the safety limit of %d matches. The file was not modified.'] :=
    'Az osszes csere leallt a %d talalat biztonsagi limitjenel. A fajl nem valtozott.';

  GTextCzech.Values['Searching'] := 'Hledani';
  GTextCzech.Values['Searching...'] := 'Hledani...';
  GTextCzech.Values['File changed on disk'] := 'Soubor na disku byl zmenen';
  GTextCzech.Values['File changed on disk since load'] :=
    'Soubor byl na disku zmenen po nacteni sem.'#13#10#13#10 +
    'Ano = Znovu nacist z disku a zrusit tuto akci.'#13#10 +
    'Ne = Ignorovat a pokracovat (prepsat soubor na disku).'#13#10 +
    'Zrusit = Prerusit.';
  GTextCzech.Values['Not enough free disk space to complete this operation safely.'] :=
    'Nedostatek volneho mista na disku pro bezpecne dokonceni teto operace.';
  GTextCzech.Values['Temporary output file was not created.'] := 'Docasny vystupni soubor nebyl vytvoren.';
  GTextCzech.Values['Could not remove or rename the target file (in use or access denied).'] :=
    'Nelze odstranit ani prejmenovat cilovy soubor (pouzivan nebo pristup zamitnut).';
  GTextCzech.Values['Rename reported success but target file is missing.'] :=
    'Prejmenovani ohlasilo uspech, ale cilovy soubor chybi.';
  GTextCzech.Values['Could not finalize save (rename). Error %d: %s'] :=
    'Nelze dokoncit ulozeni (prejmenovani). Chyba %d: %s';
  GTextCzech.Values['Replace-all stopped at the safety limit of %d matches. The file was not modified.'] :=
    'Nahradit vse se zastavilo na bezpecnostnim limitu %d shod. Soubor nebyl zmenen.';

  GTextEnglish.Values['[ReplaceAll] Error: '] := '[ReplaceAll] Error: ';
  GTextPortuguese.Values['[ReplaceAll] Error: '] := '[Substituir tudo] Erro: ';
  GTextSpanish.Values['[ReplaceAll] Error: '] := '[Reemplazar todo] Error: ';
  GTextFrench.Values['[ReplaceAll] Error: '] := '[Remplacer tout] Erreur : ';
  GTextGerman.Values['[ReplaceAll] Error: '] := '[Alle ersetzen] Fehler: ';
  GTextItalian.Values['[ReplaceAll] Error: '] := '[Sostituisci tutto] Errore: ';
  GTextPolish.Values['[ReplaceAll] Error: '] := '[Zamien wszystko] Blad: ';
  GTextPortuguesePT.Values['[ReplaceAll] Error: '] := '[Substituir tudo] Erro: ';
  GTextRomanian.Values['[ReplaceAll] Error: '] := '[Inlocuieste tot] Eroare: ';
  GTextHungarian.Values['[ReplaceAll] Error: '] := '[Mind csere] Hiba: ';
  GTextCzech.Values['[ReplaceAll] Error: '] := '[Nahradit vse] Chyba: ';

  GTextEnglish.Values['[ReplaceAll] '] := '[ReplaceAll] ';
  GTextPortuguese.Values['[ReplaceAll] '] := '[Substituir tudo] ';
  GTextSpanish.Values['[ReplaceAll] '] := '[Reemplazar todo] ';
  GTextFrench.Values['[ReplaceAll] '] := '[Remplacer tout] ';
  GTextGerman.Values['[ReplaceAll] '] := '[Alle ersetzen] ';
  GTextItalian.Values['[ReplaceAll] '] := '[Sostituisci tutto] ';
  GTextPolish.Values['[ReplaceAll] '] := '[Zamien wszystko] ';
  GTextPortuguesePT.Values['[ReplaceAll] '] := '[Substituir tudo] ';
  GTextRomanian.Values['[ReplaceAll] '] := '[Inlocuieste tot] ';
  GTextHungarian.Values['[ReplaceAll] '] := '[Mind csere] ';
  GTextCzech.Values['[ReplaceAll] '] := '[Nahradit vse] ';

  { --- About FastFile dialog (11 languages) ------------------------------ }
  GTextEnglish.Values['Build time: '] := 'Build time: ';
  GTextPortuguese.Values['Build time: '] := 'Data de compilacao: ';
  GTextSpanish.Values['Build time: '] := 'Fecha de compilacion: ';
  GTextFrench.Values['Build time: '] := 'Date de compilation : ';
  GTextGerman.Values['Build time: '] := 'Build-Zeit: ';
  GTextItalian.Values['Build time: '] := 'Data di compilazione: ';
  GTextPolish.Values['Build time: '] := 'Czas kompilacji: ';
  GTextPortuguesePT.Values['Build time: '] := 'Data de compilacao: ';
  GTextRomanian.Values['Build time: '] := 'Data compilarii: ';
  GTextHungarian.Values['Build time: '] := 'Forditas ideje: ';
  GTextCzech.Values['Build time: '] := 'Cas sestaveni: ';

  GTextEnglish.Values['Developed by: '] := 'Developed by: ';
  GTextPortuguese.Values['Developed by: '] := 'Desenvolvido por: ';
  GTextSpanish.Values['Developed by: '] := 'Desarrollado por: ';
  GTextFrench.Values['Developed by: '] := 'D'#233'velopp'#233' par : ';
  GTextGerman.Values['Developed by: '] := 'Entwickelt von: ';
  GTextItalian.Values['Developed by: '] := 'Sviluppato da: ';
  GTextPolish.Values['Developed by: '] := 'Opracowany przez: ';
  GTextPortuguesePT.Values['Developed by: '] := 'Desenvolvido por: ';
  GTextRomanian.Values['Developed by: '] := 'Dezvoltat de: ';
  GTextHungarian.Values['Developed by: '] := 'Fejlesztette: ';
  GTextCzech.Values['Developed by: '] := 'Vyvinul: ';

  GTextEnglish.Values['Contact email:'] := 'Contact email:';
  GTextPortuguese.Values['Contact email:'] := 'E-mail de contato:';
  GTextSpanish.Values['Contact email:'] := 'Correo de contacto:';
  GTextFrench.Values['Contact email:'] := 'E-mail de contact :';
  GTextGerman.Values['Contact email:'] := 'Kontakt-E-Mail:';
  GTextItalian.Values['Contact email:'] := 'Email di contatto:';
  GTextPolish.Values['Contact email:'] := 'E-mail kontaktowy:';
  GTextPortuguesePT.Values['Contact email:'] := 'E-mail de contacto:';
  GTextRomanian.Values['Contact email:'] := 'E-mail de contact:';
  GTextHungarian.Values['Contact email:'] := 'Kapcsolati e-mail:';
  GTextCzech.Values['Contact email:'] := 'Kontaktni e-mail:';

  { --- Go to byte offset + filter prefix (11 languages) ------------------- }
  GTextEnglish.Values['&Go to byte offset...'] := '&Go to byte offset...';
  GTextPortuguese.Values['&Go to byte offset...'] := '&Ir para offset em bytes...';
  GTextSpanish.Values['&Go to byte offset...'] := '&Ir a desplazamiento en bytes...';
  GTextFrench.Values['&Go to byte offset...'] := 'Aller au d'#233'calage en octets...';
  GTextGerman.Values['&Go to byte offset...'] := '&Gehe zu Byte-Offset...';
  GTextItalian.Values['&Go to byte offset...'] := '&Vai all''offset in byte...';
  GTextPolish.Values['&Go to byte offset...'] := 'Prze&jdz do offsetu w bajtach...';
  GTextPortuguesePT.Values['&Go to byte offset...'] := '&Ir para offset em bytes...';
  GTextRomanian.Values['&Go to byte offset...'] := '&Mergi la offset octeti...';
  GTextHungarian.Values['&Go to byte offset...'] := '&Ugras bait offsetre...';
  GTextCzech.Values['&Go to byte offset...'] := '&Prejit na offset v bajtech...';

  GTextEnglish.Values['Go to byte offset'] := 'Go to byte offset';
  GTextPortuguese.Values['Go to byte offset'] := 'Ir para offset em bytes';
  GTextSpanish.Values['Go to byte offset'] := 'Ir a desplazamiento en bytes';
  GTextFrench.Values['Go to byte offset'] := 'Aller au d'#233'calage en octets';
  GTextGerman.Values['Go to byte offset'] := 'Gehe zu Byte-Offset';
  GTextItalian.Values['Go to byte offset'] := 'Vai all''offset in byte';
  GTextPolish.Values['Go to byte offset'] := 'Przejdz do offsetu w bajtach';
  GTextPortuguesePT.Values['Go to byte offset'] := 'Ir para offset em bytes';
  GTextRomanian.Values['Go to byte offset'] := 'Mergi la offset octeti';
  GTextHungarian.Values['Go to byte offset'] := 'Ugras bait offsetre';
  GTextCzech.Values['Go to byte offset'] := 'Prejit na offset v bajtech';

  GTextEnglish.Values['Byte position in file (1-based; $ prefix for hex):'] :=
    'Byte position in file (1-based; $ prefix for hex):';
  GTextPortuguese.Values['Byte position in file (1-based; $ prefix for hex):'] :=
    'Posicao em bytes no arquivo (base 1; prefixo $ para hex):';
  GTextSpanish.Values['Byte position in file (1-based; $ prefix for hex):'] :=
    'Posicion en bytes en el archivo (base 1; prefijo $ para hex):';
  GTextFrench.Values['Byte position in file (1-based; $ prefix for hex):'] :=
    'Position en octets dans le fichier (base 1 ; pr'#233'fixe $ pour hex) :';
  GTextGerman.Values['Byte position in file (1-based; $ prefix for hex):'] :=
    'Byte-Position in der Datei (1-basiert; $-Pr'#228'fix f'#252'r Hex):';
  GTextItalian.Values['Byte position in file (1-based; $ prefix for hex):'] :=
    'Posizione in byte nel file (base 1; prefisso $ per hex):';
  GTextPolish.Values['Byte position in file (1-based; $ prefix for hex):'] :=
    'Pozycja w bajtach w pliku (baza 1; prefiks $ dla hex):';
  GTextPortuguesePT.Values['Byte position in file (1-based; $ prefix for hex):'] :=
    'Posicao em bytes no ficheiro (base 1; prefixo $ para hex):';
  GTextRomanian.Values['Byte position in file (1-based; $ prefix for hex):'] :=
    'Pozitia in octeti in fisier (baza 1; prefix $ pentru hex):';
  GTextHungarian.Values['Byte position in file (1-based; $ prefix for hex):'] :=
    'Bait pozicio a fajlban (1-alapu; $ elotag hexhez):';
  GTextCzech.Values['Byte position in file (1-based; $ prefix for hex):'] :=
    'Pozice v bajtech v souboru (zaklad 1; prefix $ pro hex):';

  GTextEnglish.Values['Invalid byte position.'] := 'Invalid byte position.';
  GTextPortuguese.Values['Invalid byte position.'] := 'Posicao em bytes invalida.';
  GTextSpanish.Values['Invalid byte position.'] := 'Posicion en bytes no valida.';
  GTextFrench.Values['Invalid byte position.'] := 'Position en octets invalide.';
  GTextGerman.Values['Invalid byte position.'] := 'Ung'#252'ltige Byte-Position.';
  GTextItalian.Values['Invalid byte position.'] := 'Posizione in byte non valida.';
  GTextPolish.Values['Invalid byte position.'] := 'Nieprawidlowa pozycja w bajtach.';
  GTextPortuguesePT.Values['Invalid byte position.'] := 'Posicao em bytes invalida.';
  GTextRomanian.Values['Invalid byte position.'] := 'Pozitie octeti invalida.';
  GTextHungarian.Values['Invalid byte position.'] := 'Ervenytelen bait pozicio.';
  GTextCzech.Values['Invalid byte position.'] := 'Neplatna pozice v bajtech.';

  GTextEnglish.Values['Byte position is out of range for this file.'] :=
    'Byte position is out of range for this file.';
  GTextPortuguese.Values['Byte position is out of range for this file.'] :=
    'Posicao em bytes fora do intervalo deste arquivo.';
  GTextSpanish.Values['Byte position is out of range for this file.'] :=
    'Posicion en bytes fuera del rango de este archivo.';
  GTextFrench.Values['Byte position is out of range for this file.'] :=
    'Position en octets hors limites pour ce fichier.';
  GTextGerman.Values['Byte position is out of range for this file.'] :=
    'Byte-Position liegt ausserhalb des Dateibereichs.';
  GTextItalian.Values['Byte position is out of range for this file.'] :=
    'Posizione in byte fuori intervallo per questo file.';
  GTextPolish.Values['Byte position is out of range for this file.'] :=
    'Pozycja w bajtach poza zakresem tego pliku.';
  GTextPortuguesePT.Values['Byte position is out of range for this file.'] :=
    'Posicao em bytes fora do intervalo deste ficheiro.';
  GTextRomanian.Values['Byte position is out of range for this file.'] :=
    'Pozitia in octeti este in afara intervalului pentru acest fisier.';
  GTextHungarian.Values['Byte position is out of range for this file.'] :=
    'A bait pozicio kivul esik a fajl tartomanyan.';
  GTextCzech.Values['Byte position is out of range for this file.'] :=
    'Pozice v bajtech je mimo rozsah tohoto souboru.';

  GTextEnglish.Values['Could not resolve line for that byte position.'] :=
    'Could not resolve line for that byte position.';
  GTextPortuguese.Values['Could not resolve line for that byte position.'] :=
    'Nao foi possivel determinar a linha para essa posicao em bytes.';
  GTextSpanish.Values['Could not resolve line for that byte position.'] :=
    'No se pudo determinar la linea para esa posicion en bytes.';
  GTextFrench.Values['Could not resolve line for that byte position.'] :=
    'Impossible de determiner la ligne pour cette position en octets.';
  GTextGerman.Values['Could not resolve line for that byte position.'] :=
    'Zeile zu dieser Byte-Position konnte nicht ermittelt werden.';
  GTextItalian.Values['Could not resolve line for that byte position.'] :=
    'Impossibile determinare la riga per quella posizione in byte.';
  GTextPolish.Values['Could not resolve line for that byte position.'] :=
    'Nie mozna ustalic linii dla tej pozycji w bajtach.';
  GTextPortuguesePT.Values['Could not resolve line for that byte position.'] :=
    'Nao foi possivel determinar a linha para essa posicao em bytes.';
  GTextRomanian.Values['Could not resolve line for that byte position.'] :=
    'Nu s-a putut determina linia pentru acea pozitie in octeti.';
  GTextHungarian.Values['Could not resolve line for that byte position.'] :=
    'Nem sikerult sort meghatarozni ehhez a bait poziciohoz.';
  GTextCzech.Values['Could not resolve line for that byte position.'] :=
    'Nepodarilo se urcit radek pro tuto pozici v bajtech.';

  GTextEnglish.Values['Filter: use line prefix match? (Yes = line starts with text, No = contains anywhere)'] :=
    'Filter: use line prefix match? (Yes = line starts with text, No = contains anywhere)';
  GTextPortuguese.Values['Filter: use line prefix match? (Yes = line starts with text, No = contains anywhere)'] :=
    'Filtro: coincidir com prefixo da linha? (Sim = linha comeca com o texto, Nao = contem em qualquer lugar)';
  GTextSpanish.Values['Filter: use line prefix match? (Yes = line starts with text, No = contains anywhere)'] :=
    'Filtro: '#191'coincidir con prefijo de linea? (Si = la linea empieza con el texto, No = contiene en cualquier sitio)';
  GTextFrench.Values['Filter: use line prefix match? (Yes = line starts with text, No = contains anywhere)'] :=
    'Filtre : correspondance par pr'#233'fixe de ligne ? (Oui = la ligne commence par le texte, Non = contient n''importe o'#249')';
  GTextGerman.Values['Filter: use line prefix match? (Yes = line starts with text, No = contains anywhere)'] :=
    'Filter: Zeilenpr'#228'fix? (Ja = Zeile beginnt mit Text, Nein = enth'#228'lt irgendwo)';
  GTextItalian.Values['Filter: use line prefix match? (Yes = line starts with text, No = contains anywhere)'] :=
    'Filtro: prefisso di riga? (Si = la riga inizia con il testo, No = contiene ovunque)';
  GTextPolish.Values['Filter: use line prefix match? (Yes = line starts with text, No = contains anywhere)'] :=
    'Filtr: dopasowanie prefiksu linii? (Tak = linia zaczyna sie od tekstu, Nie = zawiera gdziekolwiek)';
  GTextPortuguesePT.Values['Filter: use line prefix match? (Yes = line starts with text, No = contains anywhere)'] :=
    'Filtro: coincidir com prefixo da linha? (Sim = linha comeca com o texto, Nao = contem em qualquer lugar)';
  GTextRomanian.Values['Filter: use line prefix match? (Yes = line starts with text, No = contains anywhere)'] :=
    'Filtru: potrivire prefix linie? (Da = linia incepe cu textul, Nu = contine oriunde)';
  GTextHungarian.Values['Filter: use line prefix match? (Yes = line starts with text, No = contains anywhere)'] :=
    'Szuro: sor eleje egyezik? (Igen = a sor a szoveggel kezdodik, Nem = barmhol tartalmazza)';
  GTextCzech.Values['Filter: use line prefix match? (Yes = line starts with text, No = contains anywhere)'] :=
    'Filtr: shoda prefixu radku? (Ano = radek zacina textem, Ne = obsahuje kdekoli)';

  { --- Filter / find / replace / encoding (2026-04) ------------------------ }
  GTextEnglish.Values['Show only lines matching (text or regex pattern):'] :=
    'Show only lines matching (text or regex pattern):';
  GTextPortuguese.Values['Show only lines matching (text or regex pattern):'] :=
    'Mostrar apenas linhas que coincidem (texto ou padrao regex):';
  GTextSpanish.Values['Show only lines matching (text or regex pattern):'] :=
    'Mostrar solo lineas que coinciden (texto o patron regex):';
  GTextFrench.Values['Show only lines matching (text or regex pattern):'] :=
    'Afficher uniquement les lignes correspondantes (texte ou motif regex) :';
  GTextGerman.Values['Show only lines matching (text or regex pattern):'] :=
    'Nur passende Zeilen anzeigen (Text oder Regex-Muster):';
  GTextItalian.Values['Show only lines matching (text or regex pattern):'] :=
    'Mostra solo le righe corrispondenti (testo o pattern regex):';
  GTextPolish.Values['Show only lines matching (text or regex pattern):'] :=
    'Pokaz tylko pasujace linie (tekst lub wzorzec regex):';
  GTextPortuguesePT.Values['Show only lines matching (text or regex pattern):'] :=
    'Mostrar apenas linhas que coincidem (texto ou padrao regex):';
  GTextRomanian.Values['Show only lines matching (text or regex pattern):'] :=
    'Afiseaza doar liniile care se potrivesc (text sau sablon regex):';
  GTextHungarian.Values['Show only lines matching (text or regex pattern):'] :=
    'Csak az egyezo sorok megjelenitese (szoveg vagy regex minta):';
  GTextCzech.Values['Show only lines matching (text or regex pattern):'] :=
    'Zobrazit pouze vyhovujici radky (text nebo regex vzor):';

  GTextEnglish.Values['Filter match mode: Yes = line starts with, No = contains, OK = regex (VBScript). Cancel = abort.'] :=
    'Filter match mode: Yes = line starts with, No = contains, OK = regex (VBScript). Cancel = abort.';
  GTextPortuguese.Values['Filter match mode: Yes = line starts with, No = contains, OK = regex (VBScript). Cancel = abort.'] :=
    'Modo do filtro: Sim = linha comeca com, Nao = contem, OK = regex (VBScript). Cancelar = abortar.';
  GTextSpanish.Values['Filter match mode: Yes = line starts with, No = contains, OK = regex (VBScript). Cancel = abort.'] :=
    'Modo de filtro: Si = la linea empieza con, No = contiene, OK = regex (VBScript). Cancelar = abortar.';
  GTextFrench.Values['Filter match mode: Yes = line starts with, No = contains, OK = regex (VBScript). Cancel = abort.'] :=
    'Mode filtre : Oui = la ligne commence par, Non = contient, OK = regex (VBScript). Annuler = abandon.';
  GTextGerman.Values['Filter match mode: Yes = line starts with, No = contains, OK = regex (VBScript). Cancel = abort.'] :=
    'Filtermodus: Ja = Zeile beginnt mit, Nein = enthalt, OK = Regex (VBScript). Abbrechen = Abbruch.';
  GTextItalian.Values['Filter match mode: Yes = line starts with, No = contains, OK = regex (VBScript). Cancel = abort.'] :=
    'Modalita filtro: Si = la riga inizia con, No = contiene, OK = regex (VBScript). Annulla = interrompi.';
  GTextPolish.Values['Filter match mode: Yes = line starts with, No = contains, OK = regex (VBScript). Cancel = abort.'] :=
    'Tryb filtra: Tak = linia zaczyna sie od, Nie = zawiera, OK = regex (VBScript). Anuluj = przerwij.';
  GTextPortuguesePT.Values['Filter match mode: Yes = line starts with, No = contains, OK = regex (VBScript). Cancel = abort.'] :=
    'Modo do filtro: Sim = linha comeca com, Nao = contem, OK = regex (VBScript). Cancelar = abortar.';
  GTextRomanian.Values['Filter match mode: Yes = line starts with, No = contains, OK = regex (VBScript). Cancel = abort.'] :=
    'Mod filtru: Da = linia incepe cu, Nu = contine, OK = regex (VBScript). Renunta = intrerupe.';
  GTextHungarian.Values['Filter match mode: Yes = line starts with, No = contains, OK = regex (VBScript). Cancel = abort.'] :=
    'Szuro mod: Igen = a sor eleje, Nem = tartalmazza, OK = regex (VBScript). Megse = megszakit.';
  GTextCzech.Values['Filter match mode: Yes = line starts with, No = contains, OK = regex (VBScript). Cancel = abort.'] :=
    'Rezim filtru: Ano = radek zacina, Ne = obsahuje, OK = regex (VBScript). Storno = prerusit.';

  GTextEnglish.Values['Regular expression: match case? (Yes = case sensitive, No = ignore case)'] :=
    'Regular expression: match case? (Yes = case sensitive, No = ignore case)';
  GTextPortuguese.Values['Regular expression: match case? (Yes = case sensitive, No = ignore case)'] :=
    'Expressao regular: diferenciar maiusculas? (Sim = sim, Nao = ignorar maiusculas)';
  GTextSpanish.Values['Regular expression: match case? (Yes = case sensitive, No = ignore case)'] :=
    'Expresion regular: '#191'sensible a mayusculas? (Si = si, No = ignorar)';
  GTextFrench.Values['Regular expression: match case? (Yes = case sensitive, No = ignore case)'] :=
    'Expression reguliere : respecter la casse ? (Oui = sensible, Non = ignorer)';
  GTextGerman.Values['Regular expression: match case? (Yes = case sensitive, No = ignore case)'] :=
    'Regul'#228'rer Ausdruck: Gross/Kleinschreibung? (Ja = beachten, Nein = ignorieren)';
  GTextItalian.Values['Regular expression: match case? (Yes = case sensitive, No = ignore case)'] :=
    'Espressione regolare: maiuscole? (Si = sensibile, No = ignora)';
  GTextPolish.Values['Regular expression: match case? (Yes = case sensitive, No = ignore case)'] :=
    'Wyrazenie regularne: wielkosc liter? (Tak = uwzgledniaj, Nie = ignoruj)';
  GTextPortuguesePT.Values['Regular expression: match case? (Yes = case sensitive, No = ignore case)'] :=
    'Expressao regular: diferenciar maiusculas? (Sim = sim, Nao = ignorar maiusculas)';
  GTextRomanian.Values['Regular expression: match case? (Yes = case sensitive, No = ignore case)'] :=
    'Expresie regulata: majuscule? (Da = sensibil, Nu = ignora)';
  GTextHungarian.Values['Regular expression: match case? (Yes = case sensitive, No = ignore case)'] :=
    'Regul'#225'ris kifejez'#233's: kis/nagybetu? (Igen = erz'#233'keny, Nem = figyelmen kivul)';
  GTextCzech.Values['Regular expression: match case? (Yes = case sensitive, No = ignore case)'] :=
    'Regularni vyraz: velka/mala pismena? (Ano = rozlisovat, Ne = ignorovat)';

  GTextEnglish.Values['VBScript.RegExp is not available (invalid pattern or missing component).'] :=
    'VBScript.RegExp is not available (invalid pattern or missing component).';
  GTextPortuguese.Values['VBScript.RegExp is not available (invalid pattern or missing component).'] :=
    'VBScript.RegExp nao esta disponivel (padrao invalido ou componente em falta).';
  GTextSpanish.Values['VBScript.RegExp is not available (invalid pattern or missing component).'] :=
    'VBScript.RegExp no esta disponible (patron invalido o componente ausente).';
  GTextFrench.Values['VBScript.RegExp is not available (invalid pattern or missing component).'] :=
    'VBScript.RegExp indisponible (motif invalide ou composant manquant).';
  GTextGerman.Values['VBScript.RegExp is not available (invalid pattern or missing component).'] :=
    'VBScript.RegExp nicht verfugbar (ungultiges Muster oder fehlende Komponente).';
  GTextItalian.Values['VBScript.RegExp is not available (invalid pattern or missing component).'] :=
    'VBScript.RegExp non disponibile (modello non valido o componente mancante).';
  GTextPolish.Values['VBScript.RegExp is not available (invalid pattern or missing component).'] :=
    'VBScript.RegExp niedostepny (nieprawidlowy wzor lub brak skladnika).';
  GTextPortuguesePT.Values['VBScript.RegExp is not available (invalid pattern or missing component).'] :=
    'VBScript.RegExp nao esta disponivel (padrao invalido ou componente em falta).';
  GTextRomanian.Values['VBScript.RegExp is not available (invalid pattern or missing component).'] :=
    'VBScript.RegExp indisponibil (sablon invalid sau component lipsa).';
  GTextHungarian.Values['VBScript.RegExp is not available (invalid pattern or missing component).'] :=
    'VBScript.RegExp nem elerheto (ervenytelen minta vagy hianyzo komponens).';
  GTextCzech.Values['VBScript.RegExp is not available (invalid pattern or missing component).'] :=
    'VBScript.RegExp neni k dispozici (neplatny vzor nebo chybejici komponenta).';

  GTextEnglish.Values['Could not initialize COM for the regex filter.'] :=
    'Could not initialize COM for the regex filter.';
  GTextPortuguese.Values['Could not initialize COM for the regex filter.'] :=
    'Nao foi possivel inicializar o COM para o filtro regex.';
  GTextSpanish.Values['Could not initialize COM for the regex filter.'] :=
    'No se pudo inicializar COM para el filtro regex.';
  GTextFrench.Values['Could not initialize COM for the regex filter.'] :=
    'Impossible d''initialiser COM pour le filtre regex.';
  GTextGerman.Values['Could not initialize COM for the regex filter.'] :=
    'COM konnte fur den Regex-Filter nicht initialisiert werden.';
  GTextItalian.Values['Could not initialize COM for the regex filter.'] :=
    'Impossibile inizializzare COM per il filtro regex.';
  GTextPolish.Values['Could not initialize COM for the regex filter.'] :=
    'Nie mozna zainicjowac COM dla filtru regex.';
  GTextPortuguesePT.Values['Could not initialize COM for the regex filter.'] :=
    'Nao foi possivel inicializar o COM para o filtro regex.';
  GTextRomanian.Values['Could not initialize COM for the regex filter.'] :=
    'Nu s-a putut initializa COM pentru filtrul regex.';
  GTextHungarian.Values['Could not initialize COM for the regex filter.'] :=
    'A COM nem inicializalhato a regex szurohoz.';
  GTextCzech.Values['Could not initialize COM for the regex filter.'] :=
    'Nelze inicializovat COM pro regex filtr.';

  GTextEnglish.Values['Filter: line count too large for filter memory (32-bit limit).'] :=
    'Filter: line count too large for filter memory (32-bit limit).';
  GTextPortuguese.Values['Filter: line count too large for filter memory (32-bit limit).'] :=
    'Filtro: numero de linhas excede a memoria segura do filtro (limite 32-bit).';
  GTextSpanish.Values['Filter: line count too large for filter memory (32-bit limit).'] :=
    'Filtro: demasiadas lineas para la memoria del filtro (limite 32-bit).';
  GTextFrench.Values['Filter: line count too large for filter memory (32-bit limit).'] :=
    'Filtre : trop de lignes pour la memoire du filtre (limite 32 bits).';
  GTextGerman.Values['Filter: line count too large for filter memory (32-bit limit).'] :=
    'Filter: Zeilenzahl zu gross fur Filterspeicher (32-Bit-Grenze).';
  GTextItalian.Values['Filter: line count too large for filter memory (32-bit limit).'] :=
    'Filtro: troppe righe per la memoria del filtro (limite 32-bit).';
  GTextPolish.Values['Filter: line count too large for filter memory (32-bit limit).'] :=
    'Filtr: zbyt wiele linii dla pamieci filtra (limit 32-bit).';
  GTextPortuguesePT.Values['Filter: line count too large for filter memory (32-bit limit).'] :=
    'Filtro: numero de linhas excede a memoria segura do filtro (limite 32-bit).';
  GTextRomanian.Values['Filter: line count too large for filter memory (32-bit limit).'] :=
    'Filtru: prea multe linii pentru memoria filtrului (limita 32-bit).';
  GTextHungarian.Values['Filter: line count too large for filter memory (32-bit limit).'] :=
    'Szuro: a sorok szama meghaladja a szuro memoriakorlatjat (32-bit).';
  GTextCzech.Values['Filter: line count too large for filter memory (32-bit limit).'] :=
    'Filtr: prilis mnoho radku pro pamet filtru (limit 32-bit).';

  GTextEnglish.Values['Search cancelled.'] := 'Search cancelled.';
  GTextPortuguese.Values['Search cancelled.'] := 'Pesquisa cancelada.';
  GTextSpanish.Values['Search cancelled.'] := 'Busqueda cancelada.';
  GTextFrench.Values['Search cancelled.'] := 'Recherche annulee.';
  GTextGerman.Values['Search cancelled.'] := 'Suche abgebrochen.';
  GTextItalian.Values['Search cancelled.'] := 'Ricerca annullata.';
  GTextPolish.Values['Search cancelled.'] := 'Wyszukiwanie anulowane.';
  GTextPortuguesePT.Values['Search cancelled.'] := 'Pesquisa cancelada.';
  GTextRomanian.Values['Search cancelled.'] := 'Cautare anulata.';
  GTextHungarian.Values['Search cancelled.'] := 'Kereses megszakitva.';
  GTextCzech.Values['Search cancelled.'] := 'Hledani zruseno.';

  GTextEnglish.Values['replacements'] := 'replacements';
  GTextPortuguese.Values['replacements'] := 'substituicoes';
  GTextSpanish.Values['replacements'] := 'reemplazos';
  GTextFrench.Values['replacements'] := 'remplacements';
  GTextGerman.Values['replacements'] := 'Ersetzungen';
  GTextItalian.Values['replacements'] := 'sostituzioni';
  GTextPolish.Values['replacements'] := 'zamiany';
  GTextPortuguesePT.Values['replacements'] := 'substituicoes';
  GTextRomanian.Values['replacements'] := 'inlocuiri';
  GTextHungarian.Values['replacements'] := 'cserek';
  GTextCzech.Values['replacements'] := 'nahrazeni';

  GTextEnglish.Values['Filtering'] := 'Filtering';
  GTextPortuguese.Values['Filtering'] := 'A filtrar';
  GTextSpanish.Values['Filtering'] := 'Filtrando';
  GTextFrench.Values['Filtering'] := 'Filtrage';
  GTextGerman.Values['Filtering'] := 'Filtere';
  GTextItalian.Values['Filtering'] := 'Filtro in corso';
  GTextPolish.Values['Filtering'] := 'Filtrowanie';
  GTextPortuguesePT.Values['Filtering'] := 'A filtrar';
  GTextRomanian.Values['Filtering'] := 'Filtrare';
  GTextHungarian.Values['Filtering'] := 'Szures';
  GTextCzech.Values['Filtering'] := 'Filtrovani';

  GTextEnglish.Values['lines'] := 'lines';
  GTextPortuguese.Values['lines'] := 'linhas';
  GTextSpanish.Values['lines'] := 'lineas';
  GTextFrench.Values['lines'] := 'lignes';
  GTextGerman.Values['lines'] := 'Zeilen';
  GTextItalian.Values['lines'] := 'righe';
  GTextPolish.Values['lines'] := 'linii';
  GTextPortuguesePT.Values['lines'] := 'linhas';
  GTextRomanian.Values['lines'] := 'linii';
  GTextHungarian.Values['lines'] := 'sorok';
  GTextCzech.Values['lines'] := 'radku';

  GTextEnglish.Values['Streaming replace writes a temp file, then swaps it over the original when possible. Free disk space is checked first. A safety limit on match count applies. This cannot be undone.'] :=
    'Streaming replace writes a temp file, then swaps it over the original when possible. Free disk space is checked first. A safety limit on match count applies. This cannot be undone.';
  GTextPortuguese.Values['Streaming replace writes a temp file, then swaps it over the original when possible. Free disk space is checked first. A safety limit on match count applies. This cannot be undone.'] :=
    'Substituir tudo em streaming grava um ficheiro temporario e depois substitui o original quando possivel. O espaco livre e verificado primeiro. Aplica-se um limite de seguranca no numero de correspondencias. Nao pode ser anulado.';
  GTextSpanish.Values['Streaming replace writes a temp file, then swaps it over the original when possible. Free disk space is checked first. A safety limit on match count applies. This cannot be undone.'] :=
    'Reemplazar todo en streaming escribe un temporal y luego sustituye el original cuando es posible. Primero se comprueba el espacio libre. Hay un limite de seguridad en coincidencias. No se puede deshacer.';
  GTextFrench.Values['Streaming replace writes a temp file, then swaps it over the original when possible. Free disk space is checked first. A safety limit on match count applies. This cannot be undone.'] :=
    'Remplacer tout en flux ecrit un fichier temporaire puis remplace l''original si possible. L''espace disque est verifie en premier. Une limite de securite sur le nombre de correspondances s''applique. Operation irreversible.';
  GTextGerman.Values['Streaming replace writes a temp file, then swaps it over the original when possible. Free disk space is checked first. A safety limit on match count applies. This cannot be undone.'] :=
    'Streaming-Ersetzen schreibt eine Temp-Datei und ersetzt dann die Originaldatei wenn moglich. Freier Speicher wird zuerst gepruft. Ein Sicherheitslimit fur Treffer gilt. Nicht ruckgangig.';
  GTextItalian.Values['Streaming replace writes a temp file, then swaps it over the original when possible. Free disk space is checked first. A safety limit on match count applies. This cannot be undone.'] :=
    'Sostituzione in streaming su file temporaneo, poi scambio con l''originale se possibile. Prima si verifica lo spazio libero. Vale un limite di sicurezza sul numero di occorrenze. Operazione irreversibile.';
  GTextPolish.Values['Streaming replace writes a temp file, then swaps it over the original when possible. Free disk space is checked first. A safety limit on match count applies. This cannot be undone.'] :=
    'Strumieniowe zamienianie zapisuje plik tymczasowy, potem podmienia oryginal, gdy to mozliwe. Najpierw sprawdzany jest wolny dysk. Obowiazuje limit dopasowan. Operacji nie cofniesz.';
  GTextPortuguesePT.Values['Streaming replace writes a temp file, then swaps it over the original when possible. Free disk space is checked first. A safety limit on match count applies. This cannot be undone.'] :=
    'Substituir tudo em streaming grava um ficheiro temporario e depois substitui o original quando possivel. O espaco livre e verificado primeiro. Aplica-se um limite de seguranca no numero de correspondencias. Nao pode ser anulado.';
  GTextRomanian.Values['Streaming replace writes a temp file, then swaps it over the original when possible. Free disk space is checked first. A safety limit on match count applies. This cannot be undone.'] :=
    'Inlocuire in flux scrie un fisier temporar, apoi il inlocuieste pe cel original cand e posibil. Spatiul liber e verificat mai intai. Se aplica o limita de siguranta la numarul de potriviri. Nu se poate anula.';
  GTextHungarian.Values['Streaming replace writes a temp file, then swaps it over the original when possible. Free disk space is checked first. A safety limit on match count applies. This cannot be undone.'] :=
    'Streamelt csere ideiglenes fajt ir, majd lecsereli az eredetit, ha lehet. Eloszor a szabad hely ellenorzese. Talalati limit van. Nem vonhato vissza.';
  GTextCzech.Values['Streaming replace writes a temp file, then swaps it over the original when possible. Free disk space is checked first. A safety limit on match count applies. This cannot be undone.'] :=
    'Streamovane nahrazovani zapise docasny soubor a pak ho prohodi za original, pokud to jde. Nejdrive se kontroluje volne misto. Plati bezpecnostni limit shod. Nelze vratit zpet.';

  GTextEnglish.Values['Line-segmented processing for heavy operations (off by default)'] :=
    'Line-segmented processing for heavy operations (off by default)';
  GTextPortuguese.Values['Line-segmented processing for heavy operations (off by default)'] :=
    'Processamento por segmentos de linha para opera'#231#245'es pesadas (desligado por padr'#227'o)';
  GTextSpanish.Values['Line-segmented processing for heavy operations (off by default)'] :=
    'Procesamiento por segmentos de l'#237'nea para operaciones pesadas (desactivado por defecto)';
  GTextFrench.Values['Line-segmented processing for heavy operations (off by default)'] :=
    'Traitement segment'#233' par lignes pour op'#233'rations lourdes (d'#233'sactiv'#233' par d'#233'faut)';
  GTextGerman.Values['Line-segmented processing for heavy operations (off by default)'] :=
    'Zeilenweise segmentierte Verarbeitung bei schweren Operationen (standardm'#228#223'ig aus)';
  GTextItalian.Values['Line-segmented processing for heavy operations (off by default)'] :=
    'Elaborazione segmentata per righe per operazioni pesanti (disattivata di default)';
  GTextPolish.Values['Line-segmented processing for heavy operations (off by default)'] :=
    'Przetwarzanie segmentowe (linie) dla ciezkich operacji (domyslnie wylaczone)';
  GTextPortuguesePT.Values['Line-segmented processing for heavy operations (off by default)'] :=
    'Processamento por segmentos de linha para opera'#231#245'es pesadas (desligado por predefini'#231#227'o)';
  GTextRomanian.Values['Line-segmented processing for heavy operations (off by default)'] :=
    'Procesare segmentata pe linii pentru operatii grele (dezactivata implicit)';
  GTextHungarian.Values['Line-segmented processing for heavy operations (off by default)'] :=
    'Soronkent szegmentalt feldolgozas nehez muveletekhez (alapbol ki)';
  GTextCzech.Values['Line-segmented processing for heavy operations (off by default)'] :=
    'Segmentovane zpracovani podle radku pro narocne operace (vypnuto implicitne)';

  GTextEnglish.Values['Line-segmented &mode (heavy ops)'] :=
    'Line-segmented &mode (heavy ops)';
  GTextPortuguese.Values['Line-segmented &mode (heavy ops)'] :=
    'Modo &segmentado por linhas (ops. pesadas)';
  GTextSpanish.Values['Line-segmented &mode (heavy ops)'] :=
    'Modo &segmentado por l'#237'neas (ops. pesadas)';
  GTextFrench.Values['Line-segmented &mode (heavy ops)'] :=
    'Mode &segment'#233' par lignes (op. lourdes)';
  GTextGerman.Values['Line-segmented &mode (heavy ops)'] :=
    '&Zeilensegment-Modus (schwere Op.)';
  GTextItalian.Values['Line-segmented &mode (heavy ops)'] :=
    'Modo &segmentato per righe (op. pesanti)';
  GTextPolish.Values['Line-segmented &mode (heavy ops)'] :=
    'Tryb &segmentowy linii (ciezkie op.)';
  GTextPortuguesePT.Values['Line-segmented &mode (heavy ops)'] :=
    'Modo &segmentado por linhas (op. pesadas)';
  GTextRomanian.Values['Line-segmented &mode (heavy ops)'] :=
    'Mod &segmentat pe linii (op. grele)';
  GTextHungarian.Values['Line-segmented &mode (heavy ops)'] :=
    '&Soronkent szegmentalt mod (nehhez muveletek)';
  GTextCzech.Values['Line-segmented &mode (heavy ops)'] :=
    '&Segmentace podle radku (tezke operace)';

  GTextEnglish.Values['  Ctrl+Alt+R ........ Toggle read-only session (blocks disk writes from the Read tab)'] :=
    '  Ctrl+Alt+R ........ Toggle read-only session (blocks disk writes from the Read tab)';
  GTextPortuguese.Values['  Ctrl+Alt+R ........ Toggle read-only session (blocks disk writes from the Read tab)'] :=
    '  Ctrl+Alt+R ........ Alternar sess'#227'o somente leitura (bloqueia grava'#231#227'o no separador Read)';
  GTextSpanish.Values['  Ctrl+Alt+R ........ Toggle read-only session (blocks disk writes from the Read tab)'] :=
    '  Ctrl+Alt+R ........ Alternar sesi'#243'n solo lectura (bloquea escrituras en la pesta'#241'a Read)';
  GTextFrench.Values['  Ctrl+Alt+R ........ Toggle read-only session (blocks disk writes from the Read tab)'] :=
    '  Ctrl+Alt+R ........ Basculer la session lecture seule (ecriture disque bloquee dans l''onglet Read)';
  GTextGerman.Values['  Ctrl+Alt+R ........ Toggle read-only session (blocks disk writes from the Read tab)'] :=
    '  Ctrl+Alt+R ........ Nur-Lese-Sitzung umschalten (Schreiben im Read-Tab blockiert)';
  GTextItalian.Values['  Ctrl+Alt+R ........ Toggle read-only session (blocks disk writes from the Read tab)'] :=
    '  Ctrl+Alt+R ........ Attiva/disattiva sessione sola lettura (blocca scritture su disco nella scheda Read)';
  GTextPolish.Values['  Ctrl+Alt+R ........ Toggle read-only session (blocks disk writes from the Read tab)'] :=
    '  Ctrl+Alt+R ........ Przelacz sesje tylko do odczytu (blokuje zapis z karty Read)';
  GTextPortuguesePT.Values['  Ctrl+Alt+R ........ Toggle read-only session (blocks disk writes from the Read tab)'] :=
    '  Ctrl+Alt+R ........ Alternar sess'#227'o apenas de leitura (bloqueia grava'#231#227'o no separador Read)';
  GTextRomanian.Values['  Ctrl+Alt+R ........ Toggle read-only session (blocks disk writes from the Read tab)'] :=
    '  Ctrl+Alt+R ........ Comutare sesiune doar-citire (blocheaza scrierile pe disc in fila Read)';
  GTextHungarian.Values['  Ctrl+Alt+R ........ Toggle read-only session (blocks disk writes from the Read tab)'] :=
    '  Ctrl+Alt+R ........ Csak olvashato munkamenet ki/be (Read fulon lemeziras tiltva)';
  GTextCzech.Values['  Ctrl+Alt+R ........ Toggle read-only session (blocks disk writes from the Read tab)'] :=
    '  Ctrl+Alt+R ........ Prepina relaci pouze pro cteni (blokuje zapis na disk na zalozce Read)';

  GTextEnglish.Values['Dialogs'] := 'Dialogs';
  GTextPortuguese.Values['Dialogs'] := 'Di'#225'logos';
  GTextSpanish.Values['Dialogs'] := 'Di'#225'logos';
  GTextFrench.Values['Dialogs'] := 'Bo'#238'tes de dialogue';
  GTextGerman.Values['Dialogs'] := 'Dialoge';
  GTextItalian.Values['Dialogs'] := 'Finestre di dialogo';
  GTextPolish.Values['Dialogs'] := 'Okna dialogowe';
  GTextPortuguesePT.Values['Dialogs'] := 'Di'#225'logos';
  GTextRomanian.Values['Dialogs'] := 'Dialoguri';
  GTextHungarian.Values['Dialogs'] := 'Parbeszedablakok';
  GTextCzech.Values['Dialogs'] := 'Dialogy';

  GTextEnglish.Values['FastFile - Version History'] := 'FastFile - Version History';
  GTextPortuguese.Values['FastFile - Version History'] := 'FastFile - Hist'#243'rico de vers'#245'es';
  GTextSpanish.Values['FastFile - Version History'] := 'FastFile - Historial de versiones';
  GTextFrench.Values['FastFile - Version History'] := 'FastFile - Historique des versions';
  GTextGerman.Values['FastFile - Version History'] := 'FastFile - Versionshistorie';
  GTextItalian.Values['FastFile - Version History'] := 'FastFile - Cronologia versioni';
  GTextPolish.Values['FastFile - Version History'] := 'FastFile - Historia wersji';
  GTextPortuguesePT.Values['FastFile - Version History'] := 'FastFile - Hist'#243'rico de vers'#245'es';
  GTextRomanian.Values['FastFile - Version History'] := 'FastFile - Istoric versiuni';
  GTextHungarian.Values['FastFile - Version History'] := 'FastFile - Verzio tortenet';
  GTextCzech.Values['FastFile - Version History'] := 'FastFile - Historie verzi';

  GTextEnglish.Values['When enabled, Replace All and batch delete of checked lines may process the file in line-aligned segments (temporary parts), then merge. Can reduce peak memory on very large files. Replace All: search text that spans a segment boundary may not match.'] :=
    'When enabled, Replace All and batch delete of checked lines may process the file ' +
    'in line-aligned segments (temporary parts), then merge. Can reduce peak memory ' +
    'on very large files. Replace All: search text that spans a segment boundary may not match.';
  GTextPortuguese.Values['When enabled, Replace All and batch delete of checked lines may process the file in line-aligned segments (temporary parts), then merge. Can reduce peak memory on very large files. Replace All: search text that spans a segment boundary may not match.'] :=
    'Quando ativo, Substituir tudo e a exclus'#227'o em lote das linhas assinaladas podem ' +
    'processar o ficheiro em segmentos alinhados a linhas (partes tempor'#225'rias) e depois ' +
    'juntar. Pode reduzir o pico de mem'#243'ria em ficheiros muito grandes. Substituir tudo: ' +
    'textos que atravessem o limite de um segmento podem n'#227'o coincidir.';
  GTextSpanish.Values['When enabled, Replace All and batch delete of checked lines may process the file in line-aligned segments (temporary parts), then merge. Can reduce peak memory on very large files. Replace All: search text that spans a segment boundary may not match.'] :=
    'Si est'#225' activo, Reemplazar todo y el borrado por lotes de l'#237'neas marcadas pueden ' +
    'procesar el archivo en segmentos alineados a l'#237'neas (partes temporales) y luego unir. ' +
    'Puede reducir el pico de memoria en archivos muy grandes. Reemplazar todo: textos que ' +
    'crucen el l'#237'mite de un segmento pueden no coincidir.';
  GTextFrench.Values['When enabled, Replace All and batch delete of checked lines may process the file in line-aligned segments (temporary parts), then merge. Can reduce peak memory on very large files. Replace All: search text that spans a segment boundary may not match.'] :=
    'Si active, Remplacer tout et la suppression par lots des lignes coch'#233'es peuvent ' +
    'traiter le fichier par segments align'#233's sur les lignes (parties temporaires), puis ' +
    'fusionner. Peut r'#233'duire le pic m'#233'moire sur tr'#232's gros fichiers. Remplacer tout: ' +
    'une recherche '#224' cheval sur une limite de segment peut ne pas correspondre.';
  GTextGerman.Values['When enabled, Replace All and batch delete of checked lines may process the file in line-aligned segments (temporary parts), then merge. Can reduce peak memory on very large files. Replace All: search text that spans a segment boundary may not match.'] :=
    'Wenn aktiv, k'#246'nnen Ersetzen alle und das stapelweise L'#246'schen markierter Zeilen ' +
    'die Datei zeilenweise in Teilen verarbeiten (tempor'#228'r) und zusammenf'#252'gen. Kann ' +
    'Spitzenlast bei sehr gro'#223'en Dateien senken. Ersetzen alle: Suchtexte '#252'ber ' +
    'Segmentgrenzen hinweg k'#246'nnen fehlen.';
  GTextItalian.Values['When enabled, Replace All and batch delete of checked lines may process the file in line-aligned segments (temporary parts), then merge. Can reduce peak memory on very large files. Replace All: search text that spans a segment boundary may not match.'] :=
    'Se attivo, Sostituisci tutto e l''eliminazione in batch delle righe selezionate ' +
    'possono elaborare il file in segmenti allineati alle righe (parti temporanee) e poi ' +
    'unire. Pu'#242' ridurre il picco di memoria su file molto grandi. Sostituisci tutto: ' +
    'testi a cavallo del confine di segmento possono non corrispondere.';
  GTextPolish.Values['When enabled, Replace All and batch delete of checked lines may process the file in line-aligned segments (temporary parts), then merge. Can reduce peak memory on very large files. Replace All: search text that spans a segment boundary may not match.'] :=
    'Po wlaczeniu Zamien wszystko i wsadowe usuwanie zaznaczonych linii moga ' +
    'przetwarzac plik w segmentach wg linii (tymczasowe czesci), potem laczyc. Moze ' +
    'zmniejszyc szczyt pamieci przy bardzo duzych plikach. Zamien wszystko: tekst na ' +
    'granicy segmentu moze nie pasowac.';
  GTextPortuguesePT.Values['When enabled, Replace All and batch delete of checked lines may process the file in line-aligned segments (temporary parts), then merge. Can reduce peak memory on very large files. Replace All: search text that spans a segment boundary may not match.'] :=
    'Quando ativo, Substituir tudo e a elimina'#231#227'o em lote das linhas assinaladas podem ' +
    'processar o ficheiro em segmentos alinhados a linhas (partes tempor'#225'rias) e depois ' +
    'juntar. Pode reduzir o pico de mem'#243'ria em ficheiros muito grandes. Substituir tudo: ' +
    'textos que atravessem o limite de um segmento podem n'#227'o coincidir.';
  GTextRomanian.Values['When enabled, Replace All and batch delete of checked lines may process the file in line-aligned segments (temporary parts), then merge. Can reduce peak memory on very large files. Replace All: search text that spans a segment boundary may not match.'] :=
    'Cand activ, Inlocuieste tot si stergerea in lot a liniilor bifate pot procesa ' +
    'fisierul in segmente aliniate pe linii (parti temporare), apoi unifica. Poate reduce ' +
    'varful de memorie pe fisiere foarte mari. Inlocuieste tot: textul de la granita de ' +
    'segment poate fi ratat.';
  GTextHungarian.Values['When enabled, Replace All and batch delete of checked lines may process the file in line-aligned segments (temporary parts), then merge. Can reduce peak memory on very large files. Replace All: search text that spans a segment boundary may not match.'] :=
    'Ha be van kapcsolva, az Osszes cseréje es a kijelolt sorok csomagos torlese ' +
    'soronkent szegmentalt, ideiglenes reszekre bonthatja a fajlt, majd osszeilleszti. ' +
    'Csokkentheti a memoriacsucsot nagy fajlokon. Osszes cseréje: a szegmens-hataron ' +
    'atnyulo szoveg kimaradhat.';
  GTextCzech.Values['When enabled, Replace All and batch delete of checked lines may process the file in line-aligned segments (temporary parts), then merge. Can reduce peak memory on very large files. Replace All: search text that spans a segment boundary may not match.'] :=
    'Je-li zapnuto, Nahradit vse a davkove mazani oznacenych radku mohou soubor ' +
    'zpracovat po radech v segmentech (docasne casti) a pak sloucit. Muze snizit spicku ' +
    'pameti u velmi velkych souboru. Nahradit vse: text pres hranici segmentu nemusi sedet.';

  GTextEnglish.Values['Line-segmented mode is ON: Replace All runs on line-aligned parts; matches that span a part boundary may be missed.'] :=
    'Line-segmented mode is ON: Replace All runs on line-aligned parts; matches that span a part boundary may be missed.';
  GTextPortuguese.Values['Line-segmented mode is ON: Replace All runs on line-aligned parts; matches that span a part boundary may be missed.'] :=
    'Modo segmentado ATIVO: Substituir tudo corre em partes alinhadas a linhas; correspond'#234'ncias a atravessar um limite de parte podem ser ignoradas.';
  GTextSpanish.Values['Line-segmented mode is ON: Replace All runs on line-aligned parts; matches that span a part boundary may be missed.'] :=
    'Modo segmentado ACTIVO: Reemplazar todo se ejecuta en partes alineadas a l'#237'neas; las coincidencias que crucen un l'#237'mite pueden perderse.';
  GTextFrench.Values['Line-segmented mode is ON: Replace All runs on line-aligned parts; matches that span a part boundary may be missed.'] :=
    'Mode segment'#233' ACTIF: Remplacer tout par parties align'#233'es sur les lignes; les correspondances '#224' cheval sur une limite peuvent '#234'tre manqu'#233'es.';
  GTextGerman.Values['Line-segmented mode is ON: Replace All runs on line-aligned parts; matches that span a part boundary may be missed.'] :=
    'Zeilen-Segmentmodus AN: Ersetzen alle arbeitet in teilweise zeilenweise Teilen; Treffer '#252'ber Grenzen hinweg k'#246'nnen fehlen.';
  GTextItalian.Values['Line-segmented mode is ON: Replace All runs on line-aligned parts; matches that span a part boundary may be missed.'] :=
    'Modalit'#224' segmentata ATTIVA: Sostituisci tutto lavora su parti allineate alle righe; le corrispondenze sul confine possono mancare.';
  GTextPolish.Values['Line-segmented mode is ON: Replace All runs on line-aligned parts; matches that span a part boundary may be missed.'] :=
    'Tryb segmentow WLACZONY: Zamien wszystko dziala na czesciach wg linii; dopasowania na granicy czesci moga zostac pominiete.';
  GTextPortuguesePT.Values['Line-segmented mode is ON: Replace All runs on line-aligned parts; matches that span a part boundary may be missed.'] :=
    'Modo segmentado ATIVO: Substituir tudo corre em partes alinhadas a linhas; correspond'#234'ncias a atravessar um limite de parte podem ser ignoradas.';
  GTextRomanian.Values['Line-segmented mode is ON: Replace All runs on line-aligned parts; matches that span a part boundary may be missed.'] :=
    'Mod segmentat ACTIV: Inlocuieste tot ruleaza pe parti aliniate pe linii; potrivirile la granita de parte pot fi ratate.';
  GTextHungarian.Values['Line-segmented mode is ON: Replace All runs on line-aligned parts; matches that span a part boundary may be missed.'] :=
    'Szegmentalt mod BE: Osszes cseréje soronkent igazitott reszeken fut; a hataron atnyulo egyezesek kimaradhatnak.';
  GTextCzech.Values['Line-segmented mode is ON: Replace All runs on line-aligned parts; matches that span a part boundary may be missed.'] :=
    'Segmentovany rezim ZAPNUTY: Nahradit vse bezi po castech podle radku; shody na hranici casti mohou chybet.';

  GTextEnglish.Values['Segment'] := 'Segment';
  GTextPortuguese.Values['Segment'] := 'Segmento';
  GTextSpanish.Values['Segment'] := 'Segmento';
  GTextFrench.Values['Segment'] := 'Segment';
  GTextGerman.Values['Segment'] := 'Segment';
  GTextItalian.Values['Segment'] := 'Segmento';
  GTextPolish.Values['Segment'] := 'Segment';
  GTextPortuguesePT.Values['Segment'] := 'Segmento';
  GTextRomanian.Values['Segment'] := 'Segment';
  GTextHungarian.Values['Segment'] := 'Szegmens';
  GTextCzech.Values['Segment'] := 'Segment';

  GTextEnglish.Values['Segmented replace: invalid line index in temp.txt.'] :=
    'Segmented replace: invalid line index in temp.txt.';
  GTextPortuguese.Values['Segmented replace: invalid line index in temp.txt.'] :=
    'Substitui'#231#227'o segmentada: '#237'ndice de linha inv'#225'lido em temp.txt.';
  GTextSpanish.Values['Segmented replace: invalid line index in temp.txt.'] :=
    'Reemplazo segmentado: '#237'ndice de l'#237'nea inv'#225'lido en temp.txt.';
  GTextFrench.Values['Segmented replace: invalid line index in temp.txt.'] :=
    'Remplacement segment'#233': index de ligne invalide dans temp.txt.';
  GTextGerman.Values['Segmented replace: invalid line index in temp.txt.'] :=
    'Segmentiertes Ersetzen: ung'#252'ltiger Zeilenindex in temp.txt.';
  GTextItalian.Values['Segmented replace: invalid line index in temp.txt.'] :=
    'Sostituzione segmentata: indice di riga non valido in temp.txt.';
  GTextPolish.Values['Segmented replace: invalid line index in temp.txt.'] :=
    'Zamiana segmentowa: nieprawidlowy indeks linii w temp.txt.';
  GTextPortuguesePT.Values['Segmented replace: invalid line index in temp.txt.'] :=
    'Substitui'#231#227'o segmentada: '#237'ndice de linha inv'#225'lido em temp.txt.';
  GTextRomanian.Values['Segmented replace: invalid line index in temp.txt.'] :=
    'Inlocuire segmentata: index de linie invalid in temp.txt.';
  GTextHungarian.Values['Segmented replace: invalid line index in temp.txt.'] :=
    'Szegmentalt csere: '#233'rv'#233'nytelen sorindex a temp.txt-ben.';
  GTextCzech.Values['Segmented replace: invalid line index in temp.txt.'] :=
    'Segmentovane nahrazovani: neplatny index radku v temp.txt.';

  GTextEnglish.Values['Continue?'] := 'Continue?';
  GTextPortuguese.Values['Continue?'] := 'Continuar?';
  GTextSpanish.Values['Continue?'] := 'Continuar?';
  GTextFrench.Values['Continue?'] := 'Continuer ?';
  GTextGerman.Values['Continue?'] := 'Fortfahren?';
  GTextItalian.Values['Continue?'] := 'Continuare?';
  GTextPolish.Values['Continue?'] := 'Kontynuowac?';
  GTextPortuguesePT.Values['Continue?'] := 'Continuar?';
  GTextRomanian.Values['Continue?'] := 'Continuati?';
  GTextHungarian.Values['Continue?'] := 'Folytatja?';
  GTextCzech.Values['Continue?'] := 'Pokracovat?';

  GTextEnglish.Values['Replacing (streaming to temp file)...'] := 'Replacing (streaming to temp file)...';
  GTextPortuguese.Values['Replacing (streaming to temp file)...'] := 'A substituir (streaming para ficheiro temporario)...';
  GTextSpanish.Values['Replacing (streaming to temp file)...'] := 'Reemplazando (streaming a archivo temporal)...';
  GTextFrench.Values['Replacing (streaming to temp file)...'] := 'Remplacement (flux vers fichier temporaire)...';
  GTextGerman.Values['Replacing (streaming to temp file)...'] := 'Ersetze (Streaming in Temp-Datei)...';
  GTextItalian.Values['Replacing (streaming to temp file)...'] := 'Sostituzione (streaming su file temporaneo)...';
  GTextPolish.Values['Replacing (streaming to temp file)...'] := 'Zamienianie (strumieniowo do pliku tymczasowego)...';
  GTextPortuguesePT.Values['Replacing (streaming to temp file)...'] := 'A substituir (streaming para ficheiro temporario)...';
  GTextRomanian.Values['Replacing (streaming to temp file)...'] := 'Inlocuire (streaming in fisier temporar)...';
  GTextHungarian.Values['Replacing (streaming to temp file)...'] := 'Csere (streamelt ideiglenes faj)...';
  GTextCzech.Values['Replacing (streaming to temp file)...'] := 'Nahrazovani (stream do docasneho souboru)...';

  GTextEnglish.Values['[Save note] DEFAULT follows detection; a forced view only changes list decoding until an operation rewrites the file on disk.'] :=
    '[Save note] DEFAULT follows detection; a forced view only changes list decoding until an operation rewrites the file on disk.';
  GTextPortuguese.Values['[Save note] DEFAULT follows detection; a forced view only changes list decoding until an operation rewrites the file on disk.'] :=
    '[Nota] DEFAULT segue a deteccao; uma vista forcada so altera a descodificacao na lista ate uma operacao regravar o ficheiro em disco.';
  GTextSpanish.Values['[Save note] DEFAULT follows detection; a forced view only changes list decoding until an operation rewrites the file on disk.'] :=
    '[Nota] DEFAULT sigue la deteccion; una vista forzada solo cambia la decodificacion en la lista hasta que una operacion reescriba el archivo.';
  GTextFrench.Values['[Save note] DEFAULT follows detection; a forced view only changes list decoding until an operation rewrites the file on disk.'] :=
    '[Note] DEFAULT suit la detection; une vue forcee ne change que le decodage de la liste tant qu''une operation ne reecrit pas le fichier.';
  GTextGerman.Values['[Save note] DEFAULT follows detection; a forced view only changes list decoding until an operation rewrites the file on disk.'] :=
    '[Hinweis] DEFAULT folgt der Erkennung; erzwungene Ansicht andert nur die Listendekodierung, bis eine Operation die Datei neu schreibt.';
  GTextItalian.Values['[Save note] DEFAULT follows detection; a forced view only changes list decoding until an operation rewrites the file on disk.'] :=
    '[Nota] DEFAULT segue il rilevamento; la vista forzata cambia solo la decodifica in lista finche un operazione non riscrive il file.';
  GTextPolish.Values['[Save note] DEFAULT follows detection; a forced view only changes list decoding until an operation rewrites the file on disk.'] :=
    '[Uwaga] DEFAULT = detekcja; wymuszony widok zmienia tylko dekodowanie na liscie, dopoki operacja nie zapisze pliku.';
  GTextPortuguesePT.Values['[Save note] DEFAULT follows detection; a forced view only changes list decoding until an operation rewrites the file on disk.'] :=
    '[Nota] DEFAULT segue a deteccao; uma vista forcada so altera a descodificacao na lista ate uma operacao regravar o ficheiro em disco.';
  GTextRomanian.Values['[Save note] DEFAULT follows detection; a forced view only changes list decoding until an operation rewrites the file on disk.'] :=
    '[Nota] DEFAULT urmeaza detectia; fortat modifica doar decodarea in lista pana rescrie fisierul o operatie.';
  GTextHungarian.Values['[Save note] DEFAULT follows detection; a forced view only changes list decoding until an operation rewrites the file on disk.'] :=
    '[Megjegyzes] DEFAULT = felismeres; kenyszeritett nezet csak a lista dekodolasat valtoztatja, amig muvelet nem irja ujra a fajlt.';
  GTextCzech.Values['[Save note] DEFAULT follows detection; a forced view only changes list decoding until an operation rewrites the file on disk.'] :=
    '[Poznamka] DEFAULT = detekce; vynuceny pohled meni jen dekodovani seznamu, dokud operace znovu nezapise soubor.';

  GTextEnglish.Values['[Line preview limited to %s bytes for performance; file line total %s bytes.]'] :=
    '[Line preview limited to %s bytes for performance; file line total %s bytes.]';
  GTextPortuguese.Values['[Line preview limited to %s bytes for performance; file line total %s bytes.]'] :=
    '[Pre-visualizacao da linha limitada a %s bytes por desempenho; total da linha no ficheiro %s bytes.]';
  GTextSpanish.Values['[Line preview limited to %s bytes for performance; file line total %s bytes.]'] :=
    '[Vista previa de linea limitada a %s bytes por rendimiento; total de linea en archivo %s bytes.]';
  GTextFrench.Values['[Line preview limited to %s bytes for performance; file line total %s bytes.]'] :=
    '[Apercu de ligne limite a %s octets pour les performances ; total de ligne %s octets.]';
  GTextGerman.Values['[Line preview limited to %s bytes for performance; file line total %s bytes.]'] :=
    '[Zeilenvorschau auf %s Bytes begrenzt (Leistung); Zeilengesamt %s Bytes.]';
  GTextItalian.Values['[Line preview limited to %s bytes for performance; file line total %s bytes.]'] :=
    '[Anteprima riga limitata a %s byte per prestazioni; totale riga nel file %s byte.]';
  GTextPolish.Values['[Line preview limited to %s bytes for performance; file line total %s bytes.]'] :=
    '[Podglad linii ograniczony do %s bajtow (wydajnosc); calkowita dlugosc linii w pliku %s bajtow.]';
  GTextPortuguesePT.Values['[Line preview limited to %s bytes for performance; file line total %s bytes.]'] :=
    '[Pre-visualizacao da linha limitada a %s bytes por desempenho; total da linha no ficheiro %s bytes.]';
  GTextRomanian.Values['[Line preview limited to %s bytes for performance; file line total %s bytes.]'] :=
    '[Previzualizare linie limitata la %s octeti (performanta); total linie in fisier %s octeti.]';
  GTextHungarian.Values['[Line preview limited to %s bytes for performance; file line total %s bytes.]'] :=
    '[Sor elotetekorlat %s bait (teljesitmeny); sor osszesen a fajlban %s bait.]';
  GTextCzech.Values['[Line preview limited to %s bytes for performance; file line total %s bytes.]'] :=
    '[Nahled radku omezen na %s bajtu (vykon); celkova delka radku v souboru %s bajtu.]';

  { --- Help memo lines + filter status (11 languages) ---------------------- }
  GTextEnglish.Values['  Ctrl+Shift+G .... Go to byte offset (1-based file position; $ = hex)'] :=
    '  Ctrl+Shift+G .... Go to byte offset (1-based file position; $ = hex)';
  GTextPortuguese.Values['  Ctrl+Shift+G .... Go to byte offset (1-based file position; $ = hex)'] :=
    '  Ctrl+Shift+G .... Ir para offset em bytes (posicao 1-based no arquivo; $ = hex)';
  GTextSpanish.Values['  Ctrl+Shift+G .... Go to byte offset (1-based file position; $ = hex)'] :=
    '  Ctrl+Shift+G .... Ir a offset en bytes (posicion 1-based; $ = hex)';
  GTextFrench.Values['  Ctrl+Shift+G .... Go to byte offset (1-based file position; $ = hex)'] :=
    '  Ctrl+Shift+G .... Aller au d'#233'calage en octets (position 1-based ; $ = hex)';
  GTextGerman.Values['  Ctrl+Shift+G .... Go to byte offset (1-based file position; $ = hex)'] :=
    '  Ctrl+Shift+G .... Gehe zu Byte-Offset (1-basiert; $ = Hex)';
  GTextItalian.Values['  Ctrl+Shift+G .... Go to byte offset (1-based file position; $ = hex)'] :=
    '  Ctrl+Shift+G .... Vai all''offset in byte (base 1; $ = hex)';
  GTextPolish.Values['  Ctrl+Shift+G .... Go to byte offset (1-based file position; $ = hex)'] :=
    '  Ctrl+Shift+G .... Przejdz do offsetu w bajtach (baza 1; $ = hex)';
  GTextPortuguesePT.Values['  Ctrl+Shift+G .... Go to byte offset (1-based file position; $ = hex)'] :=
    '  Ctrl+Shift+G .... Ir para offset em bytes (posicao 1-based no ficheiro; $ = hex)';
  GTextRomanian.Values['  Ctrl+Shift+G .... Go to byte offset (1-based file position; $ = hex)'] :=
    '  Ctrl+Shift+G .... Mergi la offset octeti (pozitie 1-based; $ = hex)';
  GTextHungarian.Values['  Ctrl+Shift+G .... Go to byte offset (1-based file position; $ = hex)'] :=
    '  Ctrl+Shift+G .... Ugras bait offsetre (1-alapu; $ = hex)';
  GTextCzech.Values['  Ctrl+Shift+G .... Go to byte offset (1-based file position; $ = hex)'] :=
    '  Ctrl+Shift+G .... Prejit na offset v bajtech (zaklad 1; $ = hex)';

  GTextEnglish.Values['  Filter (Ctrl+L) .... View over index; Yes=prefix / No=contains / OK=VBScript regex'] :=
    '  Filter (Ctrl+L) .... View over index; Yes=prefix / No=contains / OK=VBScript regex';
  GTextPortuguese.Values['  Filter (Ctrl+L) .... View over index; Yes=prefix / No=contains / OK=VBScript regex'] :=
    '  Filtro (Ctrl+L) .... Vista sobre o indice; Sim=prefixo / Nao=contem / OK=regex VBScript';
  GTextSpanish.Values['  Filter (Ctrl+L) .... View over index; Yes=prefix / No=contains / OK=VBScript regex'] :=
    '  Filtro (Ctrl+L) .... Vista sobre el indice; Si=prefijo / No=contiene / OK=regex VBScript';
  GTextFrench.Values['  Filter (Ctrl+L) .... View over index; Yes=prefix / No=contains / OK=VBScript regex'] :=
    '  Filtre (Ctrl+L) .... Vue sur l''index ; Oui=pr'#233'fixe / Non=contient / OK=regex VBScript';
  GTextGerman.Values['  Filter (Ctrl+L) .... View over index; Yes=prefix / No=contains / OK=VBScript regex'] :=
    '  Filter (Ctrl+L) .... Ansicht '#252'ber Index; Ja=Pr'#228'fix / Nein=enth'#228'lt / OK=VBScript-Regex';
  GTextItalian.Values['  Filter (Ctrl+L) .... View over index; Yes=prefix / No=contains / OK=VBScript regex'] :=
    '  Filtro (Ctrl+L) .... Vista sull''indice; Si=prefisso / No=contiene / OK=regex VBScript';
  GTextPolish.Values['  Filter (Ctrl+L) .... View over index; Yes=prefix / No=contains / OK=VBScript regex'] :=
    '  Filtr (Ctrl+L) .... Widok na indeks; Tak=prefiks / Nie=zawiera / OK=regex VBScript';
  GTextPortuguesePT.Values['  Filter (Ctrl+L) .... View over index; Yes=prefix / No=contains / OK=VBScript regex'] :=
    '  Filtro (Ctrl+L) .... Vista sobre o indice; Sim=prefixo / Nao=contem / OK=regex VBScript';
  GTextRomanian.Values['  Filter (Ctrl+L) .... View over index; Yes=prefix / No=contains / OK=VBScript regex'] :=
    '  Filtru (Ctrl+L) .... Vedere peste index; Da=prefix / Nu=contine / OK=regex VBScript';
  GTextHungarian.Values['  Filter (Ctrl+L) .... View over index; Yes=prefix / No=contains / OK=VBScript regex'] :=
    '  Szuro (Ctrl+L) .... Nezet az indexre; Igen=eleje / Nem=tartalmazza / OK=VBScript regex';
  GTextCzech.Values['  Filter (Ctrl+L) .... View over index; Yes=prefix / No=contains / OK=VBScript regex'] :=
    '  Filtr (Ctrl+L) .... Pohled pres index; Ano=prefix / Ne=obsahuje / OK=regex VBScript';

  GTextEnglish.Values['  Filter is view-only (no disk rewrite). Regex uses Windows VBScript.RegExp on each line preview.'] :=
    '  Filter is view-only (no disk rewrite). Regex uses Windows VBScript.RegExp on each line preview.';
  GTextPortuguese.Values['  Filter is view-only (no disk rewrite). Regex uses Windows VBScript.RegExp on each line preview.'] :=
    '  Filtro e so visualizacao (sem regravar disco). Regex usa VBScript.RegExp do Windows em cada pre-visualizacao de linha.';
  GTextSpanish.Values['  Filter is view-only (no disk rewrite). Regex uses Windows VBScript.RegExp on each line preview.'] :=
    '  El filtro es solo vista (sin reescribir disco). Regex usa VBScript.RegExp de Windows en cada vista previa de linea.';
  GTextFrench.Values['  Filter is view-only (no disk rewrite). Regex uses Windows VBScript.RegExp on each line preview.'] :=
    '  Filtre en lecture seule (pas de reecriture disque). Regex = VBScript.RegExp Windows sur chaque apercu de ligne.';
  GTextGerman.Values['  Filter is view-only (no disk rewrite). Regex uses Windows VBScript.RegExp on each line preview.'] :=
    '  Filter nur Ansicht (keine Platten-Umschreibung). Regex nutzt Windows VBScript.RegExp pro Zeilenvorschau.';
  GTextItalian.Values['  Filter is view-only (no disk rewrite). Regex uses Windows VBScript.RegExp on each line preview.'] :=
    '  Filtro solo vista (nessuna riscrittura su disco). Regex: VBScript.RegExp di Windows su ogni anteprima riga.';
  GTextPolish.Values['  Filter is view-only (no disk rewrite). Regex uses Windows VBScript.RegExp on each line preview.'] :=
    '  Filtr tylko podglad (bez zapisu dysku). Regex: Windows VBScript.RegExp na podgladzie kazdej linii.';
  GTextPortuguesePT.Values['  Filter is view-only (no disk rewrite). Regex uses Windows VBScript.RegExp on each line preview.'] :=
    '  Filtro e so visualizacao (sem regravar disco). Regex usa VBScript.RegExp do Windows em cada pre-visualizacao de linha.';
  GTextRomanian.Values['  Filter is view-only (no disk rewrite). Regex uses Windows VBScript.RegExp on each line preview.'] :=
    '  Filtru doar vizual (fara rescriere disc). Regex foloseste VBScript.RegExp Windows pe fiecare previzualizare.';
  GTextHungarian.Values['  Filter is view-only (no disk rewrite). Regex uses Windows VBScript.RegExp on each line preview.'] :=
    '  Szuro csak nezet (nincs lemeziras). Regex: Windows VBScript.RegExp minden sor eloteten.';
  GTextCzech.Values['  Filter is view-only (no disk rewrite). Regex uses Windows VBScript.RegExp on each line preview.'] :=
    '  Filtr jen pohled (bez prepisu disku). Regex pouziva Windows VBScript.RegExp u nahledu kazdeho radku.';

  GTextEnglish.Values['  Line-prefix step: Yes = line starts with text; No = contains anywhere (view only, no file rewrite).'] :=
    '  Line-prefix step: Yes = line starts with text; No = contains anywhere (view only, no file rewrite).';
  GTextPortuguese.Values['  Line-prefix step: Yes = line starts with text; No = contains anywhere (view only, no file rewrite).'] :=
    '  Passo do prefixo: Sim = linha comeca com o texto; Nao = contem em qualquer lugar (so visualizacao, sem regravar).';
  GTextSpanish.Values['  Line-prefix step: Yes = line starts with text; No = contains anywhere (view only, no file rewrite).'] :=
    '  Paso de prefijo: Si = la linea empieza con el texto; No = contiene en cualquier sitio (solo vista, sin reescribir).';
  GTextFrench.Values['  Line-prefix step: Yes = line starts with text; No = contains anywhere (view only, no file rewrite).'] :=
    '  '#201'tape pr'#233'fixe : Oui = la ligne commence par le texte ; Non = contient n''importe o'#249' (vue seule, pas de r'#233#233'criture).';
  GTextGerman.Values['  Line-prefix step: Yes = line starts with text; No = contains anywhere (view only, no file rewrite).'] :=
    '  Pr'#228'fix-Schritt: Ja = Zeile beginnt mit Text; Nein = enth'#228'lt irgendwo (nur Ansicht, keine Datei-Umschreibung).';
  GTextItalian.Values['  Line-prefix step: Yes = line starts with text; No = contains anywhere (view only, no file rewrite).'] :=
    '  Passo prefisso: Si = la riga inizia con il testo; No = contiene ovunque (solo vista, nessuna riscrittura).';
  GTextPolish.Values['  Line-prefix step: Yes = line starts with text; No = contains anywhere (view only, no file rewrite).'] :=
    '  Krok prefiksu: Tak = linia zaczyna sie od tekstu; Nie = zawiera gdziekolwiek (tylko widok, bez zapisu).';
  GTextPortuguesePT.Values['  Line-prefix step: Yes = line starts with text; No = contains anywhere (view only, no file rewrite).'] :=
    '  Passo do prefixo: Sim = linha comeca com o texto; Nao = contem em qualquer lugar (so visualizacao, sem regravar).';
  GTextRomanian.Values['  Line-prefix step: Yes = line starts with text; No = contains anywhere (view only, no file rewrite).'] :=
    '  Pas prefix: Da = linia incepe cu textul; Nu = contine oriunde (doar vizualizare, fara rescriere).';
  GTextHungarian.Values['  Line-prefix step: Yes = line starts with text; No = contains anywhere (view only, no file rewrite).'] :=
    '  Elotag-lepes: Igen = a sor a szoveggel kezdodik; Nem = barmhol tartalmazza (csak nezet, nincs ujrairas).';
  GTextCzech.Values['  Line-prefix step: Yes = line starts with text; No = contains anywhere (view only, no file rewrite).'] :=
    '  Krok prefixu: Ano = radek zacina textem; Ne = obsahuje kdekoli (pouze nahled, bez prepisu souboru).';

  GTextEnglish.Values['Filter cleared.'] := 'Filter cleared.';
  GTextPortuguese.Values['Filter cleared.'] := 'Filtro limpo.';
  GTextSpanish.Values['Filter cleared.'] := 'Filtro borrado.';
  GTextFrench.Values['Filter cleared.'] := 'Filtre effac'#233'.';
  GTextGerman.Values['Filter cleared.'] := 'Filter aufgehoben.';
  GTextItalian.Values['Filter cleared.'] := 'Filtro cancellato.';
  GTextPolish.Values['Filter cleared.'] := 'Filtr wyczyszczony.';
  GTextPortuguesePT.Values['Filter cleared.'] := 'Filtro limpo.';
  GTextRomanian.Values['Filter cleared.'] := 'Filtru sters.';
  GTextHungarian.Values['Filter cleared.'] := 'Szuro torolve.';
  GTextCzech.Values['Filter cleared.'] := 'Filtr zrusen.';

  GTextEnglish.Values['Filtering...'] := 'Filtering...';
  GTextPortuguese.Values['Filtering...'] := 'Filtrando...';
  GTextSpanish.Values['Filtering...'] := 'Filtrando...';
  GTextFrench.Values['Filtering...'] := 'Filtrage...';
  GTextGerman.Values['Filtering...'] := 'Filter wird angewendet...';
  GTextItalian.Values['Filtering...'] := 'Filtraggio...';
  GTextPolish.Values['Filtering...'] := 'Filtrowanie...';
  GTextPortuguesePT.Values['Filtering...'] := 'A filtrar...';
  GTextRomanian.Values['Filtering...'] := 'Filtrare...';
  GTextHungarian.Values['Filtering...'] := 'Szures...';
  GTextCzech.Values['Filtering...'] := 'Filtrovani...';

  GTextEnglish.Values['Filter: %d/%d'] := 'Filter: %d/%d';
  GTextPortuguese.Values['Filter: %d/%d'] := 'Filtro: %d/%d';
  GTextSpanish.Values['Filter: %d/%d'] := 'Filtro: %d/%d';
  GTextFrench.Values['Filter: %d/%d'] := 'Filtre : %d/%d';
  GTextGerman.Values['Filter: %d/%d'] := 'Filter: %d/%d';
  GTextItalian.Values['Filter: %d/%d'] := 'Filtro: %d/%d';
  GTextPolish.Values['Filter: %d/%d'] := 'Filtr: %d/%d';
  GTextPortuguesePT.Values['Filter: %d/%d'] := 'Filtro: %d/%d';
  GTextRomanian.Values['Filter: %d/%d'] := 'Filtru: %d/%d';
  GTextHungarian.Values['Filter: %d/%d'] := 'Szuro: %d/%d';
  GTextCzech.Values['Filter: %d/%d'] := 'Filtr: %d/%d';

  GTextEnglish.Values['Ready'] := 'Ready';
  GTextPortuguese.Values['Ready'] := 'Pronto';
  GTextSpanish.Values['Ready'] := 'Listo';
  GTextFrench.Values['Ready'] := 'Pr'#234't';
  GTextGerman.Values['Ready'] := 'Bereit';
  GTextItalian.Values['Ready'] := 'Pronto';
  GTextPolish.Values['Ready'] := 'Gotowy';
  GTextPortuguesePT.Values['Ready'] := 'Pronto';
  GTextRomanian.Values['Ready'] := 'Gata';
  GTextHungarian.Values['Ready'] := 'Keszen';
  GTextCzech.Values['Ready'] := 'Pripraveno';

  GTextEnglish.Values['This line is not in the current filter results.'] :=
    'This line is not in the current filter results.';
  GTextPortuguese.Values['This line is not in the current filter results.'] :=
    'Essa linha nao esta entre os resultados do filtro atual.';
  GTextSpanish.Values['This line is not in the current filter results.'] :=
    'Esta linea no esta entre los resultados del filtro actual.';
  GTextFrench.Values['This line is not in the current filter results.'] :=
    'Cette ligne ne figure pas parmi les r'#233'sultats du filtre actuel.';
  GTextGerman.Values['This line is not in the current filter results.'] :=
    'Diese Zeile ist nicht in den aktuellen Filterergebnissen.';
  GTextItalian.Values['This line is not in the current filter results.'] :=
    'Questa riga non '#232' tra i risultati del filtro corrente.';
  GTextPolish.Values['This line is not in the current filter results.'] :=
    'Ta linia nie znajduje sie w biezacych wynikach filtra.';
  GTextPortuguesePT.Values['This line is not in the current filter results.'] :=
    'Essa linha nao esta entre os resultados do filtro actual.';
  GTextRomanian.Values['This line is not in the current filter results.'] :=
    'Aceasta linie nu se afla printre rezultatele filtrului curent.';
  GTextHungarian.Values['This line is not in the current filter results.'] :=
    'Ez a sor nincs benne a jelenlegi szuro eredmenyeiben.';
  GTextCzech.Values['This line is not in the current filter results.'] :=
    'Tento radek neni mezi vysledky aktualniho filtru.';
end;

procedure AddCommonTranslationsCompareMerge;

  procedure Set11(const K: string;
    const EN, PT, ES, FR, DE, IT, PL, PTPT, RO, HU, CZ: string);
  begin
    GTextEnglish.Values[K] := EN;
    GTextPortuguese.Values[K] := PT;
    GTextSpanish.Values[K] := ES;
    GTextFrench.Values[K] := FR;
    GTextGerman.Values[K] := DE;
    GTextItalian.Values[K] := IT;
    GTextPolish.Values[K] := PL;
    GTextPortuguesePT.Values[K] := PTPT;
    GTextRomanian.Values[K] := RO;
    GTextHungarian.Values[K] := HU;
    GTextCzech.Values[K] := CZ;
  end;

begin
  Set11('Please select both Left and Right files.',
    'Please select both Left and Right files.',
    'Por favor selecione ambos os arquivos Esquerdo e Direito.',
    'Por favor seleccione ambos archivos Izquierdo y Derecho.',
    'Veuillez selectionner les fichiers Gauche et Droit.',
    'Bitte wahlen Sie sowohl die linke als auch die rechte Datei.',
    'Si prega di selezionare sia il file Sinistro che Destro.',
    'Wybierz zarowno plik lewy, jak i prawy.',
    'Por favor seleccione ambos os ficheiros Esquerdo e Direito.',
    'Va rugam sa selectati atat fisierul Stang cat si cel Drept.',
    'Kerjuk, valassza ki a bal es jobb fajlokat is.',
    'Vyberte prosim levy i pravy soubor.');

  Set11('There is no difference between the files.',
    'There is no difference between the files.',
    'N'#227'o h'#225' diferen'#231'a entre os arquivos.',
    'No hay diferencia entre los archivos.',
    'Il n''y a pas de diff'#233'rence entre les fichiers.',
    'Es gibt keinen Unterschied zwischen den Dateien.',
    'Non c'#232' differenza tra i file.',
    'Nie ma r'#243#191'nicy mi'#281'dzy plikami.',
    'N'#227'o h'#225' diferen'#231'a entre os ficheiros.',
    'Nu exist'#227' nicio diferen'#254#227' '#238'ntre fi'#186'iere.',
    'Nincs k'#252'l'#246'nb'#233'g a f'#225'jlok k'#246'z'#246'tt.',
    'Mezi soubory nen'#237' '#382#225'dn'#253' rozd'#237'l.');

  Set11('equal', 'equal', 'igual', 'igual', 'egal', 'gleich', 'uguale', 'rowny', 'igual', 'egal', 'egyenlo', 'stejny');
  Set11('change', 'change', 'alterado', 'cambio', 'modifie', 'geandert', 'modificato', 'zmieniony', 'alterado', 'modificat', 'valtozott', 'zmeneny');
  Set11('delete', 'delete', 'removido', 'eliminado', 'supprime', 'geloscht', 'eliminato', 'usuniety', 'removido', 'sters', 'torolt', 'odstraneny');
  Set11('insert', 'insert', 'inserido', 'insertado', 'insere', 'eingefugt', 'inserito', 'wstawiony', 'inserido', 'inserat', 'beszurt', 'vlozeny');

  Set11('Compare / merge + session history',
    'Compare / merge + session history',
    'Comparar / mesclar + hist'#243'rico da sess'#227'o',
    'Comparar / combinar + historial de sesi'#243'n',
    'Comparer / fusionner + historique de session',
    'Vergleichen / Zusammenfuehren + Sitzungsverlauf',
    'Confronta / unisci + cronologia sessione',
    'Porownaj / scal + historia sesji',
    'Comparar / mesclar + hist'#243'rico da sess'#227'o',
    'Compara / imbinare + istoric sesiune',
    'Osszehasonlitas / osszevonas + munkamenet naplo',
    'Porovnat / slouceni + historie relace');

  Set11('Session history',
    'Session history',
    'Hist'#243'rico de edi'#231#227'o (sess'#227'o)',
    'Historial de edici'#243'n (sesi'#243'n)',
    'Historique d''edition (session)',
    'Sitzungsverlauf (Bearbeitung)',
    'Cronologia modifica (sessione)',
    'Historia sesji (edycja)',
    'Hist'#243'rico de edi'#231#227'o (sess'#227'o)',
    'Istoric sesiune (editare)',
    'Munkamenet elozmenyek (szerkesztes)',
    'Historie relace (upravy)');

  Set11('Two-file diff',
    'Two-file diff',
    'Diff entre dois arquivos',
    'Diff entre dos archivos',
    'Diff entre deux fichiers',
    'Zwei-Datei-Diff',
    'Diff tra due file',
    'Porownanie dwoch plikow',
    'Diff entre dois ficheiros',
    'Diff intre doua fisiere',
    'Ket fajl diff-je',
    'Rozdil dvou souboru');

  Set11('History log path:',
    'History log path:',
    'Caminho do hist'#243'rico:',
    'Ruta del historial:',
    'Chemin du journal :',
    'Protokollpfad:',
    'Percorso registro:',
    'Sciezka dziennika:',
    'Caminho do hist'#243'rico:',
    'Cale jurnal:',
    'Naplo utvonal:',
    'Cesta k protokolu:');

  Set11('Reloading session history...',
    'Reloading session history...',
    'A recarregar hist'#243'rico da sess'#227'o...',
    'Recargando historial de sesion...',
    'Rechargement de l''historique de session...',
    'Sitzungsverlauf wird neu geladen...',
    'Ricaricamento cronologia sessione...',
    'Ponowne wczytywanie historii sesji...',
    'A recarregar hist'#243'rico da sess'#227'o...',
    'Se reincarca istoricul sesiunii...',
    'Munkamenet elozmenyek ujratoltese...',
    'Obnovuji historii relace...');

  Set11('Reload',
    'Reload',
    'Recarregar',
    'Volver a cargar',
    'Recharger',
    'Neu laden',
    'Ricarica',
    'Przeladuj',
    'Recarregar',
    'Reincarcare',
    'Ujratoltes',
    'Znovu nacist');

  Set11('Journal entries: click to jump to the line in the preview below. Lines starting with # are hidden. Up to %d recent log lines are loaded.',
    'Journal entries: click to jump to the line in the preview below. Lines starting with # are hidden. Up to %d recent log lines are loaded.',
    'Entradas do di'#225'rio: clique para ir '#224' linha correspondente na pr'#233'-visualiza'#231#227'o abaixo. Linhas que come'#231'am com # ficam ocultas. Carrega-se no m'#225'ximo %d linhas recentes do registo.',
    'Entradas del diario: pulse para ir a la l'#237'nea en la vista previa inferior. Las l'#237'neas que empiezan por # se ocultan. Se cargan como m'#225'ximo %d l'#237'neas recientes del registro.',
    'Entr'#233'es du journal : cliquez pour aller '#224' la ligne correspondante dans l''aper'#231'u ci-dessous. Les lignes commen'#231'ant par # sont masqu'#233'es. %d lignes r'#233'centes maximum.',
    'Journalzeilen: Klick springt zur Zeile in der Vorschau unten. Zeilen mit # werden ausgeblendet. Maximal %d letzte Logzeilen.',
    'Voci di registro: clic per saltare alla riga nell''anteprima sotto. Le righe che iniziano con # sono nascoste. Al massimo %d righe recenti.',
    'Wpisy dziennika: kliknij, aby przejsc do wiersza w podgladzie. Linie z # sa ukryte. Ladowane sa max. %d ostatnich linii.',
    'Entradas do di'#225'rio: clique para ir '#224' linha correspondente na pr'#233'-visualiza'#231#227'o abaixo. As linhas que come'#231'am com # ficam ocultas. Carregam-se no m'#225'ximo %d linhas recentes do registo.',
    'Intrari in jurnal: clic pentru linia din previzualizare. Liniile care incep cu # sunt ascunse. Maxim %d linii recente.',
    'Naplo sorok: kattintas ugras az elonezet sorara. A # kezdetu sorok rejtve. Legfeljebb %d utolso naplosor.',
    'Zaznamy deniku: kliknete pro skok na radek v nahledu dole. Radky zacinajici # jsou skryte. Nacte se nejvyse %d poslednich radku.');

  Set11('Copy preview line (number and text)',
    'Copy preview line (number and text)',
    'Copiar linha da pr'#233'-visualiza'#231#227'o (n'#250'mero e texto)',
    'Copiar l'#237'nea de vista previa (n'#250'mero y texto)',
    'Copier la ligne d''aper'#231'u (num'#233'ro et texte)',
    'Vorschauzeile kopieren (Nummer und Text)',
    'Copia riga anteprima (numero e testo)',
    'Kopiuj wiersz z podgladu (numer i tekst)',
    'Copiar linha da pr'#233'-visualiza'#231#227'o (n'#250'mero e texto)',
    'Copiaza linia din previzualizare (numar si text)',
    'Elonezeti sor masolasa (szam es szoveg)',
    'Kopirovat radek nahledu (cislo a text)');

  Set11('Copy preview text only',
    'Copy preview text only',
    'Copiar apenas o texto da pr'#233'-visualiza'#231#227'o',
    'Copiar solo el texto de la vista previa',
    'Copier uniquement le texte de l''aper'#231'u',
    'Nur Vorschautext kopieren',
    'Copia solo il testo dell''anteprima',
    'Kopiuj tylko tekst z podgladu',
    'Copiar apenas o texto da pr'#233'-visualiza'#231#227'o',
    'Copiaza doar textul din previzualizare',
    'Csak az elonezeti szoveg masolasa',
    'Kop'#237'rovat jen text n'#225'hledu');

  Set11('No session history file yet. Edits will append here.',
    'No session history file yet. Edits will append here.',
    'Ainda n'#227'o existe arquivo de hist'#243'rico. As edi'#231#245'es ser'#227'o anexadas aqui.',
    'Aun no hay archivo de historial. Las ediciones se anexaran aqui.',
    'Pas encore de fichier journal. Les modifications seront ajoutees ici.',
    'Noch keine Sitzungsprotokolldatei. Aenderungen werden hier angehaengt.',
    'Nessun file di cronologia. Le modifiche saranno aggiunte qui.',
    'Nie ma jeszcze pliku historii sesji. Edycje beda dolaczane tutaj.',
    'Ainda n'#227'o existe ficheiro de hist'#243'rico. As edi'#231#245'es ser'#227'o anexadas aqui.',
    'Nu exista inca fisier de istoric. Editurile vor fi adaugate aici.',
    'Meg nincs munkamenet-naplo fajl. A szerkesztesek ide kerulnek.',
    'Soubor historie relace jeste neexistuje. Upravy se zde pridaji.');

  Set11('Left file',
    'Left file',
    'Arquivo esquerdo',
    'Archivo izquierdo',
    'Fichier gauche',
    'Linke Datei',
    'File sinistro',
    'Lewy plik',
    'Ficheiro esquerdo',
    'Fisier stanga',
    'Bal oldali fajl',
    'Levy soubor');

  Set11('Right file',
    'Right file',
    'Arquivo direito',
    'Archivo derecho',
    'Fichier droit',
    'Rechte Datei',
    'File destro',
    'Prawy plik',
    'Ficheiro direito',
    'Fisier dreapta',
    'Jobb oldali fajl',
    'Pravy soubor');

  Set11('First line',
    'First line',
    'Primeira linha',
    'Primera linea',
    'Premiere ligne',
    'Erste Zeile',
    'Prima riga',
    'Pierwsza linia',
    'Primeira linha',
    'Prima linie',
    'Elso sor',
    'Prvni radek');

  Set11('Last line',
    'Last line',
    'Ultima linha',
    'Ultima linea',
    'Derniere ligne',
    'Letzte Zeile',
    'Ultima riga',
    'Ostatnia linia',
    'Ultima linha',
    'Ultima linie',
    'Utolso sor',
    'Posledni radek');

  Set11('Build diff',
    'Build diff',
    'Gerar diff',
    'Generar diff',
    'Generer le diff',
    'Diff erstellen',
    'Crea diff',
    'Utworz roznice',
    'Gerar diff',
    'Genereaza diff',
    'Diff keszitese',
    'Sestavit diff');

  Set11('Diff by lines (range)',
    'Diff by lines (range)',
    'Diff por linhas (intervalo)',
    'Diff por lineas (rango)',
    'Diff par lignes (plage)',
    'Diff nach Zeilen (Bereich)',
    'Diff per righe (intervallo)',
    'Porownanie po liniach (zakres)',
    'Diff por linhas (intervalo)',
    'Diff pe linii (interval)',
    'Diff sorok szerint (tartomany)',
    'Diff po radcich (rozsah)');

  Set11('Copy selected left',
    'Copy selected left',
    'Copiar selecao (esquerda)',
    'Copiar seleccion (izquierda)',
    'Copier la selection (gauche)',
    'Auswahl kopieren (links)',
    'Copia selezione (sinistra)',
    'Kopiuj zaznaczenie (lewo)',
    'Copiar selecao (esquerda)',
    'Copiaza selectia (stanga)',
    'Kijeloles masolasa (bal)',
    'Kopirovat vyber (vlevo)');

  Set11('Copy selected right',
    'Copy selected right',
    'Copiar selecao (direita)',
    'Copiar seleccion (derecha)',
    'Copier la selection (droite)',
    'Auswahl kopieren (rechts)',
    'Copia selezione (destra)',
    'Kopiuj zaznaczenie (prawo)',
    'Copiar selecao (direita)',
    'Copiaza selectia (dreapta)',
    'Kijeloles masolasa (jobb)',
    'Kopirovat vyber (vpravo)');

  Set11('Sync scroll',
    'Sync scroll',
    'Sincronizar scroll',
    'Sincronizar desplazamiento',
    'Defilement synchronise',
    'Bildlauf synchronisieren',
    'Scorri sincronizzato',
    'Synchronizuj przewijanie',
    'Sincronizar scroll',
    'Derulare sincronizata',
    'Gorgetes szinkronban',
    'Synchronizovat posuv');

  Set11('Close',
    'Close',
    'Fechar',
    'Cerrar',
    'Fermer',
    'Schliessen',
    'Chiudi',
    'Zamknij',
    'Fechar',
    'Inchide',
    'Bezaras',
    'Zavrit');

  Set11('Please choose an existing left file.',
    'Please choose an existing left file.',
    'Escolha um arquivo esquerdo existente.',
    'Elija un archivo izquierdo existente.',
    'Choisissez un fichier gauche existant.',
    'Bitte waehlen Sie eine vorhandene linke Datei.',
    'Scegli un file sinistro esistente.',
    'Wybierz istniejacy lewy plik.',
    'Escolha um ficheiro esquerdo existente.',
    'Alegeti un fisier din stanga existent.',
    'Valasszon letezo bal oldali fajlt.',
    'Vyberte existujici levy soubor.');

  Set11('Please choose an existing right file.',
    'Please choose an existing right file.',
    'Escolha um arquivo direito existente.',
    'Elija un archivo derecho existente.',
    'Choisissez un fichier droit existant.',
    'Bitte waehlen Sie eine vorhandene rechte Datei.',
    'Scegli un file destro esistente.',
    'Wybierz istniejacy prawy plik.',
    'Escolha um ficheiro direito existente.',
    'Alegeti un fisier din dreapta existent.',
    'Valasszon letezo jobb oldali fajlt.',
    'Vyberte existujici pravy soubor.');

  Set11('First line must be >= 1.',
    'First line must be >= 1.',
    'A primeira linha deve ser >= 1.',
    'La primera linea debe ser >= 1.',
    'La premiere ligne doit etre >= 1.',
    'Die erste Zeile muss >= 1 sein.',
    'La prima riga deve essere >= 1.',
    'Pierwsza linia musi byc >= 1.',
    'A primeira linha deve ser >= 1.',
    'Prima linie trebuie sa fie >= 1.',
    'Az elso sor >= 1 legyen.',
    'Prvni radek musi byt >= 1.');

  Set11('Last line must be >= first line.',
    'Last line must be >= first line.',
    'A ultima linha deve ser >= a primeira.',
    'La ultima linea debe ser >= que la primera.',
    'La derniere ligne doit etre >= a la premiere.',
    'Die letzte Zeile muss >= erste Zeile sein.',
    'L''ultima riga deve essere >= alla prima.',
    'Ostatnia linia musi byc >= pierwszej.',
    'A ultima linha deve ser >= a primeira.',
    'Ultima linie trebuie sa fie >= prima linie.',
    'Az utolso sor >= az elso sornak kell lennie.',
    'Posledni radek musi byt >= prvniho.');

  Set11('Nothing selected.',
    'Nothing selected.',
    'Nada selecionado.',
    'Nada seleccionado.',
    'Aucune selection.',
    'Nichts ausgewaehlt.',
    'Nessuna selezione.',
    'Nic nie zaznaczono.',
    'Nada seleccionado.',
    'Nimic selectat.',
    'Nincs kijeloles.',
    'Nic neni vybrano.');

  Set11('Use Apply buttons to save merged lines to disk (batched). Green (equal) rows are ignored.',
    'Use Apply buttons to save merged lines to disk (batched). Green (equal) rows are ignored.',
    'Use os bot'#245'es Aplicar para gravar no disco (em lote). Linhas verdes (iguais) s'#227'o ignoradas.',
    'Use los botones Aplicar para guardar en disco (por lotes). Las filas verdes (iguales) se ignoran.',
    'Utilisez les boutons Appliquer pour enregistrer sur le disque (par lots). Les lignes vertes (identiques) sont ignorees.',
    'Verwenden Sie Anwenden, um zusammengefuehrte Zeilen stapelweise zu speichern. Gruene (gleiche) Zeilen werden ignoriert.',
    'Usa Applica per salvare le linee unite su disco (in blocco). Le righe verdi (uguali) sono ignorate.',
    'Uzyj przyciskow Zastosuj, by zapisac scalone linie na dysku (partiami). Zielone (identyczne) wiersze sa pomijane.',
    'Use os bot'#245'es Aplicar para gravar no disco (em lote). Linhas verdes (iguais) s'#227'o ignoradas.',
    'Folositi Aplica pentru a salva liniile imbinate pe disc (in loturi). Liniile verzi (egale) sunt ignorate.',
    'Az Alkalmaz gombokkal mentsen sorokat lemezre (kotegelve). A zold (azonos) sorok figyelmen kivul.',
    'Pouzijte Pouzit k ulozeni sloucenych radku na disk (davky). Zelene (shodne) radky se preskoci.');

  Set11('Building diff (bounded window)...',
    'Building diff (bounded window)...',
    'A gerar diff (janela limitada)...',
    'Generando diff (ventana limitada)...',
    'Generation du diff (fenetre limitee)...',
    'Diff wird erstellt (begrenztes Fenster)...',
    'Creazione diff (finestra limitata)...',
    'Tworzenie diff (okno ograniczone)...',
    'A gerar diff (janela limitada)...',
    'Se genereaza diff (fereastra limitata)...',
    'Diff keszitese (korlatozott ablak)...',
    'Vytvarensi diff (omezene okno)...');

  Set11('Compare / merge + &history...',
    'Compare / merge + &history...',
    'Comparar / mesclar + &hist'#243'rico...',
    'Comparar / combinar + &historial...',
    'Comparer / fusionner + &historique...',
    'Vergleichen / Zusammenfuehren + &Verlauf...',
    'Confronta / unisci + &cronologia...',
    'Porownaj / scal + &historia...',
    'Comparar / mesclar + &hist'#243'rico...',
    'Compara / imbinare + &istoric...',
    'Osszehasonlitas / osszevonas + &naplo...',
    'Porovnat / sloucit + &historii...');

  Set11('Browse...',
    'Browse...',
    'Procurar...',
    'Examinar...',
    'Parcourir...',
    'Durchsuchen...',
    'Sfoglia...',
    'Przegladaj...',
    'Procurar...',
    'Rasfoire...',
    'Tallozas...',
    'Prochazet...');

  Set11('Apply left to right (disk)',
    'Apply left to right (disk)',
    'Aplicar esquerda para a direita (disco)',
    'Aplicar izquierda a derecha (disco)',
    'Appliquer gauche vers la droite (disque)',
    'Links nach rechts anwenden (Festplatte)',
    'Applica da sinistra a destra (disco)',
    'Zastosuj z lewej do prawej (dysk)',
    'Aplicar da esquerda para a direita (disco)',
    'Aplica de la stanga la dreapta (disc)',
    'Balrol jobbra alkalmazas (lemez)',
    'Pouzit zleva doprava (disk)');

  Set11('Apply right to left (disk)',
    'Apply right to left (disk)',
    'Aplicar direita para a esquerda (disco)',
    'Aplicar derecha a izquierda (disco)',
    'Appliquer droite vers la gauche (disque)',
    'Rechts nach links anwenden (Festplatte)',
    'Applica da destra a sinistra (disco)',
    'Zastosuj z prawej do lewej (dysk)',
    'Aplicar da direita para a esquerda (disco)',
    'Aplica de la dreapta la stanga (disc)',
    'Jobbrol balra alkalmazas (lemez)',
    'Pouzit zprava doleva (disk)');

  Set11('Apply %d change(s) to the right file on disk?',
    'Apply %d change(s) to the right file on disk?',
    'Aplicar %d alteracao(oes) ao arquivo da direita no disco?',
    'Aplicar %d cambio(s) al archivo derecho en el disco?',
    'Appliquer %d modification(s) au fichier droit sur le disque ?',
    '%d Aenderung(en) in der rechten Datei auf der Festplatte anwenden?',
    'Applicare %d modifica/e al file destro su disco?',
    'Zastosowac %d zmian(y) do prawego pliku na dysku?',
    'Aplicar %d alteracao(oes) ao ficheiro da direita no disco?',
    'Aplicati %d modificari la fisierul din dreapta pe disc?',
    'Alkalmaz %d valtozast a jobb fajlon a lemezen?',
    'Pouzit %d zmen v pravem souboru na disku?');

  Set11('Apply %d change(s) to the left file on disk?',
    'Apply %d change(s) to the left file on disk?',
    'Aplicar %d alteracao(oes) ao arquivo da esquerda no disco?',
    'Aplicar %d cambio(s) al archivo izquierdo en el disco?',
    'Appliquer %d modification(s) au fichier gauche sur le disque ?',
    '%d Aenderung(en) in der linken Datei auf der Festplatte anwenden?',
    'Applicare %d modifica/e al file sinistro su disco?',
    'Zastosowac %d zmian(y) do lewego pliku na dysku?',
    'Aplicar %d alteracao(oes) ao ficheiro da esquerda no disco?',
    'Aplicati %d modificari la fisierul din stanga pe disc?',
    'Alkalmaz %d valtozast a bal fajlon a lemezen?',
    'Pouzit %d zmen v levem souboru na disku?');

  Set11('Confirm',
    'Confirm',
    'Confirmar',
    'Confirmar',
    'Confirmer',
    'Bestaetigen',
    'Conferma',
    'Potwierdz',
    'Confirmar',
    'Confirmati',
    'Megerosites',
    'Potvrdit');

  Set11('Clear history',
    'Clear history',
    'Limpar hist'#243'rico',
    'Borrar historial',
    'Effacer l''historique',
    'Verlauf l'#246'schen',
    'Cancella cronologia',
    'Wyczy'#347#263' histori'#281,
    'Limpar hist'#243'rico',
    'Sterge istoricul',
    'El'#245'zm'#233'nyek t'#246'rl'#233'se',
    'Vymazat historii');

  Set11('Are you sure you want to delete this session history log file and its directory?',
    'Are you sure you want to delete this session history log file and its directory?',
    'Tem certeza de que deseja excluir este arquivo de log do hist'#243'rico da sess'#227'o e sua pasta?',
    #191'Est'#225' seguro de que desea eliminar este archivo de registro del historial de la sesi'#243'n y su carpeta?',
    'Voulez-vous vraiment supprimer ce fichier journal d''historique de session et son r'#233'pertoire?',
    'M'#246'chten Sie diese Sitzungsverlauf-Protokolldatei und das zugeh'#246'rige Verzeichnis wirklich l'#246'schen?',
    'Sei sicuro di voler eliminare questo file di registro della cronologia della sessione e la sua directory?',
    'Czy na pewno chcesz usun'#261#263' ten plik dziennika historii sesji i jego katalog?',
    'Tem a certeza de que deseja eliminar este ficheiro de registo do hist'#243'rico da sess'#227'o e a sua pasta?',
    'Sunte'#539'i sigur c'#259' dori'#539'i s'#259' '#537'terge'#539'i acest fi'#537'ier jurnal cu istoricul sesiunii '#537'i directorul s'#259'u?',
    'Biztosan t'#246'rli ezt a munkamenet el'#245'zm'#233'ny napl'#243'f'#225'jlt '#233's a mapp'#225'j'#225't?',
    'Opravdu chcete smazat tento soubor protokolu historie relace a jeho slo'#382'ku?');

  Set11('Legend:',
    'Legend:',
    'Legenda:',
    'Leyenda:',
    'L''egende :',
    'Legende:',
    'Legenda:',
    'Legenda:',
    'Legenda:',
    'Legenda:',
    'Jelmagyarazat:',
    'Legenda:');

  Set11('green: equal',
    'green: equal',
    'verde = igual',
    'verde = igual',
    'vert = egal',
    'gruen = gleich',
    'verde = uguale',
    'zielony = taki sam',
    'verde = igual',
    'verde = egal',
    'zold = megegyezik',
    'zelena = shodne');

  Set11('yellow: added (right)',
    'yellow: added (right)',
    'amarelo = inserido (direita)',
    'amarillo = anadido (derecha)',
    'jaune = ajoute (droite)',
    'gelb = eingefuegt (rechts)',
    'giallo = inserito (destra)',
    'zolty = dodany (prawo)',
    'amarelo = inserido (direita)',
    'galben = adaugat (dreapta)',
    'sarga = hozzaadva (jobb)',
    'zluta = pridano (vpravo)');

  Set11('red: removed (left)',
    'red: removed (left)',
    'vermelho = removido (esquerda)',
    'rojo = eliminado (izquierda)',
    'rouge = supprime (gauche)',
    'rot = entfernt (links)',
    'rosso = rimosso (sinistra)',
    'czerwony = usuniety (lewo)',
    'vermelho = removido (esquerda)',
    'rosu = sters (stanga)',
    'piros = eltavolitva (bal)',
    'cervena = odebrano (vlevo)');

  Set11('blue: changed',
    'blue: changed',
    'azul = alterado',
    'azul = cambiado',
    'bleu = modifie',
    'blau = geaendert',
    'blu = modificato',
    'niebieski = zmieniony',
    'azul = alterado',
    'albastru = modificat',
    'kek = modositva',
    'modra = zmeneno');

  Set11('Applying merge...',
    'Applying merge...',
    'A aplicar mesclagem...',
    'Aplicando combinacion...',
    'Application de la fusion...',
    'Zusammenfuehrung wird angewendet...',
    'Applicazione unione...',
    'Stosowanie scalenia...',
    'A aplicar mesclagem...',
    'Se aplica imbinarea...',
    'Egyesites alkalmazasa...',
    'Provadi se slouceni...');

  Set11('Merge finished with %d error(s).',
    'Merge finished with %d error(s).',
    'Mesclagem concluida com %d erro(s).',
    'Combinacion finalizada con %d error(es).',
    'Fusion terminee avec %d erreur(s).',
    'Zusammenfuehrung mit %d Fehler(n) beendet.',
    'Unione completata con %d errore/i.',
    'Scalenie zakonczone z %d bledem(ami).',
    'Mesclagem concluida com %d erro(s).',
    'Imbinare terminata cu %d erori.',
    'Egyesites befejezve %d hibaval.',
    'Slouceni dokonceno s %d chybami.');

  Set11('Merge apply finished OK.',
    'Merge apply finished OK.',
    'Mesclagem aplicada com sucesso.',
    'Combinacion aplicada correctamente.',
    'Fusion appliquee avec succes.',
    'Zusammenfuehrung erfolgreich angewendet.',
    'Unione applicata correttamente.',
    'Scalenie zastosowane pomyslnie.',
    'Mesclagem aplicada com sucesso.',
    'Imbinare aplicata cu succes.',
    'Egyesites sikeresen alkalmazva.',
    'Slouceni uspesne provedeno.');

  Set11('No mergeable diff rows selected.',
    'No mergeable diff rows selected.',
    'Nenhuma linha de diff aplicavel selecionada.',
    'No hay filas de diff aplicables seleccionadas.',
    'Aucune ligne de diff applicable selectionnee.',
    'Keine anwendbaren Diff-Zeilen ausgewaehlt.',
    'Nessuna riga diff applicabile selezionata.',
    'Nie wybrano wierszy roznic do zastosowania.',
    'Nenhuma linha de diff aplicavel seleccionada.',
    'Nicio rand diff aplicabil selectat.',
    'Nincs kivalasztott alkalmazhato diff-sor.',
    'Nejsou vybrany zadne radky k aplikaci slouceni.');


  { Compare / merge — extras (11 idiomas) }
  GTextEnglish.Values['History file preview (colors from journal; line numbers are as at edit time).'] :=
    'History file preview (colors from journal; line numbers are as at edit time).';
  GTextPortuguese.Values['History file preview (colors from journal; line numbers are as at edit time).'] :=
    'Pr'#233'-visualiza'#231#227'o do arquivo (cores pelo di'#225'rio; n'#250'meros de linha conforme na edi'#231#227'o).';
  GTextSpanish.Values['History file preview (colors from journal; line numbers are as at edit time).'] :=
    'Vista previa del archivo (colores seg'#250'n el diario; n'#250'meros de l'#237'nea al momento de editar).';
  GTextFrench.Values['History file preview (colors from journal; line numbers are as at edit time).'] :=
    'Aper'#231'u du fichier (couleurs du journal; numeros de ligne au moment de l''edition).';
  GTextGerman.Values['History file preview (colors from journal; line numbers are as at edit time).'] :=
    'Dateivorschau (Farben aus dem Journal; Zeilennummern zum Bearbeitungszeitpunkt).';
  GTextItalian.Values['History file preview (colors from journal; line numbers are as at edit time).'] :=
    'Anteprima file (colori dal registro; numeri di riga al momento della modifica).';
  GTextPolish.Values['History file preview (colors from journal; line numbers are as at edit time).'] :=
    'Podglad pliku (kolory z dziennika; numery linii wg momentu edycji).';
  GTextPortuguesePT.Values['History file preview (colors from journal; line numbers are as at edit time).'] :=
    'Pr'#233'-visualiza'#231#227'o do ficheiro (cores pelo di'#225'rio; n'#250'meros de linha conforme na edi'#231#227'o).';
  GTextRomanian.Values['History file preview (colors from journal; line numbers are as at edit time).'] :=
    'Previzualizare fisier (culori din jurnal; numere de linie la momentul editarii).';
  GTextHungarian.Values['History file preview (colors from journal; line numbers are as at edit time).'] :=
    'Fajl elonezet (szinek a naplobol; sorok szama szerkeszteskor).';
  GTextCzech.Values['History file preview (colors from journal; line numbers are as at edit time).'] :=
    'Nahled souboru (barvy podle deniku; cisla radku v okamziku upravy).';

  Set11('Journal too large; line colors omitted on preview.',
    'Journal too large; line colors omitted on preview.',
    'Diario muito grande; cores omitidas na pre-visualizacao.',
    'Diario demasiado grande; colores omitidas en la vista previa.',
    'Journal trop volumineux; couleurs omises dans l''apercu.',
    'Journal zu gross; Farben in der Vorschau ausgelassen.',
    'Registro troppo grande; colori omessi nell''anteprima.',
    'Dziennik zbyt duzy; kolory w podgladzie pominiete.',
    'Diario demasiado grande; cores omitidas na pre-visualizacao.',
    'Jurnal prea mare; culori omise in previzualizare.',
    'Naplo tul nagy; szinek nelkul az elonezetben.',
    'Denik prilis velky; barvy v nahledu vynechany.');

  GTextEnglish.Values['Copy selection'] := 'Copy selection';
  GTextPortuguese.Values['Copy selection'] := 'Copiar sele'#231#227'o';
  GTextSpanish.Values['Copy selection'] := 'Copiar seleccion';
  GTextFrench.Values['Copy selection'] := 'Copier la selection';
  GTextGerman.Values['Copy selection'] := 'Auswahl kopieren';
  GTextItalian.Values['Copy selection'] := 'Copia selezione';
  GTextPolish.Values['Copy selection'] := 'Kopiuj zaznaczenie';
  GTextPortuguesePT.Values['Copy selection'] := 'Copiar selec'#231#227'o';
  GTextRomanian.Values['Copy selection'] := 'Copiaza selectia';
  GTextHungarian.Values['Copy selection'] := 'Kijeloles masolasa';
  GTextCzech.Values['Copy selection'] := 'Kopirovat vyber';

  GTextEnglish.Values['Apply selected merge to the right file (disk)'] :=
    'Apply selected merge to the right file (disk)';
  GTextPortuguese.Values['Apply selected merge to the right file (disk)'] :=
    'Aplicar mesclagem selecionada ao arquivo da direita (disco)';
  GTextSpanish.Values['Apply selected merge to the right file (disk)'] :=
    'Aplicar fusion seleccionada al archivo derecho (disco)';
  GTextFrench.Values['Apply selected merge to the right file (disk)'] :=
    'Appliquer la fusion selectionnee au fichier droit (disque)';
  GTextGerman.Values['Apply selected merge to the right file (disk)'] :=
    'Ausgewahlte Zusammenfuhrung in die rechte Datei schreiben (Festplatte)';
  GTextItalian.Values['Apply selected merge to the right file (disk)'] :=
    'Applica unione selezionata al file destro (disco)';
  GTextPolish.Values['Apply selected merge to the right file (disk)'] :=
    'Zastosuj wybrane scalenie do prawego pliku (dysk)';
  GTextPortuguesePT.Values['Apply selected merge to the right file (disk)'] :=
    'Aplicar mesclagem seleccionada ao ficheiro da direita (disco)';
  GTextRomanian.Values['Apply selected merge to the right file (disk)'] :=
    'Aplica fuziunea selectata la fisierul din dreapta (disc)';
  GTextHungarian.Values['Apply selected merge to the right file (disk)'] :=
    'Kijelolt egyesites alkalmazasa a jobb fajlra (lemez)';
  GTextCzech.Values['Apply selected merge to the right file (disk)'] :=
    'Pouzit vybrany merge do praveho souboru (disk)';

  GTextEnglish.Values['Apply selected merge to the left file (disk)'] :=
    'Apply selected merge to the left file (disk)';
  GTextPortuguese.Values['Apply selected merge to the left file (disk)'] :=
    'Aplicar mesclagem selecionada ao arquivo da esquerda (disco)';
  GTextSpanish.Values['Apply selected merge to the left file (disk)'] :=
    'Aplicar fusion seleccionada al archivo izquierdo (disco)';
  GTextFrench.Values['Apply selected merge to the left file (disk)'] :=
    'Appliquer la fusion selectionnee au fichier gauche (disque)';
  GTextGerman.Values['Apply selected merge to the left file (disk)'] :=
    'Ausgewahlte Zusammenfuhrung in die linke Datei schreiben (Festplatte)';
  GTextItalian.Values['Apply selected merge to the left file (disk)'] :=
    'Applica unione selezionata al file sinistro (disco)';
  GTextPolish.Values['Apply selected merge to the left file (disk)'] :=
    'Zastosuj wybrane scalenie do lewego pliku (dysk)';
  GTextPortuguesePT.Values['Apply selected merge to the left file (disk)'] :=
    'Aplicar mesclagem seleccionada ao ficheiro da esquerda (disco)';
  GTextRomanian.Values['Apply selected merge to the left file (disk)'] :=
    'Aplica fuziunea selectata la fisierul din stanga (disc)';
  GTextHungarian.Values['Apply selected merge to the left file (disk)'] :=
    'Kijelolt egyesites alkalmazasa a bal fajlra (lemez)';
  GTextCzech.Values['Apply selected merge to the left file (disk)'] :=
    'Pouzit vybrany merge do leveho souboru (disk)';

  Set11('  Ctrl+Shift+H ....... Compare / merge + session history (two-file diff, journal)',
    '  Ctrl+Shift+H ....... Compare / merge + session history (two-file diff, journal)',
    '  Ctrl+Shift+H ....... Comparar / mesclar + hist'#243'rico (diff, di'#225'rio)',
    '  Ctrl+Shift+H ....... Comparar / combinar + historial (diff, diario)',
    '  Ctrl+Shift+H ....... Comparer / fusionner + historique (diff, journal)',
    '  Ctrl+Shift+H ....... Vergleichen/Zusammenfuehren + Verlauf (Diff, Journal)',
    '  Ctrl+Shift+H ....... Confronta/unisci + cronologia (diff, registro)',
    '  Ctrl+Shift+H ....... Porownaj/scal + historia (diff, dziennik)',
    '  Ctrl+Shift+H ....... Comparar / mesclar + hist'#243'rico (diff, di'#225'rio)',
    '  Ctrl+Shift+H ....... Compara/imbinare + istoric (diff, jurnal)',
    '  Ctrl+Shift+H ....... Osszehasonlitas + naplo (diff, naplo)',
    '  Ctrl+Shift+H ....... Porovnat/slouceni + historie (diff, denik)');

  Set11('  Session history Reload: a worker thread reads the journal tail, filters lines, loads the preview file and optional color scan; the progress bar covers that work first, then filling the memo and list on the UI thread.',
    '  Session history Reload: a worker thread reads the journal tail, filters lines, loads the preview file and optional color scan; the progress bar covers that work first, then filling the memo and list on the UI thread.',
    '  Recarregar hist'#243'rico: uma thread de trabalho l'#234' a cauda do di'#225'rio, filtra linhas, carrega o ficheiro de pr'#233'-visualiza'#231#227'o e o scan opcional de cores; a barra cobre essa fase e depois o preenchimento do memo e da lista na UI.',
    '  Recargar historial: un hilo de trabajo lee el final del diario, filtra l'#237'neas, carga la vista previa y el escaneo de color opcional; la barra cubre esa parte y luego el memo y la lista en la UI.',
    '  Recharger l''historique : un thread de travail lit la fin du journal, filtre, charge l''aper'#231'u et le balayage couleur optionnel ; la barre suit cette phase puis le remplissage du m'#233'mo et de la liste dans l''UI.',
    '  Verlauf neu laden: Worker-Thread liest Journalende, filtert, l'#228'dt Vorschau und optionalen Farb-Scan; Fortschritt zuerst dort, dann Memo+Liste auf der UI-Thread.',
    '  Ricarica cronologia: un worker legge la coda del registro, filtra, carica anteprima e scan colori opzionale; la barra copre quella fase poi memo ed elenco nel thread UI.',
    '  Przeladowanie historii: w'#261'tek roboczy czyta koniec dziennika, filtruje, '#322'aduje podgl'#261'd i opcjonalny skan kolor'#243'w; pasek najpierw tam, potem memo i lista na w'#261'tku UI.',
    '  Recarregar hist'#243'rico: uma thread l'#234' a cauda do di'#225'rio, filtra, carrega a pr'#233'-visualiza'#231#227'o e o varrimento de cores; a barra reflecte isso e depois o memo e a lista na UI.',
    '  Reincarcare istoric: fir de executie citeste coada jurnalului, filtreaza, incarca previzualizarea si scanarea optionala de culori; bara urmeaza faza, apoi memo si lista pe UI.',
    '  Eloszmeny ujratoltese: hatterszal olvassa a naplo veget, szuri, betolti az elonezetet es az opcionalis szinszkennelest; a sav eloszor ezt, majd a memo es lista kitoltese kovetkezik a UI szalban.',
    '  Obnoveni historie relace: worker cte konec deniku, filtruje, nacita nahled a volitelny barevny pruchod; ukazatel nejdriv tuto cast, pak vyplneni memo a seznamu ve vlakne UI.');

  Set11('  The loading overlay is not stay-on-top, and the UI yields often (including a short wait for queued input) so you can use Alt+Tab and other applications during a long reload.',
    '  The loading overlay is not stay-on-top, and the UI yields often (including a short wait for queued input) so you can use Alt+Tab and other applications during a long reload.',
    '  O overlay de carga n'#227'o fica sempre por cima (top-most) e a UI cede tempo '#224' fila com pequenas esperas, para o Alt+Tab e outras aplica'#231#245'es continuarem utiliz'#225'veis durante um reload longo.',
    '  La superposici'#243'n de carga no es siempre encima; la UI cede el bucle de mensajes (con esperas cortas) para que Alt+Tab y otras apps sigan usables en recargas largas.',
    '  La superposition de chargement n''est pas toujours au premier plan ; l''UI rend la main souvent (petites attentes) pour garder Alt+Tab et les autres applications utilisables.',
    '  Das Lade-Overlay ist nicht immer im Vordergrund; die UI reicht oft an (kurze Wartezeiten), damit Alt+Tab und andere Apps bei langem Reload nutzbar bleiben.',
    '  La schermata di caricamento non resta in primo piano; l''UI cede spesso (brevi attese) cos'#236' Alt+Tab e le altre app restano usabili durante ricariche lunghe.',
    '  Nak'#322'adka post'#281'pu nie jest zawsze na wierzchu; UI cz'#281'sto oddaje ster (kr'#243'tkie oczekiwania), by Alt+Tab i inne aplikacje dzia'#322'a'#322'y przy d'#322'ugim przeladowaniu.',
    '  O overlay de progresso n'#227'o '#233' sempre-em-primeiro-plano; a UI cede tempo ao processador de mensagens (esperas curtas) para Alt+Tab e outras apps durante recargas longas.',
    '  Suprapunerea de incarcare nu ramane mereu deasupra; UI cede des (pauze scurte) ca Alt+Tab si alte aplicatii sa ramana utilizabile.',
    '  A bet'#246'lt'#233's nem mindig top-most ablak; a UI gyakran '#225'tad'#237'tja a vez'#233'rl'#233'st (r'#246'vid v'#225'rakoz'#225's), '#237'gy Alt+Tab '#233's m'#225's alkalmaz'#225'sok hossz'#250' '#250'jrat'#246'lt'#233's k'#246'zben is haszn'#225'lhat'#243'k.',
    '  Prekryv nacitani neni vzdy navrchu; UI casto predava rizeni (kratke cekani), takze Alt+Tab a jine aplikace zustanou pouzitelne pri dlouhem obnoveni.');

  GTextEnglish.Values['Select all'] := 'Select all';
  GTextPortuguese.Values['Select all'] := 'Selecionar tudo';
  GTextSpanish.Values['Select all'] := 'Seleccionar todo';
  GTextFrench.Values['Select all'] := 'Tout selectionner';
  GTextGerman.Values['Select all'] := 'Alles auswahlen';
  GTextItalian.Values['Select all'] := 'Seleziona tutto';
  GTextPolish.Values['Select all'] := 'Zaznacz wszystko';
  GTextPortuguesePT.Values['Select all'] := 'Seleccionar tudo';
  GTextRomanian.Values['Select all'] := 'Selecteaza tot';
  GTextHungarian.Values['Select all'] := 'Mind kijelolese';
  GTextCzech.Values['Select all'] := 'Vybrat vse';
end;

procedure AddCommonTranslations;
begin
  { Guard: build tables exactly once at initialization. }
  if GEnglish <> nil then Exit;

  GEnglish        := CreateTable;
  GPortuguese     := CreateTable;
  GSpanish        := CreateTable;
  GFrench         := CreateTable;
  GGerman         := CreateTable;
  GItalian        := CreateTable;
  GPolish         := CreateTable;
  GPortuguesePT   := CreateTable;
  GRomanian       := CreateTable;
  GHungarian      := CreateTable;
  GCzech          := CreateTable;
  GTextEnglish    := CreateTable;
  GTextPortuguese := CreateTable;
  GTextSpanish    := CreateTable;
  GTextFrench     := CreateTable;
  GTextGerman     := CreateTable;
  GTextItalian    := CreateTable;
  GTextPolish     := CreateTable;
  GTextPortuguesePT := CreateTable;
  GTextRomanian   := CreateTable;
  GTextHungarian  := CreateTable;
  GTextCzech      := CreateTable;

  AddCommonTranslationsBaseLanguageOptions;

  { language.option.japanese removed — Japanese replaced by new languages }

  { --- New language option keys ------------------------------------------- }
  AddCommonTranslationsNewLanguageOptions;
  AddCommonTranslationsGTextFromFiveNewLangsToBeforeSpanish;
  AddCommonTranslationsGTextSpanishItalian;
  AddCommonTranslationsGTextEnglishThroughVirtual;
  AddCommonTranslationsStaleFilePreAssign;

  AddCommonTranslationsLateDialogsAndFolders;

  { --- GText baseline for new languages ----------------------------------- }
  { Seed complete phrase tables to avoid fallback at runtime. }
  GTextPolish.Assign(GTextEnglish);
  GTextPortuguesePT.Assign(GTextPortuguese);
  GTextRomanian.Assign(GTextEnglish);
  GTextHungarian.Assign(GTextEnglish);
  GTextCzech.Assign(GTextEnglish);
  AddCommonTranslationsStaleFilePostSeed;
  AddCommonTranslationsCompareMerge;

  { --- GText targeted overrides: Polish ----------------------------------- }
  GTextPolish.Values['Application language'] := 'J'#234'zyk aplikacji';
  GTextPolish.Values['Operation cancelled.'] := 'Operacja anulowana.';
  GTextPolish.Values['Delete confirmation'] := 'Potwierdzenie usuni'#234'cia';
  GTextPolish.Values['Import file extensions'] := 'Importuj rozszerzenia plik'#243'w';
  GTextPolish.Values['Importing file extensions to exclude from search'] := 'Importowanie rozszerze'#241' plik'#243'w do wykluczenia z wyszukiwania';

  { --- GText targeted overrides: Portuguese (Portugal) -------------------- }
  GTextPortuguesePT.Values['Please select a file.'] := 'Selecione um ficheiro.';
  GTextPortuguesePT.Values['Please select a file first.'] := 'Selecione um ficheiro primeiro.';
  GTextPortuguesePT.Values['Please read the file first.'] := 'Leia o ficheiro primeiro.';
  GTextPortuguesePT.Values['Please read a file first.'] := 'Leia um ficheiro primeiro.';
  GTextPortuguesePT.Values['File not found.'] := 'Ficheiro n'#227'o encontrado.';
  GTextPortuguesePT.Values['Importing file extensions to exclude from search'] := 'Importar extens'#245'es de ficheiro para excluir da pesquisa';
  GTextPortuguesePT.Values['Enter search text.'] := 'Digite o texto a pesquisar.';
  GTextPortuguesePT.Values['Type the text to search:'] := 'Digite o texto a pesquisar:';
  GTextPortuguesePT.Values['Search'] := 'Pesquisar';
  GTextPortuguesePT.Values['Case sensitive search?'] := 'Pesquisa com distin'#231''#227'o de mai'#250'sculas/min'#250'sculas?';
  GTextPortuguesePT.Values['Please enter a search word.'] := 'Digite uma palavra de pesquisa.';
  GTextPortuguesePT.Values['Text not found.'] := 'Texto n'#227'o encontrado.';
  GTextPortuguesePT.Values['No active filter. Press Ctrl+L first.'] := 'N'#227'o h'#225' filtro ativo. Prima Ctrl+L primeiro.';
  GTextPortuguesePT.Values['Filter has no results to export.'] := 'O filtro n'#227'o possui resultados para exportar.';
  GTextPortuguesePT.Values['No lines entered. Operation cancelled.'] := 'Nenhuma linha introduzida. Opera'#231#227'o cancelada.';
  GTextPortuguesePT.Values['Cannot sort the list while a search is in progress.'] := 'N'#227'o '#233' poss'#237'vel ordenar a lista enquanto uma pesquisa est'#225' em progresso.';
  GTextPortuguesePT.Values['Filter / Grep'] := 'Filtro / Pesquisa';
  GTextPortuguesePT.Values['Show only lines containing:'] := 'Mostrar apenas linhas que contenham:';
  GTextPortuguesePT.Values['Find in &Files...'] := 'Pesquisar em &Ficheiros...';
  GTextPortuguesePT.Values['&Recent files'] := '&Ficheiros recentes';
  GTextPortuguesePT.Values['Read &tab'] := 'Separador de &leitura';
  GTextPortuguesePT.Values['Extension files exclusion'] := 'Exclus'#227'o de extens'#245'es de ficheiro';
  GTextPortuguesePT.Values['Please enter with file extension to exclude in the files search'] := 'Introduza a extens'#227'o de ficheiro a excluir da pesquisa em ficheiros';
  GTextPortuguesePT.Values['Folders exclusion'] := 'Exclus'#227'o de pastas';
  GTextPortuguesePT.Values['Please enter with folder extension to exclude in the files search'] := 'Introduza a extens'#227'o de pasta a excluir da pesquisa em ficheiros';
  GTextPortuguesePT.Values['File created:'] := 'Ficheiro criado:';
  GTextPortuguesePT.Values['Folder saved with success.'] := 'Pasta guardada com sucesso.';
  GTextPortuguesePT.Values['File saved with success.'] := 'Ficheiro guardado com sucesso.';
  GTextPortuguesePT.Values['&View'] := '&Ver';

  { --- GText targeted overrides: Romanian --------------------------------- }
  GTextRomanian.Values['Application language'] := 'Limba aplica'#254'iei';
  GTextRomanian.Values['Operation cancelled.'] := 'Opera'#254'iune anulat'#227'.';
  GTextRomanian.Values['Delete confirmation'] := 'Confirmare '#170'tergere';
  GTextRomanian.Values['Import file extensions'] := 'Import extensii fi'#186'ier';
  GTextRomanian.Values['Importing file extensions to exclude from search'] := 'Importul extensiilor de fi'#186'ier de exclus din c'#227'utare';

  { --- GText targeted overrides: Hungarian -------------------------------- }
  GTextHungarian.Values['Application language'] := 'Alkalmaz'#225's nyelve';
  GTextHungarian.Values['Operation cancelled.'] := 'M'#251'velet megszak'#237'tva.';
  GTextHungarian.Values['Delete confirmation'] := 'T'#246'rl'#233's meger'#245's'#237't'#233'se';
  GTextHungarian.Values['Import file extensions'] := 'F'#225'jlkiterjeszt'#233'sek import'#225'l'#225'sa';
  GTextHungarian.Values['Importing file extensions to exclude from search'] := 'Keres'#233'sb'#245'l kiz'#225'rand'#243' f'#225'jlkiterjeszt'#233'sek import'#225'l'#225'sa';

  { --- GText targeted overrides: Czech ------------------------------------ }
  GTextCzech.Values['Application language'] := 'Jazyk aplikace';
  GTextCzech.Values['Operation cancelled.'] := 'Operace zru'#154'ena.';
  GTextCzech.Values['Delete confirmation'] := 'Potvrzen'#237' smaz'#225'n'#237'';
  GTextCzech.Values['Import file extensions'] := 'Importovat p'#248'ipony soubor'#249'';
  GTextCzech.Values['Importing file extensions to exclude from search'] := 'Import p'#248'ipon soubor'#249' pro vylou'#232'en'#237' z hled'#225'n'#237'';

  { --- COMPLETE MENU KEYS for Polish, Romanian, Hungarian, Czech -------- }
  { Polish menu items }
  GTextPolish.Values['&Open file...'] := '&Otworz plik...';
  GTextPolish.Values['&Recent files'] := '&Ostatnie pliki';
  GTextPolish.Values['Read &tab'] := 'Czytaj &karte';
  GTextPolish.Values['Read / &Load'] := 'Czytaj / &Laduj';
  GTextPolish.Values['E&xit'] := '&Wyjscie';
  GTextPolish.Values['&Find...'] := '&Znajdz...';
  GTextPolish.Values['Find in &Files...'] := 'Znajdz w &Plikach...';
  GTextPolish.Values['Find and &Replace...'] := 'Znajdz i &Zamien...';
  GTextPolish.Values['&Go to line...'] := '&Przejdz do linii...';
  GTextPolish.Values['Undo'] := 'Cofnij';
  GTextPolish.Values['Redo'] := 'Ponow';
  GTextPolish.Values['Copy selection'] := 'Kopiuj zaznaczenie';
  GTextPolish.Values['&View'] := '&Widok';
  GTextPolish.Values['&Word wrap'] := '&Zawijanie wierszy';
  GTextPolish.Values['Tail / &Follow mode'] := 'Tail / Tryb &Sledzenia';
  GTextPolish.Values['Fil&ter / Grep'] := 'Fil&tr / Grep';
  GTextPolish.Values['E&xport filtered results'] := 'E&ksportuj filtrowane wyniki';
  GTextPolish.Values['&Toggle bookmark'] := '&Przelacz zakladke';
  GTextPolish.Values['&Next bookmark'] := '&Nastepna zakladka';
  GTextPolish.Values['Pr&evious bookmark'] := 'Po&przednia zakladka';
  GTextPolish.Values['Clear a&ll bookmarks'] := 'Wyczysc &wszystkie zakladki';
  GTextPolish.Values['S&elect (checkbox list)'] := 'W&ybierz (lista checkbox)';
  GTextPolish.Values['Spl&it Files'] := 'Podz&iel pliki';
  GTextPolish.Values['&Merge lines'] := '&Scal linie';
  GTextPolish.Values['&Insert line'] := '&Wstaw linie';
  GTextPolish.Values['&Edit line'] := '&Edytuj linie';
  GTextPolish.Values['&Delete line'] := '&Usun linie';
  GTextPolish.Values['Exp&ort'] := 'Eks&pport';
  GTextPolish.Values['&Clear'] := '&Wyczysc';
  GTextPolish.Values['&AI (Consumer)'] := '&AI (Konsument)';
  GTextPolish.Values['&Help / Shortcuts'] := '&Pomoc / Skroty';
  GTextPolish.Values['&Version History'] := 'Historia &wersji';
  GTextPolish.Values['&More info / Splash...'] := 'Wiecej &informacji / Splash...';
  GTextPolish.Values['&About FastFile'] := '&O FastFile';

  { Romanian menu items }
  GTextRomanian.Values['&Open file...'] := '&Deschide fisier...';
  GTextRomanian.Values['&Recent files'] := '&Fisiere recente';
  GTextRomanian.Values['Read &tab'] := 'Citire &tab';
  GTextRomanian.Values['Read / &Load'] := 'Citire / &Incarcare';
  GTextRomanian.Values['E&xit'] := '&Iesire';
  GTextRomanian.Values['&Find...'] := '&Cautare...';
  GTextRomanian.Values['Find in &Files...'] := 'Cautare in &Fisiere...';
  GTextRomanian.Values['Find and &Replace...'] := 'Cautare si &Inlocuire...';
  GTextRomanian.Values['&Go to line...'] := '&Mergi la linie...';
  GTextRomanian.Values['Undo'] := 'Anuleaza';
  GTextRomanian.Values['Redo'] := 'Refa';
  GTextRomanian.Values['Copy selection'] := 'Copiaza selectia';
  GTextRomanian.Values['&View'] := '&Vizualizare';
  GTextRomanian.Values['&Word wrap'] := '&Incadrare text';
  GTextRomanian.Values['Tail / &Follow mode'] := 'Tail / Mod &Urmarire';
  GTextRomanian.Values['Fil&ter / Grep'] := 'Fil&tru / Grep';
  GTextRomanian.Values['E&xport filtered results'] := 'E&xporta rezultate filtrate';
  GTextRomanian.Values['&Toggle bookmark'] := '&Comuta semn de carte';
  GTextRomanian.Values['&Next bookmark'] := '&Urmatorul semn de carte';
  GTextRomanian.Values['Pr&evious bookmark'] := 'Se&mnul de carte anterior';
  GTextRomanian.Values['Clear a&ll bookmarks'] := 'Sterge &toate semnele de carte';
  GTextRomanian.Values['S&elect (checkbox list)'] := 'S&electeaza (lista checkbox)';
  GTextRomanian.Values['Spl&it Files'] := 'Im&parte fisiere';
  GTextRomanian.Values['&Merge lines'] := '&Uneste linii';
  GTextRomanian.Values['&Insert line'] := '&Insereaza linie';
  GTextRomanian.Values['&Edit line'] := '&Editeaza linie';
  GTextRomanian.Values['&Delete line'] := '&Sterge linie';
  GTextRomanian.Values['Exp&ort'] := 'Exp&orta';
  GTextRomanian.Values['&Clear'] := '&Curata';
  GTextRomanian.Values['&AI (Consumer)'] := '&AI (Consumator)';
  GTextRomanian.Values['&Help / Shortcuts'] := '&Ajutor / Comenzi rapide';
  GTextRomanian.Values['&Version History'] := 'Istoric &versiuni';
  GTextRomanian.Values['&More info / Splash...'] := 'Mai multe &informatii / Splash...';
  GTextRomanian.Values['&About FastFile'] := '&Despre FastFile';

  { Hungarian menu items }
  GTextHungarian.Values['&Open file...'] := '&Fajl megnyitas...';
  GTextHungarian.Values['&Recent files'] := '&Legutobbi fajlok';
  GTextHungarian.Values['Read &tab'] := 'Olvasas &lap';
  GTextHungarian.Values['Read / &Load'] := 'Olvasas / &Betoltes';
  GTextHungarian.Values['E&xit'] := '&Kilepes';
  GTextHungarian.Values['&Find...'] := '&Kereses...';
  GTextHungarian.Values['Find in &Files...'] := 'Kereses a &Fajlokban...';
  GTextHungarian.Values['Find and &Replace...'] := 'Kereses es &Csere...';
  GTextHungarian.Values['&Go to line...'] := '&Ugras sorra...';
  GTextHungarian.Values['Undo'] := 'Visszavonas';
  GTextHungarian.Values['Redo'] := 'Ismetles';
  GTextHungarian.Values['Copy selection'] := 'Kijeloles masolasa';
  GTextHungarian.Values['&View'] := '&N'#233'zet';
  GTextHungarian.Values['&Word wrap'] := '&Sortores';
  GTextHungarian.Values['Tail / &Follow mode'] := 'Tail / &Kovetes mod';
  GTextHungarian.Values['Fil&ter / Grep'] := 'Szuro / Grep';
  GTextHungarian.Values['E&xport filtered results'] := '&Export szurt eredmenyek';
  GTextHungarian.Values['&Toggle bookmark'] := '&Konyvjelzo kapcsolasa';
  GTextHungarian.Values['&Next bookmark'] := '&Kovetkezo konyvjelzo';
  GTextHungarian.Values['Pr&evious bookmark'] := 'Elozo konyvjelzo';
  GTextHungarian.Values['Clear a&ll bookmarks'] := 'Minden konyvjelzo &torlese';
  GTextHungarian.Values['S&elect (checkbox list)'] := 'K&ijeloles (checkbox lista)';
  GTextHungarian.Values['Spl&it Files'] := 'Fajlok fe&losztasa';
  GTextHungarian.Values['&Merge lines'] := '&Sorok egyesitese';
  GTextHungarian.Values['&Insert line'] := '&Sor beszurasa';
  GTextHungarian.Values['&Edit line'] := '&Sor szerkesztese';
  GTextHungarian.Values['&Delete line'] := '&Sor torlese';
  GTextHungarian.Values['Exp&ort'] := 'Exp&ort';
  GTextHungarian.Values['&Clear'] := '&Torles';
  GTextHungarian.Values['&AI (Consumer)'] := '&AI (Consumer)';
  GTextHungarian.Values['&Help / Shortcuts'] := '&Sugo / Billentyuparancsok';
  GTextHungarian.Values['&Version History'] := '&Verzio tortenet';
  GTextHungarian.Values['&More info / Splash...'] := 'Tobb &info / Splash...';
  GTextHungarian.Values['&About FastFile'] := '&FastFile nevjegye';

  { Czech menu items }
  GTextCzech.Values['&Open file...'] := '&Otevrit soubor...';
  GTextCzech.Values['&Recent files'] := '&Nedavne soubory';
  GTextCzech.Values['Read &tab'] := 'Cteni &zalozky';
  GTextCzech.Values['Read / &Load'] := 'Cteni / &Nacist';
  GTextCzech.Values['E&xit'] := '&Ukoncit';
  GTextCzech.Values['&Find...'] := '&Hledat...';
  GTextCzech.Values['Find in &Files...'] := 'Hledat v &Souborech...';
  GTextCzech.Values['Find and &Replace...'] := 'Hledat a &Nahradit...';
  GTextCzech.Values['&Go to line...'] := '&Prejit na radek...';
  GTextCzech.Values['Undo'] := 'Zpet';
  GTextCzech.Values['Redo'] := 'Znovu';
  GTextCzech.Values['Copy selection'] := 'Kopirovat vyber';
  GTextCzech.Values['&View'] := '&Zobrazeni';
  GTextCzech.Values['&Word wrap'] := '&Zalamovani textu';
  GTextCzech.Values['Tail / &Follow mode'] := 'Tail / Rezim &Sledovani';
  GTextCzech.Values['Fil&ter / Grep'] := 'Fil&tr / Grep';
  GTextCzech.Values['E&xport filtered results'] := 'E&xportovat filtrovane vysledky';
  GTextCzech.Values['&Toggle bookmark'] := '&Prepnout zalozku';
  GTextCzech.Values['&Next bookmark'] := '&Dalsi zalozka';
  GTextCzech.Values['Pr&evious bookmark'] := 'Predchozi zalozka';
  GTextCzech.Values['Clear a&ll bookmarks'] := 'Smazat &vsechny zalozky';
  GTextCzech.Values['S&elect (checkbox list)'] := '&Vybrat (checkbox list)';
  GTextCzech.Values['Spl&it Files'] := 'Ro&zdelit soubory';
  GTextCzech.Values['&Merge lines'] := '&Sloucit radky';
  GTextCzech.Values['&Insert line'] := '&Vlozit radek';
  GTextCzech.Values['&Edit line'] := '&Upravit radek';
  GTextCzech.Values['&Delete line'] := '&Smazat radek';
  GTextCzech.Values['Exp&ort'] := 'Exp&ort';
  GTextCzech.Values['&Clear'] := '&Vycistit';
  GTextCzech.Values['&AI (Consumer)'] := '&AI (Consumer)';
  GTextCzech.Values['&Help / Shortcuts'] := '&Napoveda / Zkratky';
  GTextCzech.Values['&Version History'] := 'Historie &verzi';
  GTextCzech.Values['&More info / Splash...'] := 'Vice &info / Splash...';
  GTextCzech.Values['&About FastFile'] := '&O FastFile';

  { --- UI completeness for new languages (menus/tabs/find/split) --------- }
  { Polish }
  GTextPolish.Values['&File'] := '&Plik';
  GTextPolish.Values['&Edit'] := '&Edycja';
  GTextPolish.Values['&Options'] := '&Opcje';
  GTextPolish.Values['&Help'] := '&Pomoc';
  GTextPolish.Values['Read File'] := 'Czytaj plik';
  GTextPolish.Values['Split File'] := 'Podziel plik';
  GTextPolish.Values['Find Files'] := 'Znajd'#378' pliki';
  GTextPolish.Values['Split By Lines'] := 'Podzia'#322' wg linii';
  GTextPolish.Values['Split By Files'] := 'Podzia'#322' wg plik'#243'w';
  GTextPolish.Values['Exported Lines'] := 'Wyeksportowane linie';
  GTextPolish.Values['Name && Location'] := 'Nazwa && Lokalizacja';
  GTextPolish.Values['Folders exclude'] := 'Wyklucz foldery';
  GTextPolish.Values['Add-ons'] := 'Dodatki';
  GTextPolish.Values['File toolbar'] := 'Pasek pliku';
  GTextPolish.Values['Find'] := 'Szukaj';
  GTextPolish.Values['Stop'] := 'Stop';
  GTextPolish.Values['Return'] := 'Powr'#243't';
  GTextPolish.Values['Copy'] := 'Kopiuj';
  GTextPolish.Values['From:'] := 'Od:';
  GTextPolish.Values['To:'] := 'Do:';
  GTextPolish.Values['Execute'] := 'Wykonaj';
  GTextPolish.Values['File Info'] := 'Informacje o pliku';
  GTextPolish.Values['File name:'] := 'Nazwa pliku:';
  GTextPolish.Values['Creation Date:'] := 'Data utworzenia:';
  GTextPolish.Values['Total characters:'] := 'Liczba znak'#243'w:';
  GTextPolish.Values['Total lines:'] := 'Liczba linii:';
  GTextPolish.Values['Date && Time'] := 'Data && Czas';
  GTextPolish.Values['Created'] := 'Utworzone';
  GTextPolish.Values['Modified'] := 'Zmodyfikowane';
  GTextPolish.Values['Accessed'] := 'Dost'#281'p';
  GTextPolish.Values['Size && Attributes'] := 'Rozmiar && Atrybuty';
  GTextPolish.Values['Include subfolders'] := 'Uwzgl'#281'dnij podfoldery';
  GTextPolish.Values['Case Sensitive'] := 'Uwzgl'#281'dniaj wielko'#347#263' liter';
  GTextPolish.Values['Whole Word'] := 'Ca'#322'e s'#322'owo';
  GTextPolish.Values['Excluded'] := 'Wykluczone';
  GTextPolish.Values['Threaded Search'] := 'Wyszukiwanie w'#261'tkowe';
  GTextPolish.Values['Output FileName:'] := 'Nazwa pliku wyj'#347'ciowego:';
  GTextPolish.Values['Generating new file by source and target lines'] := 'Tworzenie nowego pliku wg linii '#378'r'#243'd'#322'owych i docelowych';
  GTextPolish.Values['Generating splitted files - max 100'] := 'Tworzenie podzielonych plikow - max 100';

  { Romanian }
  GTextRomanian.Values['&File'] := '&Fi'#537'ier';
  GTextRomanian.Values['&Edit'] := '&Editare';
  GTextRomanian.Values['&Options'] := '&Op'#539'iuni';
  GTextRomanian.Values['&Help'] := '&Ajutor';
  GTextRomanian.Values['Read File'] := 'Citire fi'#537'ier';
  GTextRomanian.Values['Split File'] := #206'mparte fi'#537'ier';
  GTextRomanian.Values['Find Files'] := 'G'#259'se'#537'te fi'#537'iere';
  GTextRomanian.Values['Split By Lines'] := #206'mparte dup'#259' linii';
  GTextRomanian.Values['Split By Files'] := #206'mparte dup'#259' fi'#537'iere';
  GTextRomanian.Values['Exported Lines'] := 'Linii exportate';
  GTextRomanian.Values['Name && Location'] := 'Nume && Loca'#539'ie';
  GTextRomanian.Values['Folders exclude'] := 'Exclude foldere';
  GTextRomanian.Values['Add-ons'] := 'Module';
  GTextRomanian.Values['File toolbar'] := 'Bara fi'#537'ier';
  GTextRomanian.Values['Find'] := 'Caut'#259'';
  GTextRomanian.Values['Stop'] := 'Stop';
  GTextRomanian.Values['Return'] := #206'napoi';
  GTextRomanian.Values['Copy'] := 'Copiaz'#259'';
  GTextRomanian.Values['From:'] := 'De la:';
  GTextRomanian.Values['To:'] := 'P'#226'n'#259' la:';
  GTextRomanian.Values['Execute'] := 'Execut'#259'';
  GTextRomanian.Values['File Info'] := 'Info fi'#537'ier';
  GTextRomanian.Values['File name:'] := 'Nume fi'#537'ier:';
  GTextRomanian.Values['Creation Date:'] := 'Data creare:';
  GTextRomanian.Values['Total characters:'] := 'Total caractere:';
  GTextRomanian.Values['Total lines:'] := 'Total linii:';
  GTextRomanian.Values['Date && Time'] := 'Data && Ora';
  GTextRomanian.Values['Created'] := 'Creat';
  GTextRomanian.Values['Modified'] := 'Modificat';
  GTextRomanian.Values['Accessed'] := 'Accesat';
  GTextRomanian.Values['Size && Attributes'] := 'Dimensiune && Atribute';
  GTextRomanian.Values['Include subfolders'] := 'Include subfoldere';
  GTextRomanian.Values['Case Sensitive'] := 'Diferen'#539'iaz'#259' majuscule';
  GTextRomanian.Values['Whole Word'] := 'Cuv'#226'nt intreg';
  GTextRomanian.Values['Excluded'] := 'Exclus';
  GTextRomanian.Values['Threaded Search'] := 'C'#259'utare pe thread';
  GTextRomanian.Values['Output FileName:'] := 'Nume fi'#537'ier ie'#537'ire:';
  GTextRomanian.Values['Generating new file by source and target lines'] := 'Genereaz'#259' fi'#537'ier nou dup'#259' linii surs'#259' '#537'i '#539'int'#259'';
  GTextRomanian.Values['Generating splitted files - max 100'] := 'Genereaz'#259' fi'#537'iere '#238'mp'#259'r'#539'ite - max 100';

  { Hungarian }
  GTextHungarian.Values['&File'] := '&F'#225'jl';
  GTextHungarian.Values['&Edit'] := '&Szerkeszt'#233's';
  GTextHungarian.Values['&Options'] := '&Be'#225'll'#237't'#225'sok';
  GTextHungarian.Values['&Help'] := '&S'#250'g'#243'';
  GTextHungarian.Values['Read File'] := 'F'#225'jl olvas'#225's';
  GTextHungarian.Values['Split File'] := 'F'#225'jl darabol'#225's';
  GTextHungarian.Values['Find Files'] := 'F'#225'jlok keres'#233'se';
  GTextHungarian.Values['Split By Lines'] := 'Darabol'#225's sorok szerint';
  GTextHungarian.Values['Split By Files'] := 'Darabol'#225's f'#225'jlok szerint';
  GTextHungarian.Values['Exported Lines'] := 'Export'#225'lt sorok';
  GTextHungarian.Values['Name && Location'] := 'N'#233'v && Hely';
  GTextHungarian.Values['Folders exclude'] := 'Mapp'#225'k kiz'#225'r'#225'sa';
  GTextHungarian.Values['Add-ons'] := 'Kieg'#233'sz'#237't'#337'k';
  GTextHungarian.Values['File toolbar'] := 'F'#225'jl eszk'#246'zt'#225'r';
  GTextHungarian.Values['Find'] := 'Keres'#233's';
  GTextHungarian.Values['Stop'] := 'Le'#225'll'#237't';
  GTextHungarian.Values['Return'] := 'Vissza';
  GTextHungarian.Values['Copy'] := 'M'#225'sol'#225's';
  GTextHungarian.Values['From:'] := 'T'#337'l:';
  GTextHungarian.Values['To:'] := 'Ig:';
  GTextHungarian.Values['Execute'] := 'V'#233'grehajt';
  GTextHungarian.Values['File Info'] := 'F'#225'jl inf'#243'';
  GTextHungarian.Values['File name:'] := 'F'#225'jln'#233'v:';
  GTextHungarian.Values['Creation Date:'] := 'L'#233'trehoz'#225's d'#225'tuma:';
  GTextHungarian.Values['Total characters:'] := 'Karakterek sz'#225'ma:';
  GTextHungarian.Values['Total lines:'] := 'Sorok szama:';
  GTextHungarian.Values['Date && Time'] := 'D'#225'tum && Id'#337'';
  GTextHungarian.Values['Created'] := 'L'#233'trehozva';
  GTextHungarian.Values['Modified'] := 'M'#243'dos'#237'tva';
  GTextHungarian.Values['Accessed'] := 'Hozz'#225'f'#233'rve';
  GTextHungarian.Values['Size && Attributes'] := 'M'#233'ret && Attrib'#250'tumok';
  GTextHungarian.Values['Include subfolders'] := 'Almapp'#225'k bele'#233'rtve';
  GTextHungarian.Values['Case Sensitive'] := 'Kis-/nagybet'#369' '#233'rz'#233'keny';
  GTextHungarian.Values['Whole Word'] := 'Teljes sz'#243'';
  GTextHungarian.Values['Excluded'] := 'Kizarva';
  GTextHungarian.Values['Threaded Search'] := 'Sz'#225'las keres'#233's';
  GTextHungarian.Values['Output FileName:'] := 'Kimeneti f'#225'jln'#233'v:';
  GTextHungarian.Values['Generating new file by source and target lines'] := #218'j f'#225'jl gener'#225'l'#225'sa forr'#225's '#233's c'#233'l sorok alapj'#225'n';
  GTextHungarian.Values['Generating splitted files - max 100'] := 'Darabolt f'#225'jlok gener'#225'l'#225'sa - max 100';

  { Czech }
  GTextCzech.Values['&File'] := '&Soubor';
  GTextCzech.Values['&Edit'] := '&'#218'pravy';
  GTextCzech.Values['&Options'] := '&Mo'#382'nosti';
  GTextCzech.Values['&Help'] := '&N'#225'pov'#283'da';
  GTextCzech.Values['Read File'] := #268'ten'#237' souboru';
  GTextCzech.Values['Split File'] := 'Rozd'#283'lit soubor';
  GTextCzech.Values['Find Files'] := 'Hledat soubory';
  GTextCzech.Values['Split By Lines'] := 'Rozd'#283'lit podle '#345#225'dk'#367'';
  GTextCzech.Values['Split By Files'] := 'Rozd'#283'lit podle soubor'#367'';
  GTextCzech.Values['Exported Lines'] := 'Exportovan'#233' '#345#225'dky';
  GTextCzech.Values['Name && Location'] := 'N'#225'zev && Um'#237'st'#283'n'#237'';
  GTextCzech.Values['Folders exclude'] := 'Vylou'#269'it slo'#382'ky';
  GTextCzech.Values['Add-ons'] := 'Dopl'#328'ky';
  GTextCzech.Values['File toolbar'] := 'Panel souboru';
  GTextCzech.Values['Find'] := 'Hledat';
  GTextCzech.Values['Stop'] := 'Stop';
  GTextCzech.Values['Return'] := 'Zp'#283't';
  GTextCzech.Values['Copy'] := 'Kop'#237'rovat';
  GTextCzech.Values['From:'] := 'Od:';
  GTextCzech.Values['To:'] := 'Do:';
  GTextCzech.Values['Execute'] := 'Spustit';
  GTextCzech.Values['File Info'] := 'Info souboru';
  GTextCzech.Values['File name:'] := 'N'#225'zev souboru:';
  GTextCzech.Values['Creation Date:'] := 'Datum vytvo'#345'en'#237':';
  GTextCzech.Values['Total characters:'] := 'Po'#269'et znak'#367':';
  GTextCzech.Values['Total lines:'] := 'Po'#269'et '#345#225'dk'#367':';
  GTextCzech.Values['Date && Time'] := 'Datum && '#268'as';
  GTextCzech.Values['Created'] := 'Vytvo'#345'eno';
  GTextCzech.Values['Modified'] := 'Zm'#283'n'#283'no';
  GTextCzech.Values['Accessed'] := 'P'#345#237'stup';
  GTextCzech.Values['Size && Attributes'] := 'Velikost && Atributy';
  GTextCzech.Values['Include subfolders'] := 'V'#269'etn'#283' podslo'#382'ek';
  GTextCzech.Values['Case Sensitive'] := 'Rozli'#353'ovat velk'#225'/mal'#225'';
  GTextCzech.Values['Whole Word'] := 'Cel'#233' slovo';
  GTextCzech.Values['Excluded'] := 'Vylou'#269'eno';
  GTextCzech.Values['Threaded Search'] := 'Vl'#225'knov'#233' hled'#225'n'#237'';
  GTextCzech.Values['Output FileName:'] := 'N'#225'zev v'#253'stupn'#237'ho souboru:';
  GTextCzech.Values['Generating new file by source and target lines'] := 'Generov'#225'n'#237' nov'#233'ho souboru podle zdrojov'#253'ch a c'#237'lov'#253'ch '#345#225'dk'#367'';
  GTextCzech.Values['Generating splitted files - max 100'] := 'Generov'#225'n'#237' rozd'#283'len'#253'ch soubor'#367' - max 100';

  { --- Option A: critical UI captions for tabs/find/split ---------------- }
  { Tabs and key section headers }
  GTextPortuguese.Values['Read File'] := 'Ler Arquivo';
  GTextSpanish.Values['Read File'] := 'Leer archivo';
  GTextFrench.Values['Read File'] := 'Lire fichier';
  GTextGerman.Values['Read File'] := 'Datei lesen';
  GTextItalian.Values['Read File'] := 'Leggi file';

  GTextPortuguese.Values['Split File'] := 'Dividir Arquivo';
  GTextSpanish.Values['Split File'] := 'Dividir archivo';
  GTextFrench.Values['Split File'] := 'Diviser fichier';
  GTextGerman.Values['Split File'] := 'Datei teilen';
  GTextItalian.Values['Split File'] := 'Dividi file';

  GTextPortuguese.Values['Exported Lines'] := 'Linhas Exportadas';
  GTextSpanish.Values['Exported Lines'] := 'L'#237'neas exportadas';
  GTextFrench.Values['Exported Lines'] := 'Lignes export'#233'es';
  GTextGerman.Values['Exported Lines'] := 'Exportierte Zeilen';
  GTextItalian.Values['Exported Lines'] := 'Righe esportate';

  GTextPortuguese.Values['Split By Lines'] := 'Dividir por Linhas';
  GTextSpanish.Values['Split By Lines'] := 'Dividir por l'#237'neas';
  GTextFrench.Values['Split By Lines'] := 'Diviser par lignes';
  GTextGerman.Values['Split By Lines'] := 'Nach Zeilen teilen';
  GTextItalian.Values['Split By Lines'] := 'Dividi per righe';

  GTextPortuguese.Values['Split By Files'] := 'Dividir por Arquivos';
  GTextSpanish.Values['Split By Files'] := 'Dividir por archivos';
  GTextFrench.Values['Split By Files'] := 'Diviser par fichiers';
  GTextGerman.Values['Split By Files'] := 'Nach Dateien teilen';
  GTextItalian.Values['Split By Files'] := 'Dividi per file';

  GTextPortuguese.Values['Add-ons'] := 'Extras';
  GTextSpanish.Values['Add-ons'] := 'Complementos';
  GTextFrench.Values['Add-ons'] := 'Modules compl'#233'mentaires';
  GTextGerman.Values['Add-ons'] := 'Erweiterungen';
  GTextItalian.Values['Add-ons'] := 'Componenti aggiuntivi';

  GTextPortuguese.Values['File toolbar'] := 'Barra de ferramentas do arquivo';
  GTextSpanish.Values['File toolbar'] := 'Barra de herramientas de archivo';
  GTextFrench.Values['File toolbar'] := 'Barre d''outils fichier';
  GTextGerman.Values['File toolbar'] := 'Datei-Symbolleiste';
  GTextItalian.Values['File toolbar'] := 'Barra strumenti file';

  GTextPortuguese.Values['Name && Location'] := 'Nome && Local';
  GTextSpanish.Values['Name && Location'] := 'Nombre && Ubicaci'#243'n';
  GTextFrench.Values['Name && Location'] := 'Nom && Emplacement';
  GTextGerman.Values['Name && Location'] := 'Name && Speicherort';
  GTextItalian.Values['Name && Location'] := 'Nome && Percorso';

  GTextPortuguese.Values['Folders exclude'] := 'Excluir Pastas';
  GTextSpanish.Values['Folders exclude'] := 'Excluir carpetas';
  GTextFrench.Values['Folders exclude'] := 'Exclure dossiers';
  GTextGerman.Values['Folders exclude'] := 'Ordner ausschlie'#223'en';
  GTextItalian.Values['Folders exclude'] := 'Escludi cartelle';

  { Find Files labels and controls }
  GTextPortuguese.Values['File Name (Separate multiple names with semicolon):'] := 'Nome do arquivo (separe m'#250'ltiplos nomes com ponto e v'#237'rgula):';
  GTextSpanish.Values['File Name (Separate multiple names with semicolon):'] := 'Nombre de archivo (separe m'#250'ltiples nombres con punto y coma):';
  GTextFrench.Values['File Name (Separate multiple names with semicolon):'] := 'Nom de fichier (s'#233'parez plusieurs noms par point-virgule):';
  GTextGerman.Values['File Name (Separate multiple names with semicolon):'] := 'Dateiname (mehrere Namen mit Semikolon trennen):';
  GTextItalian.Values['File Name (Separate multiple names with semicolon):'] := 'Nome file (separare pi'#249' nomi con punto e virgola):';

  GTextPortuguese.Values['Location (Separate multiple directories with semicolon):'] := 'Local (separe m'#250'ltiplos diret'#243'rios com ponto e v'#237'rgula):';
  GTextSpanish.Values['Location (Separate multiple directories with semicolon):'] := 'Ubicaci'#243'n (separe m'#250'ltiples directorios con punto y coma):';
  GTextFrench.Values['Location (Separate multiple directories with semicolon):'] := 'Emplacement (s'#233'parez plusieurs dossiers par point-virgule):';
  GTextGerman.Values['Location (Separate multiple directories with semicolon):'] := 'Speicherort (mehrere Verzeichnisse mit Semikolon trennen):';
  GTextItalian.Values['Location (Separate multiple directories with semicolon):'] := 'Percorso (separare pi'#249' cartelle con punto e virgola):';

  GTextPortuguese.Values['Include subfolders'] := 'Incluir subpastas';
  GTextSpanish.Values['Include subfolders'] := 'Incluir subcarpetas';
  GTextFrench.Values['Include subfolders'] := 'Inclure les sous-dossiers';
  GTextGerman.Values['Include subfolders'] := 'Unterordner einbeziehen';
  GTextItalian.Values['Include subfolders'] := 'Includi sottocartelle';

  GTextPortuguese.Values['Case Sensitive'] := 'Diferenciar mai'#250'sculas/min'#250'sculas';
  GTextSpanish.Values['Case Sensitive'] := 'Distinguir may'#250'sculas/min'#250'sculas';
  GTextFrench.Values['Case Sensitive'] := 'Respecter la casse';
  GTextGerman.Values['Case Sensitive'] := 'Gro'#223'-/Kleinschreibung beachten';
  GTextItalian.Values['Case Sensitive'] := 'Maiuscole/minuscole';

  GTextPortuguese.Values['Whole Word'] := 'Palavra inteira';
  GTextSpanish.Values['Whole Word'] := 'Palabra completa';
  GTextFrench.Values['Whole Word'] := 'Mot entier';
  GTextGerman.Values['Whole Word'] := 'Ganzes Wort';
  GTextItalian.Values['Whole Word'] := 'Parola intera';

  GTextPortuguese.Values['Excluded'] := 'Exclu'#237'do';
  GTextSpanish.Values['Excluded'] := 'Excluido';
  GTextFrench.Values['Excluded'] := 'Exclu';
  GTextGerman.Values['Excluded'] := 'Ausgeschlossen';
  GTextItalian.Values['Excluded'] := 'Escluso';

  GTextPortuguese.Values['Threaded Search'] := 'Busca em thread';
  GTextSpanish.Values['Threaded Search'] := 'B'#250'squeda en hilo';
  GTextFrench.Values['Threaded Search'] := 'Recherche en thread';
  GTextGerman.Values['Threaded Search'] := 'Suche im Thread';
  GTextItalian.Values['Threaded Search'] := 'Ricerca in thread';

  GTextPortuguese.Values['Stop'] := 'Parar';
  GTextSpanish.Values['Stop'] := 'Detener';
  GTextFrench.Values['Stop'] := 'Arr'#234'ter';
  GTextGerman.Values['Stop'] := 'Stopp';
  GTextItalian.Values['Stop'] := 'Ferma';

  { Split panels and file info }
  GTextPortuguese.Values['Generating new file by source and target lines'] := 'Gerando novo arquivo por linhas de origem e destino';
  GTextSpanish.Values['Generating new file by source and target lines'] := 'Generando nuevo archivo por l'#237'neas de origen y destino';
  GTextFrench.Values['Generating new file by source and target lines'] := 'G'#233'n'#233'ration d''un nouveau fichier par lignes source et cible';
  GTextGerman.Values['Generating new file by source and target lines'] := 'Neue Datei aus Quell- und Zielzeilen erstellen';
  GTextItalian.Values['Generating new file by source and target lines'] := 'Generazione nuovo file per righe sorgente e destinazione';

  GTextPortuguese.Values['Output FileName:'] := 'Nome do arquivo de sa'#237'da:';
  GTextSpanish.Values['Output FileName:'] := 'Nombre del archivo de salida:';
  GTextFrench.Values['Output FileName:'] := 'Nom du fichier de sortie:';
  GTextGerman.Values['Output FileName:'] := 'Ausgabedateiname:';
  GTextItalian.Values['Output FileName:'] := 'Nome file di output:';

  GTextPortuguese.Values['Generating splitted files - max 100'] := 'Gerando arquivos divididos - m'#225'x 100';
  GTextSpanish.Values['Generating splitted files - max 100'] := 'Generando archivos divididos - m'#225'x 100';
  GTextFrench.Values['Generating splitted files - max 100'] := 'G'#233'n'#233'ration de fichiers d'#233'coup'#233's - max 100';
  GTextGerman.Values['Generating splitted files - max 100'] := 'Geteilte Dateien erzeugen - max. 100';
  GTextItalian.Values['Generating splitted files - max 100'] := 'Generazione file divisi - max 100';

  GTextPortuguese.Values['File Info'] := 'Informa'#231#245'es do arquivo';
  GTextSpanish.Values['File Info'] := 'Informaci'#243'n del archivo';
  GTextFrench.Values['File Info'] := 'Infos fichier';
  GTextGerman.Values['File Info'] := 'Dateiinfo';
  GTextItalian.Values['File Info'] := 'Info file';

  GTextPortuguese.Values['File name:'] := 'Nome do arquivo:';
  GTextSpanish.Values['File name:'] := 'Nombre del archivo:';
  GTextFrench.Values['File name:'] := 'Nom du fichier:';
  GTextGerman.Values['File name:'] := 'Dateiname:';
  GTextItalian.Values['File name:'] := 'Nome file:';

  GTextPortuguese.Values['Creation Date:'] := 'Data de cria'#231#227'o:';
  GTextSpanish.Values['Creation Date:'] := 'Fecha de creaci'#243'n:';
  GTextFrench.Values['Creation Date:'] := 'Date de cr'#233'ation:';
  GTextGerman.Values['Creation Date:'] := 'Erstellungsdatum:';
  GTextItalian.Values['Creation Date:'] := 'Data di creazione:';

  GTextPortuguese.Values['Total characters:'] := 'Total de caracteres:';
  GTextSpanish.Values['Total characters:'] := 'Total de caracteres:';
  GTextFrench.Values['Total characters:'] := 'Total de caract'#232'res:';
  GTextGerman.Values['Total characters:'] := 'Gesamtzeichen:';
  GTextItalian.Values['Total characters:'] := 'Totale caratteri:';

  GTextPortuguese.Values['Total lines:'] := 'Total de linhas:';
  GTextSpanish.Values['Total lines:'] := 'Total de l'#237'neas:';
  GTextFrench.Values['Total lines:'] := 'Total de lignes:';
  GTextGerman.Values['Total lines:'] := 'Gesamtzeilen:';
  GTextItalian.Values['Total lines:'] := 'Totale righe:';

  GTextPortuguese.Values['Date && Time'] := 'Data && Hora';
  GTextSpanish.Values['Date && Time'] := 'Fecha && Hora';
  GTextFrench.Values['Date && Time'] := 'Date && Heure';
  GTextGerman.Values['Date && Time'] := 'Datum && Zeit';
  GTextItalian.Values['Date && Time'] := 'Data && Ora';

  GTextPortuguese.Values['Created'] := 'Criado';
  GTextSpanish.Values['Created'] := 'Creado';
  GTextFrench.Values['Created'] := 'Cr'#233#233'';
  GTextGerman.Values['Created'] := 'Erstellt';
  GTextItalian.Values['Created'] := 'Creato';

  GTextPortuguese.Values['Modified'] := 'Modificado';
  GTextSpanish.Values['Modified'] := 'Modificado';
  GTextFrench.Values['Modified'] := 'Modifi'#233'';
  GTextGerman.Values['Modified'] := 'Ge'#228'ndert';
  GTextItalian.Values['Modified'] := 'Modificato';

  GTextPortuguese.Values['Accessed'] := 'Acessado';
  GTextSpanish.Values['Accessed'] := 'Accedido';
  GTextFrench.Values['Accessed'] := 'Acc'#233'd'#233'';
  GTextGerman.Values['Accessed'] := 'Zugegriffen';
  GTextItalian.Values['Accessed'] := 'Accesso';

  GTextPortuguese.Values['Size && Attributes'] := 'Tamanho && Atributos';
  GTextSpanish.Values['Size && Attributes'] := 'Tama'#241'o && Atributos';
  GTextFrench.Values['Size && Attributes'] := 'Taille && Attributs';
  GTextGerman.Values['Size && Attributes'] := 'Gr'#246#223'e && Attribute';
  GTextItalian.Values['Size && Attributes'] := 'Dimensione && Attributi';

  GTextPortuguese.Values['Return'] := 'Voltar';
  GTextSpanish.Values['Return'] := 'Volver';
  GTextFrench.Values['Return'] := 'Retour';
  GTextGerman.Values['Return'] := 'Zur'#252'ck';
  GTextItalian.Values['Return'] := 'Indietro';

  GTextPortuguese.Values['Copy'] := 'Copiar';
  GTextSpanish.Values['Copy'] := 'Copiar';
  GTextFrench.Values['Copy'] := 'Copier';
  GTextGerman.Values['Copy'] := 'Kopieren';
  GTextItalian.Values['Copy'] := 'Copia';

  AddRuntimeDialogProgressTranslations;
  AddNewLanguagesTabComponentCoverage;
  AddFinalRomanianCzechOverrides;

  { Sort all tables by key so FastIndexOfName can use binary search. }
  SortTablesForFastLookup;
end;

function TextTableForLanguage(const Lang: TAppLanguage): TStringList;
begin
  case Lang of
    alPortuguese:   Result := GTextPortuguese;
    alSpanish:      Result := GTextSpanish;
    alFrench:       Result := GTextFrench;
    alGerman:       Result := GTextGerman;
    alItalian:      Result := GTextItalian;
    alPolish:       Result := GTextPolish;
    alPortuguesePT: Result := GTextPortuguesePT;
    alRomanian:     Result := GTextRomanian;
    alHungarian:    Result := GTextHungarian;
    alCzech:        Result := GTextCzech;
  else
    Result := GTextEnglish;
  end;
end;

function TableForLanguage(const Lang: TAppLanguage): TStringList;
begin
  case Lang of
    alPortuguese:   Result := GPortuguese;
    alSpanish:      Result := GSpanish;
    alFrench:       Result := GFrench;
    alGerman:       Result := GGerman;
    alItalian:      Result := GItalian;
    alPolish:       Result := GPolish;
    alPortuguesePT: Result := GPortuguesePT;
    alRomanian:     Result := GRomanian;
    alHungarian:    Result := GHungarian;
    alCzech:        Result := GCzech;
  else
    Result := GEnglish;
  end;
end;

function TryGetValue(Table: TStringList; const Key: string; out Value: string): Boolean;
var
  Idx: Integer;
begin
  Result := False;
  Value := '';
  if Table = nil then Exit;

  Idx := FastIndexOfName(Table, Key);
  if Idx < 0 then Exit;

  Value := Table.ValueFromIndex[Idx];
  Result := True;
end;

function AppLanguageFromCode(const Code: string): TAppLanguage;
var
  Normalized: string;
begin
  Normalized := LowerCase(Trim(Code));
  if (Normalized = 'pt') or (Normalized = 'pt-br') or (Normalized = 'pt_br') or
     (Normalized = 'portuguese') then
    Result := alPortuguese
  else if (Normalized = 'es') or (Normalized = 'es-es') or (Normalized = 'spanish') then
    Result := alSpanish
  else if (Normalized = 'fr') or (Normalized = 'fr-fr') or (Normalized = 'french') then
    Result := alFrench
  else if (Normalized = 'de') or (Normalized = 'de-de') or (Normalized = 'german') then
    Result := alGerman
  else if (Normalized = 'it') or (Normalized = 'it-it') or (Normalized = 'italian') then
    Result := alItalian
  else if (Normalized = 'pl') or (Normalized = 'pl-pl') or (Normalized = 'polish') then
    Result := alPolish
  else if (Normalized = 'pt-pt') or (Normalized = 'pt_pt') or (Normalized = 'portuguese_pt') or
     (Normalized = 'portuguese (portugal)') then
    Result := alPortuguesePT
  else if (Normalized = 'ro') or (Normalized = 'ro-ro') or (Normalized = 'romanian') then
    Result := alRomanian
  else if (Normalized = 'hu') or (Normalized = 'hu-hu') or (Normalized = 'hungarian') then
    Result := alHungarian
  else if (Normalized = 'cs') or (Normalized = 'cs-cz') or (Normalized = 'czech') then
    Result := alCzech
  else
    Result := alEnglish;
end;

function AppLanguageCode(const Lang: TAppLanguage): string;
begin
  case Lang of
    alPortuguese: Result := 'pt-BR';
    alSpanish:    Result := 'es';
    alFrench:     Result := 'fr';
    alGerman:     Result := 'de';
    alItalian:      Result := 'it';
    alPolish:       Result := 'pl';
    alPortuguesePT: Result := 'pt-PT';
    alRomanian:     Result := 'ro';
    alHungarian:    Result := 'hu';
    alCzech:        Result := 'cs';
  else
    Result := 'en';
  end;
end;

procedure SetCurrentLanguage(const Lang: TAppLanguage);
begin
  GCurrentLanguage := Lang;
end;

function GetCurrentLanguage: TAppLanguage;
begin
  Result := GCurrentLanguage;
end;

function Tr(const Key, DefaultText: string): string;
var
  Candidate: string;
begin
  if TryGetValue(TableForLanguage(GCurrentLanguage), Key, Candidate) then
  begin
    Result := Candidate;
    Exit;
  end;

  if TryGetValue(TableForLanguage(alEnglish), Key, Candidate) then
  begin
    Result := Candidate;
    Exit;
  end;

  Result := DefaultText;
end;

function TrText(const DefaultText: string): string;
var
  Candidate: string;
begin
  if TryGetValue(TextTableForLanguage(GCurrentLanguage), DefaultText, Candidate) then
  begin
    Result := Candidate;
    Exit;
  end;

  if TryGetValue(TextTableForLanguage(alEnglish), DefaultText, Candidate) then
  begin
    Result := Candidate;
    Exit;
  end;

  Result := DefaultText;
end;

procedure LocalizeStringProperty(AInstance: TObject; const APropertyName: string;
  const ATranslationKeyPrefix: string);
var
  PropInfo: PPropInfo;
  CurrentValue: string;
  NewValue: string;
begin
  if AInstance = nil then Exit;

  PropInfo := GetPropInfo(AInstance.ClassInfo, APropertyName);
  if PropInfo = nil then Exit;

  if not (PropInfo^.PropType^.Kind in [tkString, tkLString, tkWString]) then Exit;

  CurrentValue := GetStrProp(AInstance, PropInfo);
  if Trim(CurrentValue) = '' then Exit;

  NewValue := Tr(ATranslationKeyPrefix + '.' + LowerCase(APropertyName), TrText(CurrentValue));
  if NewValue <> CurrentValue then
    SetStrProp(AInstance, PropInfo, NewValue);
end;

procedure ApplyTranslationsToForm(AForm: TCustomForm);
var
  i: Integer;
  C: TComponent;
  Prefix: string;
begin
  if AForm = nil then Exit;

  Prefix := 'ui.' + AForm.Name;
  LocalizeStringProperty(AForm, 'Caption', Prefix);
  LocalizeStringProperty(AForm, 'Hint', Prefix);

  for i := 0 to AForm.ComponentCount - 1 do
  begin
    C := AForm.Components[i];
    if C = nil then Continue;

    Prefix := 'ui.' + AForm.Name + '.' + C.Name;
    LocalizeStringProperty(C, 'Caption', Prefix);
    LocalizeStringProperty(C, 'Hint', Prefix);
  end;

end;

initialization
  AddCommonTranslations;

finalization
  FreeAndNil(GEnglish);
  FreeAndNil(GPortuguese);
  FreeAndNil(GSpanish);
  FreeAndNil(GFrench);
  FreeAndNil(GGerman);
  FreeAndNil(GItalian);
  FreeAndNil(GPolish);
  FreeAndNil(GPortuguesePT);
  FreeAndNil(GRomanian);
  FreeAndNil(GHungarian);
  FreeAndNil(GCzech);
  FreeAndNil(GTextEnglish);
  FreeAndNil(GTextPortuguese);
  FreeAndNil(GTextSpanish);
  FreeAndNil(GTextFrench);
  FreeAndNil(GTextGerman);
  FreeAndNil(GTextItalian);
  FreeAndNil(GTextPolish);
  FreeAndNil(GTextPortuguesePT);
  FreeAndNil(GTextRomanian);
  FreeAndNil(GTextHungarian);
  FreeAndNil(GTextCzech);

end.

